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
  bool _isSuccess = false;
  Object? _error;

  static const _scannerSuccessCodes = {'221', '222', '223'};

  @override
  void dispose() {
    _controller.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawCode = barcodes.first.rawValue;
    if (rawCode == null) return;

    // Sanitize the code (remove trailing null bytes and common garbage characters like '\x00' and '\uFFFD')
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
    setState(() {
      _isProcessing = true;
      _isSuccess = false;
      _error = null;
    });

    // Expand the sheet to show loading state
    _sheetController.animateTo(
      ScannerGuideSheet.maxSheetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    try {
      await _controller.stop();
    } catch (_) {}
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

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });

      // Wait a bit before closing
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _error = e;
      });
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  void _clearError() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(t.scanner.title),
        backgroundColor: Theme.of(context).colorScheme.primary, // 使用主題主色
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _buildErrorWidget(error);
            },
          ),
          _buildOverlay(context),
          ScannerGuideSheet(
            controller: _sheetController,
            isProcessing: _isProcessing,
            isSuccess: _isSuccess,
            error: _error != null ? _mapScanError(_error!) : null,
            onDismissError: _clearError,
          ),
          if (_isProcessing)
            Positioned(
              top: 0,
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
              border: Border.all(
                color: Colors.white, // 改回白色
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(MobileScannerException error) {
    String message;
    String? description;
    IconData icon = Icons.error_outline;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = t.scanner.permissionDenied;
        description = t.scanner.permissionDeniedDescription;
        icon = Icons.no_photography_outlined;
      case MobileScannerErrorCode.unsupported:
        message = t.scanner.cameraError;
        description = 'Scanning is not supported on this device';
      default:
        message = t.scanner.cameraError;
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScannerTypeException implements Exception {
  final String type;
  _ScannerTypeException(this.type);
}
