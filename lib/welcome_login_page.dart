import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tattoo/test_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tattoo/services/portal_service.dart';

class WelcomeLoginPage extends StatefulWidget {
  const WelcomeLoginPage({super.key});

  @override
  State<WelcomeLoginPage> createState() => _WelcomeLoginPageState();
}

class _WelcomeLoginPageState extends State<WelcomeLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _errorMessage;
  bool _usernameHasError = false;
  bool _passwordHasError = false;
  final _portalClient = PortalService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<UserDTO> _login() async {
    return _portalClient.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _attemptLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    String? errorMessage;
    bool usernameHasError = false;
    bool passwordHasError = false;
    UserDTO? user;

    if (username.isEmpty || password.trim().isEmpty) {
      errorMessage = '請填寫學號與密碼';
      usernameHasError = username.isEmpty;
      passwordHasError = password.trim().isEmpty;
    } else if (username.contains('@') || username.startsWith('t')) {
      errorMessage = '請直接使用學號登入，不要使用電子郵件';
      usernameHasError = true;
    }

    if (errorMessage == null) {
      setState(() {
        _errorMessage = null;
        _usernameHasError = false;
        _passwordHasError = false;
      });

      FocusScope.of(context).unfocus();

      try {
        user = await _login();
        if (user.name == null) throw Exception('Simulated login failure');
      } catch (_) {
        errorMessage = '登入失敗，請確認帳號密碼';
        usernameHasError = true;
        passwordHasError = true;
      }
    }

    if (!mounted) return;

    if (errorMessage != null || user == null) {
      setState(() {
        _errorMessage = errorMessage;
        _usernameHasError = usernameHasError;
        _passwordHasError = passwordHasError;
      });
      return;
    }

    final UserDTO loggedInUser = user;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TestPage(
          username: username,
          user: loggedInUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    // A helper function to style login fields
    loginDecoration(String hintText, {bool hasError = false}) {
      final surfaceColor = Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest;
      final errorColor = Theme.of(context).colorScheme.error;
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: hasError ? errorColor : surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: hasError
                ? errorColor
                : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        filled: true,
        fillColor: surfaceColor,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 24,
                        children: [
                          // welcome title
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                              children: [
                                const TextSpan(text: '歡迎加入'),
                                const TextSpan(text: '\n'),
                                TextSpan(
                                  text: '北科生活',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // login instruction
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.grey[600],
                                  ),
                              children: [
                                const TextSpan(text: '請使用'),
                                TextSpan(
                                  text: '北科校園入口網站',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                        Uri.parse(
                                          'https://nportal.ntut.edu.tw',
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: '的帳號密碼登入。'),
                              ],
                            ),
                          ),

                          // login form
                          AutofillGroup(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 16,
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  focusNode: _usernameFocusNode,
                                  maxLines: 1,
                                  decoration: loginDecoration(
                                    '學號',
                                    hasError: _usernameHasError,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) {
                                    _passwordFocusNode.requestFocus();
                                  },
                                  onChanged: (_) {
                                    if (_errorMessage != null ||
                                        _usernameHasError ||
                                        _passwordHasError) {
                                      setState(() {
                                        _errorMessage = null;
                                        _usernameHasError = false;
                                        _passwordHasError = false;
                                      });
                                    }
                                  },
                                ),
                                TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  maxLines: 1,
                                  decoration: loginDecoration(
                                    '密碼',
                                    hasError: _passwordHasError,
                                  ),
                                  autofillHints: const [
                                    AutofillHints.password,
                                  ],
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _attemptLogin(),
                                  onChanged: (_) {
                                    if (_errorMessage != null ||
                                        _usernameHasError ||
                                        _passwordHasError) {
                                      setState(() {
                                        _errorMessage = null;
                                        _usernameHasError = false;
                                        _passwordHasError = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          // login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _attemptLogin,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: const Text('登入'),
                              ),
                            ),
                          ),

                          // terms of privacy
                          Column(
                            spacing: 8.0,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: screenHeight * 0.03,
                                color: Colors.grey[600],
                              ),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        height: 1.6,
                                        color: Colors.grey[600],
                                      ),
                                  children: [
                                    const TextSpan(
                                      text: '登入資訊將被安全地儲存在您的裝置中',
                                    ),
                                    const TextSpan(text: '\n'),
                                    const TextSpan(text: '登入即表示您同意我們的'),
                                    TextSpan(
                                      text: '隱私條款',
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(
                                            Uri.parse(
                                              'https://example.com/terms-of-service',
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
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
