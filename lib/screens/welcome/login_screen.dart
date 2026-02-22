import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';

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

  String? _errorMessage;
  bool _usernameHasError = false;
  bool _passwordHasError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
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
      if (mounted) _setError(t.login.errors.connectionFailed);
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
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: hasError ? errorColor : surfaceColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(
          color: hasError ? errorColor : primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      filled: true,
      fillColor: surfaceColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 24,
                        children: [
                          // Welcome title
                          Text.rich(
                            TextSpan(
                              text: '${t.login.welcomeLine1}\n',
                              children: [
                                TextSpan(
                                  text: t.login.welcomeLine2,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Login instruction
                          Text.rich(
                            TextSpan(
                              text: t.login.instruction.prefix,
                              children: [
                                TextSpan(
                                  text: t.login.instruction.portalLink,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrl(
                                      Uri.parse('https://nportal.ntut.edu.tw'),
                                    ),
                                ),
                                TextSpan(text: t.login.instruction.suffix),
                              ],
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
                                  autofillHints: const [AutofillHints.username],
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
                                  autofillHints: const [AutofillHints.password],
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _attemptLogin(),
                                  onChanged: (_) => _clearErrors(),
                                ),
                              ],
                            ),
                          ),

                          // Error message
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
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
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isLoading ? null : _attemptLogin,
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
                          Column(
                            spacing: 8.0,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: screenHeight * 0.03,
                                color: Colors.grey[600],
                              ),
                              Text.rich(
                                TextSpan(
                                  text: t.login.privacyNotice,
                                  children: [
                                    TextSpan(
                                      text: t.login.privacyTerms,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => launchUrl(
                                          Uri.parse(
                                            'https://example.com/terms-of-service',
                                          ),
                                        ),
                                    ),
                                  ],
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.6,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
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
