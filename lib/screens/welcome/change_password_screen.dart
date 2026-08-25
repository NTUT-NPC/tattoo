import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/welcome/change_password_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final bool isExpired;
  final String? username;

  const ChangePasswordScreen({
    super.key,
    required this.isExpired,
    this.username,
  });

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _clearErrors() {
    ref.read(changePasswordProvider.notifier).clearErrors();
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final success = await ref
        .read(changePasswordProvider.notifier)
        .submit(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
          isExpired: widget.isExpired,
          username: widget.username,
        );

    if (success && mounted) {
      if (widget.isExpired) {
        context.go(AppRoutes.home);
      } else {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.changePassword.success)),
        );
      }
    }
  }

  InputDecoration _inputDecoration(
    String hintText, {
    bool hasError = false,
    Widget? suffixIcon,
  }) {
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
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isExpired
        ? t.changePassword.titleExpired
        : t.changePassword.title;
    final state = ref.watch(changePasswordProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isExpired)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withAlpha(50),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withAlpha(
                                      100,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t.changePassword.expiredNotice,
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Form fields
                            Column(
                              spacing: 16,
                              children: [
                                if (!widget.isExpired)
                                  TextField(
                                    controller: _currentPasswordController,
                                    focusNode: _currentPasswordFocusNode,
                                    enabled: !state.isLoading,
                                    obscureText: _obscureCurrent,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _newPasswordFocusNode.requestFocus(),
                                    onChanged: (_) => _clearErrors(),
                                    decoration: _inputDecoration(
                                      t.changePassword.currentPassword,
                                      hasError: state.currentHasError,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureCurrent
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureCurrent = !_obscureCurrent;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                TextField(
                                  controller: _newPasswordController,
                                  focusNode: _newPasswordFocusNode,
                                  enabled: !state.isLoading,
                                  obscureText: _obscureNew,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _confirmPasswordFocusNode.requestFocus(),
                                  onChanged: (_) => _clearErrors(),
                                  decoration: _inputDecoration(
                                    t.changePassword.newPassword,
                                    hasError: state.newHasError,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNew = !_obscureNew;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  enabled: !state.isLoading,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  onChanged: (_) => _clearErrors(),
                                  decoration: _inputDecoration(
                                    t.changePassword.confirmPassword,
                                    hasError: state.confirmHasError,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (state.errorMessage case final errorMessage?)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Text(
                                  errorMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Submit Button
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: state.isLoading ? null : _submit,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: state.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(t.changePassword.submit),
                              ),
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
