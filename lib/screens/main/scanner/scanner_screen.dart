import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/http.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null) return;

    // Sanitize the code (remove trailing null bytes or garbage characters like )
    final code = rawCode.trim().replaceAll('\x00', '').replaceAll('\uFFFD', '');
    if (!code.startsWith('http')) {
      return;
    }

    final uri = Uri.tryParse(code);
    if (uri == null) return;

    // Correct iStudy login QR code pattern: https://istudy.ntut.edu.tw/login.php?spotlight=*
    final isIStudyLogin =
        uri.host == 'istudy.ntut.edu.tw' &&
        uri.path == '/login.php' &&
        uri.queryParameters.containsKey('spotlight');

    if (!isIStudyLogin) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.scanner.invalidUrl)));
      }
      return;
    }

    setState(() => _isProcessing = true);
    _controller.stop();
    HapticFeedback.lightImpact();

    try {
      final authRepository = ref.read(authRepositoryProvider);

      // 1. Ensure SSO for i-School Plus
      await authRepository.withAuth(
        () async {},
        sso: [PortalServiceCode.iSchoolPlusService],
      );

      // 2. Fetch the QR code URL in the background
      final dio = createDio();

      if (uri.host.contains('ntut.edu.tw')) {
        dio.interceptors.insert(0, InvalidCookieFilter());
        dio.transformer = PlainTextTransformer();
        dio.options.headers = {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Connection': 'close',
        };

        // Warm up: Visit the iStudy homepage first to ensure session cookies are active on this domain
        await dio.get('https://istudy.ntut.edu.tw/mooc/index.php');
      }

      final response = await dio.get(code);

      final responseBody = response.data.toString();
      final finalUri = response.requestOptions.uri;

      // Specific markers from user's provided HTML
      final bool hasSuccessMarker =
          responseBody.contains('登入成功') ||
          responseBody.contains('已正確使其登入成功') ||
          responseBody.contains('授權成功') ||
          responseBody.contains('已完成登入');

      // Success URL patterns provided by user (type 221, 222, 223)
      final bool isSuccessUrl =
          finalUri.path.contains('message.php') &&
          ([
            '221',
            '222',
            '223',
          ].any((t) => finalUri.queryParameters['type'] == t));

      // Check for explicit failure markers
      if (responseBody.contains('請先登入再進行掃描')) {
        throw NotLoggedInException();
      }

      final bool isSuccess = isSuccessUrl || hasSuccessMarker;

      if (!isSuccess) {
        throw Exception('Login markers not found in response');
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.scanner.success)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller.start();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_mapScanError(e))));
      }
    }
  }

  String _mapScanError(Object error) {
    return switch (error) {
      NotLoggedInException() => t.errors.sessionExpired,
      LoginException() => t.errors.credentialsInvalid,
      DioException() => t.errors.connectionFailed,
      _ => t.scanner.failed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(t.scanner.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _buildOverlay(context),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.7;
    return Stack(
      children: [
        // Darkened background with a hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(150),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  height: scanWindowSize,
                  width: scanWindowSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scan window border
        Center(
          child: Container(
            height: scanWindowSize,
            width: scanWindowSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        // Instruction bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Text(
              t.scanner.howTo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              t.scanner.processing,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
