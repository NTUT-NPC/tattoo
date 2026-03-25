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
  static const _scannerErrorMessages = {
    '201': '手機未登入',
    '202': '操作錯誤，請先至「首頁」，再點擊「校外人士登入」',
    '203': '已經是登入成功狀態',
    '204': 'QR code 已經登出，請重新整理頁面及刷新',
    '205': '已登入，要切換使用者必須先登出網頁',
    '206': 'QR code 已過期，請重複從電腦頁面刷新',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sheetController.animateTo(
        0.53,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
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

    setState(() => _isProcessing = true);
    _sheetController.animateTo(
      0.53,
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

      if (_scannerErrorMessages.containsKey(type)) {
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

  String _mapScanError(Object error) {
    if (error is _ScannerTypeException) {
      final msg = _scannerErrorMessages[error.type];
      if (msg != null) {
        return '[${error.type}] $msg';
      }
      return '[${error.type}] 登入失敗，請確認 QR code 是否正確或從電腦頁面刷新';
    }
    return switch (error) {
      SessionExpiredException() => t.errors.sessionExpired,
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
          ScannerGuideSheet(
            controller: _sheetController,
            isProcessing: _isProcessing,
          ),
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

  Widget _buildLoadingOverlay() {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(),
    );
  }
}

class _ScannerTypeException implements Exception {
  final String type;
  _ScannerTypeException(this.type);
}
