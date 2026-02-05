import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/providers/database_provider.dart';
import 'package:tattoo/providers/service_providers.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/http.dart';

part 'auth_repository.g.dart';

/// User profile combining [User] and [Student] entities.
class UserWithStudent {
  UserWithStudent(this.user, this.student);

  final User user;
  final Student student;
}

const _secureStorage = FlutterSecureStorage();

/// Provides the [AuthRepository] instance.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    secureStorage: _secureStorage,
  );
}

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.
@riverpod
Future<UserWithStudent?> userProfile(Ref ref) {
  return ref.watch(authRepositoryProvider).getUserProfile();
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

  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  AuthRepository({
    required PortalService portalService,
    required AppDatabase database,
    required FlutterSecureStorage secureStorage,
  }) : _portalService = portalService,
       _database = database,
       _secureStorage = secureStorage;

  /// Authenticates with NTUT Portal and saves the user profile.
  ///
  /// Throws [Exception] if credentials are invalid or network fails.
  /// On success, credentials are stored securely for auto-login.
  Future<User> login(String username, String password) async {
    final userDto = await _portalService.login(username, password);

    // Save credentials for auto-login
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);

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
    await _secureStorage.deleteAll();
  }

  /// Attempts to login with stored credentials.
  ///
  /// Returns the [User] if auto-login succeeds, `null` if no credentials
  /// are stored or if login fails (e.g., password changed).
  /// On failure, stored credentials are cleared.
  Future<User?> tryAutoLogin() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);

    if (username == null || password == null) {
      return null;
    }

    try {
      return await login(username, password);
    } catch (_) {
      await _secureStorage.deleteAll();
      return null;
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

  /// Fetches the user's avatar image.
  ///
  /// Returns raw image bytes (JPEG). Use with `Image.memory(bytes)`.
  ///
  /// Throws [Exception] on network failure.
  Future<Uint8List> getAvatar(String filename) async {
    return _portalService.getAvatar(filename);
  }
}
