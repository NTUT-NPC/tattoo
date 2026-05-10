import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/utils/launch_url.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/screens/main/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _scannerController = MobileScannerController();

  String? _errorMessage;
  bool _usernameHasError = false;
  bool _passwordHasError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Show an inline error if the user was redirected here due to auth failure.
    // Clear after reading — deferred to avoid modifying providers during build.
    final exception = ref.read(loginExceptionProvider);
    if (exception == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(loginExceptionProvider.notifier).set(null);
    });
    final message = switch (exception.failure) {
      .passwordExpired => t.login.errors.passwordExpired,
      .credentialsMissing ||
      .wrongCredentials ||
      .unknown => t.errors.credentialsInvalid,
      _ => t.errors.sessionExpired,
    };
    _setError(message);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // State management

  void _clearErrors() {
    if (_errorMessage != null || _usernameHasError || _passwordHasError) {
      setState(() {
        _errorMessage = null;
        _usernameHasError = false;
        _passwordHasError = false;
      });
    }
  }

  void _setError(
    String message, {
    bool username = false,
    bool password = false,
  }) {
    setState(() {
      _errorMessage = message;
      _usernameHasError = username;
      _passwordHasError = password;
      _isLoading = false;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) {
        _errorMessage = null;
        _usernameHasError = false;
        _passwordHasError = false;
      }
    });
  }

  // Actions

  Future<void> _attemptLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Validate input
    if (username.isEmpty || password.trim().isEmpty) {
      _setError(
        t.login.errors.emptyFields,
        username: username.isEmpty,
        password: password.trim().isEmpty,
      );
      return;
    }
    if (username.contains('@') || username.startsWith('t')) {
      _setError(t.login.errors.useStudentId, username: true);
      return;
    }

    _setLoading(true);
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authRepositoryProvider).login(username, password);
      if (mounted) context.go(AppRoutes.home);
    } on DioException {
      if (mounted) _setError(t.errors.connectionFailed);
    } on LoginException catch (e) {
      if (mounted) {
        switch (e.failure) {
          case .wrongCredentials:
            _setError(
              t.login.errors.wrongCredentials,
              username: true,
              password: true,
            );
          case .accountLocked:
            _setError(t.login.errors.accountLocked);
          case .passwordExpired:
            _setError(t.login.errors.passwordExpired);
          case .mobileVerificationRequired:
            _setError(t.login.errors.mobileVerificationRequired);
          case _:
            _setError(
              t.login.errors.loginFailed,
              username: true,
              password: true,
            );
        }
      }
    } catch (_) {
      if (mounted) {
        _setError(t.login.errors.loginFailed, username: true, password: true);
      }
    }
  }

  // UI helpers

  InputDecoration _inputDecoration(String hintText, {bool hasError = false}) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surfaceContainerHighest;
    final errorColor = theme.colorScheme.error;
    final primaryColor = theme.colorScheme.primary;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
        fontWeight: .w500,
      ),
      border: OutlineInputBorder(borderRadius: .circular(50)),
      enabledBorder: OutlineInputBorder(
        borderRadius: .circular(50),
        borderSide: BorderSide(color: hasError ? errorColor : surfaceColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: .circular(50),
        borderSide: BorderSide(
          color: hasError ? errorColor : primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const .symmetric(horizontal: 24, vertical: 16),
      filled: true,
      fillColor: surfaceColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return GestureDetector(
              behavior: .translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: isWide
                              ? constraints.maxWidth / 2
                              : constraints.maxWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 24,
                              children: [
                                // Welcome title
                                Text.rich(
                                  TextSpan(
                                    text: t.login.manualLoginTitleLine1,
                                    children: [
                                      TextSpan(
                                        text: t.login.manualLoginTitleLine2,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Login instruction
                                Text.rich(
                                  t.login.instruction(
                                    portalLink: (text) => TextSpan(
                                      text: text,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => launchUrl(
                                          Uri.parse(
                                            'https://nportal.ntut.edu.tw',
                                          ),
                                        ),
                                    ),
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Login form
                                AutofillGroup(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 16,
                                    children: [
                                      TextField(
                                        controller: _usernameController,
                                        focusNode: _usernameFocusNode,
                                        maxLines: 1,
                                        enabled: !_isLoading,
                                        decoration: _inputDecoration(
                                          t.login.studentId,
                                          hasError: _usernameHasError,
                                        ),
                                        autofillHints: const [
                                          AutofillHints.username,
                                        ],
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) =>
                                            _passwordFocusNode.requestFocus(),
                                        onChanged: (_) => _clearErrors(),
                                      ),
                                      TextField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        maxLines: 1,
                                        enabled: !_isLoading,
                                        decoration: _inputDecoration(
                                          t.login.password,
                                          hasError: _passwordHasError,
                                        ),
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _attemptLogin(),
                                        onChanged: (_) => _clearErrors(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Error message
                                if (_errorMessage case final errorMessage?)
                                  Text(
                                    errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _attemptLogin,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(t.login.loginButton),
                                    ),
                                  ),
                                ),

                                // Privacy notice
                                ClearNoticeVertical(
                                  text: t.login.privacyNotice(
                                    privacyPolicy: (text) => TextSpan(
                                      text: text,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => launchUrl(
                                          Uri.parse(
                                            t.about.privacyPolicyUrl,
                                          ),
                                        ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isWide
                              ? constraints.maxWidth / 2
                              : constraints.maxWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: t.login.quickLoginTitleLine1,
                                    children: [
                                      TextSpan(
                                        text: t.login.quickLoginTitleLine2,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  t.login.quickLoginDescription,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: MobileScanner(
                                      controller: _scannerController,
                                      onDetect: (capture) {
                                        final barcodes = capture.barcodes;
                                        for (final barcode in barcodes) {
                                          if (barcode.rawValue != null) {
                                            final code = barcode.rawValue!
                                                .trim();
                                            if (RegExp(
                                              r'^11[0-5](?:3[0-9]|4[02459]|5[1246789]|6[01568]|7[3489]|8[1-5]|9[189]|A[0458BCGTY]|B[23]|C[057])[A-Z0-9]\d{3}$',
                                            ).hasMatch(code)) {
                                              // Student ID scanned
                                              if (_usernameController.text !=
                                                  code) {
                                                setState(() {
                                                  _usernameController.text =
                                                      code;
                                                  _clearErrors();
                                                });
                                                _passwordFocusNode
                                                    .requestFocus();
                                              }
                                            } else if (code.startsWith(
                                              'https://ntut.app/login?code=',
                                            )) {
                                              // Tattoo App QR login scanned
                                              final extractedCode = code
                                                  .substring(
                                                    'https://ntut.app/login?code='
                                                        .length,
                                                  );
                                              if (RegExp(
                                                r'^\d+$',
                                              ).hasMatch(extractedCode)) {
                                                scannedAuthCode = extractedCode;
                                                ref
                                                    .read(
                                                      sessionProvider.notifier,
                                                    )
                                                    .create();
                                                context.go(AppRoutes.home);
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        t
                                                            .login
                                                            .errors
                                                            .invalidQrCode,
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                            break;
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
