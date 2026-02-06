import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/providers/database_provider.dart';
import 'package:tattoo/providers/service_providers.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/http.dart';

part 'auth_repository.g.dart';

/// Provides the [AuthRepository] instance.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
  );
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

  AuthRepository({
    required PortalService portalService,
    required AppDatabase database,
  }) : _portalService = portalService,
       _database = database;

  /// Authenticates with NTUT Portal and saves the user profile.
  ///
  /// Throws [Exception] if credentials are invalid or network fails.
  Future<User> login(String username, String password) async {
    final userDto = await _portalService.login(username, password);

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

  /// Logs out and clears all local user data.
  Future<void> logout() async {
    await _database.delete(_database.users).go();
    await cookieJar.deleteAll();
  }

  /// Gets the current user's profile from local storage.
  ///
  /// Returns `null` if not logged in. Does not make network requests.
  Future<User?> getCurrentUser() async {
    return _database.select(_database.users).getSingleOrNull();
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
