import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';

const _kioskLoginServiceCode = 'per_001_oauth';
const _kioskLoginHost = 'ntut.app';
const _kioskLoginPath = '/login';
const _kioskLoginQrExpiryDuration = Duration(minutes: 2);

Uri _buildKioskLoginUri(String authCode) {
  if (authCode.isEmpty) {
    throw const FormatException('SSO URL does not contain an auth code');
  }

  return .https(_kioskLoginHost, _kioskLoginPath, {'code': authCode});
}

final kioskLoginUriProvider = FutureProvider.autoDispose<Uri>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  final ssoUrl = await authRepository.getSsoUrl(_kioskLoginServiceCode);
  final authCode =
      ssoUrl.queryParameters['code'] ?? ssoUrl.queryParameters['amp;code'];

  if (authCode case final authCode?) {
    return _buildKioskLoginUri(authCode);
  }

  throw const FormatException('SSO URL does not contain an auth code');
});

class KioskLoginQrScreen extends ConsumerWidget {
  const KioskLoginQrScreen({super.key});

  void _copyUrl(BuildContext context, Uri uri) {
    Clipboard.setData(ClipboardData(text: uri.toString()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(t.general.copied),
          behavior: .floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginUri = ref.watch(kioskLoginUriProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.vote),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const .all(24),
                    child: loginUri.when(
                      skipLoadingOnRefresh: false,
                      data: (uri) => _KioskLoginQrContent(
                        uri: uri,
                        onCopy: () => _copyUrl(context, uri),
                        onExpired: () => ref.invalidate(kioskLoginUriProvider),
                      ),
                      loading: () => const _KioskLoginQrLoading(),
                      error: (error, stackTrace) => _KioskLoginQrError(
                        error: error,
                        onRefresh: () => ref.invalidate(kioskLoginUriProvider),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const .fromLTRB(24, 0, 24, 24),
        child: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(t.general.back),
        ),
      ),
    );
  }
}

class _KioskLoginQrContent extends StatefulWidget {
  const _KioskLoginQrContent({
    required this.uri,
    required this.onCopy,
    required this.onExpired,
  });

  final Uri uri;
  final VoidCallback onCopy;
  final VoidCallback onExpired;

  @override
  State<_KioskLoginQrContent> createState() => _KioskLoginQrContentState();
}

class _KioskLoginQrContentState extends State<_KioskLoginQrContent> {
  Timer? _timer;
  Duration _remaining = _kioskLoginQrExpiryDuration;

  @override
  void initState() {
    super.initState();
    _startCountdown(rebuild: false);
  }

  @override
  void didUpdateWidget(covariant _KioskLoginQrContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.uri != widget.uri) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown({bool rebuild = true}) {
    _timer?.cancel();
    void resetRemaining() {
      _remaining = _kioskLoginQrExpiryDuration;
    }

    if (rebuild) {
      setState(resetRemaining);
    } else {
      resetRemaining();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= const Duration(seconds: 1)) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _remaining = .zero;
          });
          widget.onExpired();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  String get _remainingLabel {
    return _formatRemaining(_remaining);
  }

  @override
  Widget build(BuildContext context) {
    final size = _qrSize(context);

    return _KioskLoginQrLayout(
      remainingLabel: _remainingLabel,
      onRefresh: widget.onExpired,
      child: _KioskLoginQrContainer(
        child: Semantics(
          label: t.kioskLogin.qrCode,
          child: QrImageView(
            data: widget.uri.toString(),
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _KioskLoginQrLoading extends StatelessWidget {
  const _KioskLoginQrLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = _qrSize(context);

    return _KioskLoginQrLayout(
      remainingLabel: _formatRemaining(_kioskLoginQrExpiryDuration),
      onRefresh: null,
      child: _KioskLoginQrContainer(
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _KioskLoginQrLayout extends StatelessWidget {
  const _KioskLoginQrLayout({
    required this.child,
    required this.remainingLabel,
    required this.onRefresh,
  });

  final Widget child;
  final String remainingLabel;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: 16,
      children: [
        child,
        _KioskLoginQrStatusRow(
          remainingLabel: remainingLabel,
          onRefresh: onRefresh,
        ),
        const _KioskLoginQrNotice(),
      ],
    );
  }
}

class _KioskLoginQrContainer extends StatelessWidget {
  const _KioskLoginQrContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(8),
        border: .all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const .all(16),
        child: child,
      ),
    );
  }
}

double _qrSize(BuildContext context) {
  return (MediaQuery.sizeOf(context).shortestSide - 128).clamp(
    80.0,
    320.0,
  );
}

class _KioskLoginQrStatusRow extends StatelessWidget {
  const _KioskLoginQrStatusRow({
    required this.remainingLabel,
    required this.onRefresh,
  });

  final String remainingLabel;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        IconButton(
          icon: const Icon(Icons.timer_outlined, size: 20),
          onPressed: null,
          color: colorScheme.onSurfaceVariant,
          disabledColor: colorScheme.onSurfaceVariant,
        ),
        Text(
          remainingLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          tooltip: t.kioskLogin.refresh,
          visualDensity: .compact,
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ],
    );
  }
}

class _KioskLoginQrNotice extends StatelessWidget {
  const _KioskLoginQrNotice();

  @override
  Widget build(BuildContext context) {
    return ClearNoticeVertical(
      text: TextSpan(
        text: t.kioskLogin.notice,
      ),
    );
  }
}

String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes
      .remainder(60)
      .toString()
      .padLeft(
        2,
        '0',
      );
  final seconds = remaining.inSeconds
      .remainder(60)
      .toString()
      .padLeft(
        2,
        '0',
      );

  return '$minutes:$seconds';
}

class _KioskLoginQrError extends StatelessWidget {
  const _KioskLoginQrError({
    required this.error,
    required this.onRefresh,
  });

  final Object error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = switch (error) {
      DioException() => t.errors.connectionFailed,
      FormatException() => t.kioskLogin.invalidSsoUrl,
      _ => t.kioskLogin.loadFailed,
    };

    return _KioskLoginQrLayout(
      remainingLabel: _formatRemaining(_kioskLoginQrExpiryDuration),
      onRefresh: onRefresh,
      child: _KioskLoginQrContainer(
        child: SizedBox.square(
          dimension: _qrSize(context),
          child: Center(
            child: Padding(
              padding: const .all(12),
              child: Column(
                mainAxisSize: .min,
                spacing: 12,
                children: [
                  Icon(
                    Icons.qr_code_2_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    message,
                    textAlign: .center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
