import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';

const _kioskLoginServiceCode = 'per_001_oauth';
const _kioskLoginHost = 'ntut.app';
const _kioskLoginPath = '/login';

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
        title: Text(t.kioskLogin.title),
        actions: [
          IconButton(
            tooltip: t.kioskLogin.refresh,
            onPressed: () => ref.invalidate(kioskLoginUriProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const .all(24),
            child: loginUri.when(
              data: (uri) => _KioskLoginQrContent(
                uri: uri,
                onCopy: () => _copyUrl(context, uri),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => _KioskLoginQrError(error: error),
            ),
          ),
        ),
      ),
    );
  }
}

class _KioskLoginQrContent extends StatelessWidget {
  const _KioskLoginQrContent({
    required this.uri,
    required this.onCopy,
  });

  final Uri uri;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = (MediaQuery.sizeOf(context).shortestSide - 96).clamp(
      80.0,
      320.0,
    );

    return Column(
      mainAxisSize: .min,
      spacing: 16,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: .circular(8),
            border: .all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const .all(16),
            child: Semantics(
              label: t.kioskLogin.qrCode,
              child: QrImageView(
                data: uri.toString(),
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        SelectableText(
          uri.toString(),
          textAlign: .center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        FilledButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
          label: Text(t.general.copy),
        ),
      ],
    );
  }
}

class _KioskLoginQrError extends StatelessWidget {
  const _KioskLoginQrError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = switch (error) {
      DioException() => t.errors.connectionFailed,
      FormatException() => t.kioskLogin.invalidSsoUrl,
      _ => t.kioskLogin.loadFailed,
    };

    return Column(
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
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
