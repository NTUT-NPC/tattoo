import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/providers/database_provider.dart';
import 'package:tattoo/providers/service_providers.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/http.dart';

part 'auth_repository.g.dart';

/// Thrown when [AuthRepository.withAuth] is called but no stored credentials
/// are available (user has never logged in, or has logged out).
class NotLoggedInException implements Exception {
  @override
  String toString() => 'NotLoggedInException: No stored credentials available.';
}

/// Thrown when stored credentials are rejected by the server
/// (e.g., password was changed). Stored credentials are cleared automatically.
class InvalidCredentialsException implements Exception {
  @override
  String toString() =>
      'InvalidCredentialsException: Stored credentials are no longer valid.';
}

/// Auth session status, updated by [AuthRepository.withAuth].
enum AuthStatus {
  /// Session is valid or has not been tested yet.
  authenticated,

  /// Network is unreachable.
  offline,

  /// Stored credentials were rejected or are missing.
  credentialsExpired,
}

/// User profile combining [User] and [Student] entities.
class UserWithStudent {
  UserWithStudent(this.user, this.student);

  final User user;
  final Student student;
}

const _secureStorage = FlutterSecureStorage();

/// Provides the current [AuthStatus].
///
/// Updated automatically by [AuthRepository.withAuth] on success or failure.
@Riverpod(keepAlive: true)
class AuthStatusNotifier extends _$AuthStatusNotifier {
  @override
  AuthStatus build() => AuthStatus.authenticated;

  void update(AuthStatus status) => state = status;
}

/// Provides the [AuthRepository] instance.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    secureStorage: _secureStorage,
    onAuthStatusChanged: ref.read(authStatusProvider.notifier).update,
  );
}

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.
@riverpod
Future<UserWithStudent?> userProfile(Ref ref) {
  return ref.watch(authRepositoryProvider).getUserProfile();
}

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.
@riverpod
Future<File?> userAvatar(Ref ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
}

/// Manages user authentication and profile data.
///
/// ```dart
/// final auth = ref.watch(authRepositoryProvider);
///
/// // Login
/// final user = await auth.login('111360109', 'password');
///
/// // Check session
/// if (await auth.isLoggedIn()) {
///   final user = await auth.getCurrentUser();
/// }
/// ```
class AuthRepository {
  final PortalService _portalService;
  final AppDatabase _database;
  final FlutterSecureStorage _secureStorage;
  final void Function(AuthStatus) _onAuthStatusChanged;

  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  AuthRepository({
    required PortalService portalService,
    required AppDatabase database,
    required FlutterSecureStorage secureStorage,
    required void Function(AuthStatus) onAuthStatusChanged,
  }) : _portalService = portalService,
       _database = database,
       _secureStorage = secureStorage,
       _onAuthStatusChanged = onAuthStatusChanged;

  /// Authenticates with NTUT Portal and saves the user profile.
  ///
  /// Throws [Exception] if credentials are invalid or network fails.
  /// On success, credentials are stored securely for auto-login.
  Future<User> login(String username, String password) async {
    final userDto = await _portalService.login(username, password);

    // Save credentials for auto-login
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
    _onAuthStatusChanged(AuthStatus.authenticated);

    return _database.transaction(() async {
      // Upsert student record (studentId has UNIQUE constraint)
      final student = await _database
          .into(_database.students)
          .insertReturning(
            StudentsCompanion.insert(
              studentId: username,
              name: Value(userDto.name),
            ),
            onConflict: DoUpdate(
              (old) => StudentsCompanion(name: Value(userDto.name)),
              target: [_database.students.studentId],
            ),
          );

      // Clear existing user (single-user app) and insert new user record
      await _database.delete(_database.users).go();
      return _database
          .into(_database.users)
          .insertReturning(
            UsersCompanion.insert(
              student: student.id,
              avatarFilename: userDto.avatarFilename ?? '',
              email: userDto.email ?? '',
              passwordExpiresInDays: Value(userDto.passwordExpiresInDays),
            ),
          );
    });
  }

  /// Checks if there's an active authenticated session.
  ///
  /// Does not throw.
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Logs out and clears all local user data and stored credentials.
  Future<void> logout() async {
    await _database.delete(_database.users).go();
    await cookieJar.deleteAll();
    await _clearCredentials();
    await _clearAvatarCache();
  }

  /// Whether the user has stored login credentials.
  ///
  /// Returns `true` if both username and password exist in secure storage.
  /// This does not validate the credentials or check session state.
  Future<bool> hasCredentials() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return username != null && password != null;
  }

  /// Executes [call] with automatic re-authentication on session expiry.
  ///
  /// If [call] fails with a non-[DioException] error (indicating session
  /// expiry or auth failure), this method re-authenticates using stored
  /// credentials and retries [call] once.
  ///
  /// Throws [NotLoggedInException] if no stored credentials are available.
  /// Throws [InvalidCredentialsException] if stored credentials are rejected
  /// (credentials are automatically cleared from secure storage).
  /// Rethrows [DioException] from [call] or re-auth (network errors).
  Future<T> withAuth<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      _onAuthStatusChanged(AuthStatus.authenticated);
      return result;
    } catch (e) {
      if (e is DioException) {
        _onAuthStatusChanged(AuthStatus.offline);
        rethrow;
      }

      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      if (username == null || password == null) {
        _onAuthStatusChanged(AuthStatus.credentialsExpired);
        throw NotLoggedInException();
      }

      try {
        await _portalService.login(username, password);
      } on DioException {
        _onAuthStatusChanged(AuthStatus.offline);
        rethrow;
      } catch (_) {
        await _clearCredentials();
        _onAuthStatusChanged(AuthStatus.credentialsExpired);
        throw InvalidCredentialsException();
      }

      _onAuthStatusChanged(AuthStatus.authenticated);
      return await call();
    }
  }

  /// Gets the current user's profile from local storage.
  ///
  /// Returns `null` if not logged in. Does not make network requests.
  Future<User?> getCurrentUser() async {
    return _database.select(_database.users).getSingleOrNull();
  }

  /// Gets the current user's profile with student data.
  ///
  /// Returns `null` if not logged in. Does not make network requests.
  Future<UserWithStudent?> getUserProfile() async {
    final query = _database.select(_database.users).join([
      innerJoin(
        _database.students,
        _database.students.id.equalsExp(_database.users.student),
      ),
    ]);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return UserWithStudent(
      row.readTable(_database.users),
      row.readTable(_database.students),
    );
  }

  /// Gets the current user's avatar image, with local caching.
  ///
  /// Returns a [File] pointing to the cached avatar. Use with `Image.file()`.
  /// Returns `null` if not logged in, user has no avatar, or network is
  /// unavailable and no cached file exists.
  Future<File?> getAvatar() async {
    final user = await getCurrentUser();
    if (user == null || user.avatarFilename.isEmpty) {
      return null;
    }

    final filename = user.avatarFilename;
    final cacheDir = await getApplicationCacheDirectory();
    final file = File('${cacheDir.path}/avatars/$filename');

    if (await file.exists()) {
      return file;
    }

    try {
      final bytes = await withAuth(() => _portalService.getAvatar(filename));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return file;
    } on DioException {
      return null;
    }
  }

  /// Clears stored login credentials from secure storage.
  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  /// Clears cached avatar files.
  Future<void> _clearAvatarCache() async {
    final cacheDir = await getApplicationCacheDirectory();
    final avatarDir = Directory('${cacheDir.path}/avatars');
    if (await avatarDir.exists()) {
      await avatarDir.delete(recursive: true);
    }
  }
}
