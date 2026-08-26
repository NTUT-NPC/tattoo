import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/screens/main/user_providers.dart';

class ChangePasswordState {
  final bool isLoading;
  final String? errorMessage;
  final bool currentHasError;
  final bool newHasError;
  final bool confirmHasError;

  const ChangePasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.currentHasError = false,
    this.newHasError = false,
    this.confirmHasError = false,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? currentHasError,
    bool? newHasError,
    bool? confirmHasError,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentHasError: currentHasError ?? this.currentHasError,
      newHasError: newHasError ?? this.newHasError,
      confirmHasError: confirmHasError ?? this.confirmHasError,
    );
  }
}

final changePasswordProvider =
    NotifierProvider<ChangePasswordNotifier, ChangePasswordState>(
      ChangePasswordNotifier.new,
    );

class ChangePasswordNotifier extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() {
    return const ChangePasswordState();
  }

  void clearErrors() {
    if (state.errorMessage != null ||
        state.currentHasError ||
        state.newHasError ||
        state.confirmHasError) {
      state = const ChangePasswordState();
    }
  }

  String? _validatePasswordRules(String password, String? studentId) {
    if (password.length < 8 || password.length > 14) {
      return t.changePassword.errors.invalidLength;
    }

    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[^a-zA-Z0-9]'));

    if (!hasUpper || !hasLower || !hasDigit || !hasSymbol) {
      return t.changePassword.errors.invalidComplexity;
    }

    if (studentId != null) {
      final normalizedPassword = password.toLowerCase().trim();
      final normalizedStudentId = studentId.toLowerCase().trim();
      if (normalizedStudentId.isNotEmpty &&
          normalizedPassword.contains(normalizedStudentId)) {
        return t.changePassword.errors.sameAsUsername;
      }
    }

    return null;
  }

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required bool isExpired,
    required String? username,
  }) async {
    // 1. Basic empty check
    if (!isExpired && currentPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: t.changePassword.errors.emptyFields,
        currentHasError: true,
      );
      return false;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: t.changePassword.errors.emptyFields,
        newHasError: newPassword.isEmpty,
        confirmHasError: confirmPassword.isEmpty,
      );
      return false;
    }

    // 2. Mismatch check
    if (newPassword != confirmPassword) {
      state = state.copyWith(
        errorMessage: t.changePassword.errors.mismatch,
        newHasError: true,
        confirmHasError: true,
      );
      return false;
    }

    if (isExpired && (username == null || username.trim().isEmpty)) {
      state = state.copyWith(
        errorMessage: t.changePassword.errors.failed(
          error: 'Student ID is missing',
        ),
        newHasError: true,
      );
      return false;
    }

    // Determine the student ID for similarity validation
    String? studentId = username;
    if (!isExpired) {
      var user = ref.read(userProfileProvider).value;
      if (user == null) {
        final db = ref.read(databaseProvider);
        user = await db.select(db.users).getSingleOrNull();
      }
      studentId = user?.studentId;
    }

    // 3. Complexity & Similarity Validation
    final validationError = _validatePasswordRules(newPassword, studentId);
    if (validationError != null) {
      state = state.copyWith(
        errorMessage: validationError,
        newHasError: true,
        confirmHasError: true,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentHasError: false,
      newHasError: false,
      confirmHasError: false,
    );

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (isExpired) {
        await authRepo.changeExpiredPassword(username!, newPassword);
      } else {
        await authRepo.changePassword(currentPassword, newPassword);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: t.changePassword.errors.failed(error: _errorMessageOf(e)),
        currentHasError: !isExpired,
        newHasError: true,
        confirmHasError: true,
      );
      return false;
    }
  }

  String _errorMessageOf(Object e) {
    final str = e.toString();
    final cleanMsg = str.startsWith('Exception: ')
        ? str.substring('Exception: '.length)
        : str;

    if (cleanMsg.contains('身分驗證 失敗') ||
        cleanMsg.contains('Identity verification Fail')) {
      return t.changePassword.errors.server.authFailed;
    }
    if (cleanMsg.contains('密碼修改有誤。密碼於「1」天內不得再修改。請重新輸入。')) {
      return t.changePassword.errors.server.minAge;
    }
    if (cleanMsg.contains('密碼修改有誤。密碼不得與前「3」次相同。請重新輸入。')) {
      return t.changePassword.errors.server.historyRepeat;
    }
    if (cleanMsg.contains('帳號') && cleanMsg.contains('相同')) {
      return t.changePassword.errors.server.sameAsUsername;
    }
    if (cleanMsg.contains('密碼長度') ||
        (cleanMsg.contains('字元') && cleanMsg.contains('8'))) {
      return t.changePassword.errors.server.length;
    }
    if (cleanMsg.contains('複雜性') ||
        cleanMsg.contains('大小寫') ||
        cleanMsg.contains('符號')) {
      return t.changePassword.errors.server.complexity;
    }

    return cleanMsg;
  }
}
