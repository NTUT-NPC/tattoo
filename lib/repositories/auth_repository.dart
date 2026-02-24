import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/services/student_query_service.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';
import 'package:tattoo/utils/http.dart';

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

/// Thrown when the avatar image exceeds [AuthRepository.maxAvatarSize].
class AvatarTooLargeException implements Exception {
  final int size;
  final int limit;

  AvatarTooLargeException({required this.size, required this.limit});

  @override
  String toString() =>
      'AvatarTooLargeException: '
      'Image size ${size ~/ 1024 ~/ 1024} MB exceeds '
      'limit of ${limit ~/ 1024 ~/ 1024} MB.';
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

const _secureStorage = FlutterSecureStorage();

/// Provides the current [AuthStatus].
///
/// Updated automatically by [AuthRepository.withAuth] on success or failure.
class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.authenticated;

  void update(AuthStatus status) => state = status;
}

/// Provides the current [AuthStatus].
final authStatusProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(
  AuthStatusNotifier.new,
);

/// Provides the [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    portalService: ref.watch(portalServiceProvider),
    studentQueryService: ref.watch(studentQueryServiceProvider),
    database: ref.watch(databaseProvider),
    secureStorage: _secureStorage,
    onAuthStatusChanged: ref.read(authStatusProvider.notifier).update,
  );
});

/// Manages user authentication and profile data.
///
/// ```dart
/// final auth = ref.watch(authRepositoryProvider);
///
/// // Login
/// final user = await auth.login('111360109', 'password');
///
/// // Get user profile (with automatic cache refresh)
/// final user = await auth.getUser();
///
/// // Force refresh (for pull-to-refresh)
/// final user = await auth.getUser(refresh: true);
/// ```
class AuthRepository {
  final PortalService _portalService;
  final StudentQueryService _studentQueryService;
  final AppDatabase _database;
  final FlutterSecureStorage _secureStorage;
  final void Function(AuthStatus) _onAuthStatusChanged;

  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  AuthRepository({
    required PortalService portalService,
    required StudentQueryService studentQueryService,
    required AppDatabase database,
    required FlutterSecureStorage secureStorage,
    required void Function(AuthStatus) onAuthStatusChanged,
  }) : _portalService = portalService,
       _studentQueryService = studentQueryService,
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
      await _database.delete(_database.users).go();
      return _database
          .into(_database.users)
          .insertReturning(
            UsersCompanion.insert(
              studentId: username,
              nameZh: userDto.name ?? '',
              avatarFilename: userDto.avatarFilename ?? '',
              email: userDto.email ?? '',
              passwordExpiresInDays: Value(userDto.passwordExpiresInDays),
            ),
          );
    });
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

  /// Gets the current user with automatic cache refresh.
  ///
  /// Returns `null` if not logged in. Returns cached data if fresh (within TTL),
  /// fetches full profile from network if stale or missing. Falls back to stale
  /// cached data when offline (network errors are absorbed).
  ///
  /// The returned user may have partial data ([User.fetchedAt] is null) if only
  /// login has been performed. Full profile data is fetched automatically when
  /// [User.fetchedAt] is null or stale.
  ///
  /// Set [refresh] to `true` to bypass TTL and always refetch (for pull-to-refresh).
  Future<User?> getUser({bool refresh = false}) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) return null; // Not logged in, can't fetch

    try {
      return await fetchWithTtl<User>(
        cached: user,
        getFetchedAt: (u) => u.fetchedAt,
        fetchFromNetwork: _fetchUserFromNetwork,
        refresh: refresh,
      );
    } on DioException {
      return user;
    }
  }

  /// Fetches all user data from network.
  ///
  /// Refreshes login-level fields (avatar, name, email) via Portal login,
  /// and academic data (profile, registrations) via the student query service.
  /// The login call also establishes a fresh session for the subsequent SSO
  /// calls.
  Future<User> _fetchUserFromNetwork() async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      throw StateError('Cannot fetch user profile when not logged in');
    }

    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (username == null || password == null) {
      _onAuthStatusChanged(AuthStatus.credentialsExpired);
      throw NotLoggedInException();
    }

    // Re-login to refresh login-level fields and establish a fresh session.
    // This makes the subsequent withAuth call's inner SSO unlikely to need
    // re-authentication, since the session was just established.
    final UserDto userDto;
    try {
      userDto = await _portalService.login(username, password);
    } on DioException {
      _onAuthStatusChanged(AuthStatus.offline);
      rethrow;
    } catch (_) {
      await _clearCredentials();
      _onAuthStatusChanged(AuthStatus.credentialsExpired);
      throw InvalidCredentialsException();
    }
    _onAuthStatusChanged(AuthStatus.authenticated);

    final (profile, records) = await withAuth(() async {
      await _portalService.sso(PortalServiceCode.studentQueryService);
      final profileFuture = _studentQueryService.getStudentProfile();
      final recordsFuture = _studentQueryService.getRegistrationRecords();
      return (await profileFuture, await recordsFuture);
    });

    return _database.transaction(() async {
      await (_database.update(
        _database.users,
      )..where((t) => t.id.equals(user.id))).write(
        UsersCompanion(
          avatarFilename: Value(userDto.avatarFilename ?? ''),
          nameZh: Value(userDto.name ?? ''),
          email: Value(userDto.email ?? ''),
          nameEn: Value(profile.englishName),
          dateOfBirth: Value(profile.dateOfBirth),
          programZh: Value(profile.programZh),
          programEn: Value(profile.programEn),
          departmentZh: Value(profile.departmentZh),
          departmentEn: Value(profile.departmentEn),
          fetchedAt: Value(DateTime.now()),
        ),
      );

      for (final record in records) {
        if (record.semester.year == null || record.semester.term == null) {
          continue;
        }
        final semesterId = await _database.getOrCreateSemester(
          record.semester.year!,
          record.semester.term!,
        );
        await _database
            .into(_database.userSemesterSummaries)
            .insert(
              UserSemesterSummariesCompanion.insert(
                user: user.id,
                semester: semesterId,
                className: Value(record.className),
                enrollmentStatus: Value(record.enrollmentStatus),
                registered: Value(record.registered),
                graduated: Value(record.graduated),
              ),
              onConflict: DoUpdate(
                (old) => UserSemesterSummariesCompanion(
                  className: Value(record.className),
                  enrollmentStatus: Value(record.enrollmentStatus),
                  registered: Value(record.registered),
                  graduated: Value(record.graduated),
                ),
                target: [
                  _database.userSemesterSummaries.user,
                  _database.userSemesterSummaries.semester,
                ],
              ),
            );
      }

      return _database.select(_database.users).getSingle();
    });
  }

  /// Gets the current user's avatar image, with local caching.
  ///
  /// Returns a [File] pointing to the cached avatar. Use with `Image.file()`.
  /// Returns `null` if not logged in, user has no avatar, or network is
  /// unavailable and no cached file exists.
  Future<File?> getAvatar() async {
    final user = await _database.select(_database.users).getSingleOrNull();
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
      if (!await _isImageValid(bytes)) {
        await file.delete();
        return null;
      }
      return file;
    } on DioException {
      return null;
    }
  }

  /// Maximum avatar file size (20 MB), matching NTUT's client-defined limit.
  static const maxAvatarSize = 20 * 1024 * 1024;

  /// Uploads a new avatar image, replacing the current one.
  ///
  /// Updates the stored avatar filename in the database and clears the
  /// local avatar cache so the next [getAvatar] call fetches the new image.
  ///
  /// Throws [NotLoggedInException] if not logged in.
  /// Throws [AvatarTooLargeException] if [imageBytes] exceeds [maxAvatarSize].
  Future<void> uploadAvatar(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw const FormatException('Invalid image data');
    }

    if (imageBytes.length > maxAvatarSize) {
      throw AvatarTooLargeException(
        size: imageBytes.length,
        limit: maxAvatarSize,
      );
    }

    if (!await _isImageValid(imageBytes)) {
      throw const FormatException('Invalid image data');
    }

    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      throw NotLoggedInException();
    }

    final newFilename = await withAuth(
      () => _portalService.uploadAvatar(imageBytes, user.avatarFilename),
    );

    await (_database.update(_database.users)
          ..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(avatarFilename: Value(newFilename)));

    await _clearAvatarCache();
  }

  /// Gets the user's active registration (where enrollment status is "在學").
  ///
  /// Returns the most recent semester where the user is actively enrolled,
  /// or `null` if no active registration exists.
  /// Pure DB read — call [getUser] first to populate registration data.
  Future<UserRegistration?> getActiveRegistration() async {
    return (_database.select(_database.userRegistrations)
          ..where(
            (r) => r.enrollmentStatus.equalsValue(EnrollmentStatus.learning),
          )
          ..orderBy([
            (r) => OrderingTerm.desc(r.year),
            (r) => OrderingTerm.desc(r.term),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  // Source - https://stackoverflow.com/a/76074236
  // License - CC BY-SA 4.0
  static Future<bool> _isImageValid(Uint8List bytes) async {
    Codec? codec;
    FrameInfo? frameInfo;
    try {
      codec = await instantiateImageCodec(bytes, targetWidth: 32);
      frameInfo = await codec.getNextFrame();
      return frameInfo.image.width > 0;
    } catch (_) {
      return false;
    } finally {
      frameInfo?.image.dispose();
      codec?.dispose();
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
