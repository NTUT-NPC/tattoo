import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/http.dart';

import 'scanner_guide_bottom_sheet.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isProcessing = false;

  static const _scannerSuccessCodes = {'221', '222', '223'};

  @override
  void initState() {
    super.initState();
  }

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

    // Correct iStudy login QR code pattern: https://istudy.ntut.edu.tw/mooc/login.php?spotlight=*
    final isIStudyHost = uri.host == 'istudy.ntut.edu.tw';
    final isIStudyLogin =
        isIStudyHost &&
        (uri.path == '/login.php' || uri.path == '/mooc/login.php') &&
        uri.queryParameters.containsKey('spotlight');

    if (!isIStudyLogin) {
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    setState(() => _isProcessing = true);
    
    // We can't easily get maxSheetSize here without repeating calculation
    // but we can animate to a safe default or use a generic ratio
    // Calculate a good visible height (around 60% of available height is a safe bet for content)
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight + topPadding;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetSize = 1.0 - (appBarHeight / screenHeight);

    _sheetController.animateTo(
      maxSheetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
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

        // Warm up: Visit the iStudy homepage first to ensure session cookies are active on this domain
        await dio.get('https://istudy.ntut.edu.tw/mooc/index.php');
      }

      final response = await dio.get(code);
      final finalUri = response.requestOptions.uri;
      final String? type = finalUri.queryParameters['type'];

      if (t.scanner.errors.containsKey(type)) {
        throw _ScannerTypeException(type!);
      }

      final bool isSuccess =
          finalUri.path.contains('message.php') &&
          (_scannerSuccessCodes.contains(type));

      if (!isSuccess) {
        throw _ScannerTypeException(type ?? 'unknown');
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight + topPadding;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetSize = 1.0 - (appBarHeight / screenHeight);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(t.scanner.title),
        backgroundColor: Colors.black.withAlpha(50),
        surfaceTintColor: Colors.transparent,
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
          ScannerGuideSheet(
            controller: _sheetController,
            isProcessing: _isProcessing,
            maxChildSize: maxSheetSize,
          ),
          if (_isProcessing)
            Positioned(
              top: appBarHeight,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String _mapScanError(Object error) {
    if (error is _ScannerTypeException) {
      final msg = t.scanner.errors[error.type];
      if (msg != null) {
        return '[${error.type}] $msg';
      }
      return '[${error.type}] ${t.scanner.errors['unknown']}';
    }
    return switch (error) {
      SessionExpiredException() => t.errors.sessionExpired,
      LoginException() => t.errors.credentialsInvalid,
      DioException() => t.errors.connectionFailed,
      _ => t.scanner.failed,
    };
  }

  Widget _buildOverlay(BuildContext context) {
    final scanWindowSize = MediaQuery.sizeOf(context).width * 0.7;
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
      ],
    );
  }

}

class _ScannerTypeException implements Exception {
  final String type;
  _ScannerTypeException(this.type);
}