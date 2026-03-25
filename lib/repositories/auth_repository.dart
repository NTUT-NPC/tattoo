import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/services/student_query/student_query_service.dart';
import 'package:tattoo/utils/http.dart';

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

/// Internal signal used by [AuthRepository._reauthenticate] to indicate that
/// re-authentication failed due to missing or rejected credentials.
/// The session is already destroyed before this is thrown.
class _AuthFailedException implements Exception {
  const _AuthFailedException();
}

const _secureStorage = FlutterSecureStorage();

/// Whether the user has an active authenticated session.
///
/// `true` after login, `false` after logout or auth failure. The router guard
/// watches this to redirect unauthenticated users to the login screen.
/// Session-scoped providers `ref.watch(sessionProvider)` to be recreated with
/// fresh state when the session ends.
class SessionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void create() => state = true;

  void destroy([LoginException? exception]) {
    ref.read(loginExceptionProvider.notifier).set(exception);
    state = false;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, bool>(
  SessionNotifier.new,
);

/// Holds the [LoginException] that caused the most recent session destruction,
/// or `null` for voluntary logout.
///
/// Read once by the login screen to show a contextual message, then cleared.
class LoginExceptionNotifier extends Notifier<LoginException?> {
  @override
  LoginException? build() => null;

  void set(LoginException? exception) => state = exception;
}

final loginExceptionProvider =
    NotifierProvider<LoginExceptionNotifier, LoginException?>(
      LoginExceptionNotifier.new,
    );

/// Provides the [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    portalService: ref.watch(portalServiceProvider),
    studentQueryService: ref.watch(studentQueryServiceProvider),
    database: ref.watch(databaseProvider),
    secureStorage: _secureStorage,
    onSessionCreated: () {
      ref.read(sessionProvider.notifier).create();
    },
    onSessionDestroyed: ([exception]) {
      ref.read(sessionProvider.notifier).destroy(exception);
    },
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
/// // Observe user profile (auto-refreshes when stale)
/// final stream = auth.watchUser();
///
/// // Force refresh (for pull-to-refresh)
/// await auth.refreshUser();
/// ```
class AuthRepository {
  final PortalService _portalService;
  final StudentQueryService _studentQueryService;
  final AppDatabase _database;
  final FlutterSecureStorage _secureStorage;
  final void Function() _onSessionCreated;
  final void Function([LoginException?]) _onSessionDestroyed;

  final _ssoCache = <PortalServiceCode>{};
  final _ssoInFlight = <PortalServiceCode, Completer<void>>{};
  Completer<UserDto>? _reauthenticateInFlight;

  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  AuthRepository({
    required PortalService portalService,
    required StudentQueryService studentQueryService,
    required AppDatabase database,
    required FlutterSecureStorage secureStorage,
    required void Function() onSessionCreated,
    required void Function([LoginException?]) onSessionDestroyed,
  }) : _portalService = portalService,
       _studentQueryService = studentQueryService,
       _database = database,
       _secureStorage = secureStorage,
       _onSessionCreated = onSessionCreated,
       _onSessionDestroyed = onSessionDestroyed;

  /// Authenticates with NTUT Portal and saves the user profile.
  ///
  /// Throws [LoginException] if login is rejected (wrong credentials, account
  /// locked, password expired, etc.). Throws [DioException] on network failure.
  /// On success, credentials are stored securely for auto-login.
  Future<User> login(String username, String password) async {
    final userDto = await _portalService.login(username, password);

    // Save credentials for auto-login
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
    _onSessionCreated();

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
    await _database.deleteEverything();
    await cookieJar.deleteAll();
    await _clearCredentials();
    await _clearAvatarCache();
    _ssoCache.clear();
    _ssoInFlight.clear();
    _onSessionDestroyed();
  }

  /// Executes [call] with automatic re-authentication on session expiry.
  ///
  /// If [sso] is provided, ensures SSO sessions are established for the
  /// listed services before calling [call]. SSO state is cached per service
  /// and only re-established when the portal session is refreshed.
  ///
  /// If [call] fails with a non-[DioException] error (indicating session
  /// expiry or auth failure), this method re-authenticates using stored
  /// credentials, re-establishes SSO sessions, and retries [call] once.
  /// Concurrent re-authentication attempts coalesce — only the first caller
  /// triggers the actual login; subsequent callers await the same result.
  ///
  /// On auth failure (missing or rejected credentials), destroys the session
  /// (triggering router guard redirect) and returns a never-completing future.
  /// Callers only need to handle [DioException] for network errors.
  Future<T> withAuth<T>(
    Future<T> Function() call, {
    List<PortalServiceCode> sso = const [],
  }) async {
    try {
      try {
        await _ensureSso(sso);
        return await call();
      } on DioException catch (e) {
        // Dio wraps all interceptor exceptions; unwrap SessionExpiredException
        // so the outer catch-all triggers re-authentication.
        if (e.error is SessionExpiredException) {
          Error.throwWithStackTrace(e.error!, e.stackTrace);
        }
        rethrow;
      }
    } on DioException {
      rethrow;
    } catch (_) {
      try {
        await _reauthenticate();
      } on _AuthFailedException {
        return Completer<T>().future;
      }

      await _ensureSso(sso);
      return await call();
    }
  }

  /// Re-authenticates using stored credentials, coalescing concurrent calls.
  ///
  /// Returns the [UserDto] from the login response. Concurrent callers
  /// receive the same result.
  ///
  /// Throws [_AuthFailedException] if credentials are missing or rejected
  /// (session is already destroyed). Rethrows [DioException] on network
  /// failure.
  Future<UserDto> _reauthenticate() async {
    if (_reauthenticateInFlight case final existing?) return existing.future;

    final completer = Completer<UserDto>();
    _reauthenticateInFlight = completer;
    try {
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      if (username == null || password == null) {
        _onSessionDestroyed(const LoginException(.credentialsMissing));
        throw const _AuthFailedException();
      }

      final userDto = await _portalService.login(username, password);
      _ssoCache.clear();
      _ssoInFlight.clear();
      completer.complete(userDto);
      return userDto;
    } on DioException catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } on LoginException catch (e) {
      await _clearCredentials();
      _onSessionDestroyed(e);
      throw const _AuthFailedException();
    } on _AuthFailedException {
      rethrow;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _reauthenticateInFlight = null;
    }
  }

  /// Establishes SSO sessions for services not yet cached.
  ///
  /// Concurrent calls for the same target coalesce — only the first caller
  /// triggers the actual SSO request; subsequent callers await the same
  /// [Completer].
  Future<void> _ensureSso(List<PortalServiceCode> services) async {
    await services.where((s) => !_ssoCache.contains(s)).map((s) async {
      if (_ssoInFlight[s] case final existing?) return existing.future;

      final completer = Completer<void>();
      _ssoInFlight[s] = completer;
      try {
        await _portalService.sso(s.code);
        _ssoCache.add(s);
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _ssoInFlight.remove(s);
      }
      return completer.future;
    }).wait;
  }

  /// Gets a browser-openable SSO URL for [serviceCode].
  ///
  /// Returns a URL containing an authorization code. Opening it in a system
  /// browser or any other HTTP client establishes an authenticated session for
  /// the target service without reusing this app's cookies.
  ///
  /// Uses [withAuth] to automatically re-authenticate if the portal session
  /// has expired.
  Future<Uri> getSsoUrl(String serviceCode) async {
    return withAuth(() => _portalService.getSsoUrl(serviceCode));
  }

  /// Gets the current user with automatic cache refresh.
  /// Watches the current user with automatic background refresh.
  ///
  /// Emits `null` when not logged in. Emits stale data immediately, then
  /// triggers a background network fetch if stale.
  /// The stream re-emits automatically when the DB is updated.
  ///
  /// Network errors during background refresh are absorbed — the stream
  /// continues showing stale data rather than erroring.
  Stream<User?> watchUser() async* {
    const ttl = Duration(days: 3);

    await for (final user
        in _database.select(_database.users).watchSingleOrNull()) {
      yield user;
      if (user == null) continue;

      final age = switch (user.fetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshUser();
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Refreshes login-level fields (avatar, name, email) via Portal login,
  /// and academic data (profile, registrations) via the student query service.
  /// The login call also establishes a fresh session for the subsequent SSO
  /// calls.
  ///
  /// On missing or rejected credentials, destroys the session and returns a
  /// never-completing future (router guard handles redirect).
  Future<void> refreshUser() async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      throw StateError('Cannot fetch user profile when not logged in');
    }

    // Re-login to refresh login-level fields and establish a fresh session.
    // This makes the subsequent withAuth call's inner SSO unlikely to need
    // re-authentication, since the session was just established.
    final UserDto userDto;
    try {
      userDto = await _reauthenticate();
    } on _AuthFailedException {
      return Completer<void>().future;
    }

    final (profile, records) = await withAuth(
      () async {
        final profileFuture = _studentQueryService.getStudentProfile();
        final recordsFuture = _studentQueryService.getRegistrationRecords();
        return (profileFuture, recordsFuture).wait;
      },
      sso: [.studentQueryService],
    );

    await _database.transaction(() async {
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
        final semester = await _database.getOrCreateSemester(
          record.semester.year!,
          record.semester.term!,
        );
        await _database
            .into(_database.userSemesterSummaries)
            .insert(
              UserSemesterSummariesCompanion.insert(
                user: user.id,
                semester: semester.id,
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
      if (!await _isDecodableImage(bytes)) {
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
  /// Preprocesses the image before upload: converts to JPEG, normalizes
  /// EXIF orientation, and compresses. See [_preprocessAvatar].
  ///
  /// Updates the stored avatar filename in the database and clears the
  /// local avatar cache so the next [getAvatar] call fetches the new image.
  ///
  /// Throws [AvatarTooLargeException] if processed image exceeds [maxAvatarSize].
  /// Throws [FormatException] if the image cannot be decoded.
  Future<void> uploadAvatar(Uint8List imageBytes) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      throw StateError('Cannot upload avatar when not logged in');
    }

    imageBytes = await _preprocessAvatar(imageBytes);

    if (imageBytes.length > maxAvatarSize) {
      throw AvatarTooLargeException(
        size: imageBytes.length,
        limit: maxAvatarSize,
      );
    }

    final newFilename = await withAuth(
      () => _portalService.uploadAvatar(imageBytes, user.avatarFilename),
    );

    await (_database.update(_database.users)
          ..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(avatarFilename: Value(newFilename)));

    await _clearAvatarCache();
  }

  /// Changes the user's NTUT Portal password.
  ///
  /// Requires an active session. Updates stored credentials so auto-login
  /// continues to work, then re-logins to refresh the session and clear
  /// the password expiry warning.
  ///
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      throw StateError('Cannot change password when not logged in');
    }

    await withAuth(
      () => _portalService.changePassword(currentPassword, newPassword),
    );

    // Update stored credentials so auto-login uses the new password
    await _secureStorage.write(key: _passwordKey, value: newPassword);

    // Best-effort re-login to refresh session and passwordExpiresInDays.
    // The password is already changed at this point, so don't fail if
    // the re-login hits a transient error.
    try {
      final userDto = await _portalService.login(user.studentId, newPassword);
      await (_database.update(
        _database.users,
      )..where((u) => u.id.equals(user.id))).write(
        UsersCompanion(
          passwordExpiresInDays: Value(userDto.passwordExpiresInDays),
        ),
      );
    } catch (_) {}
  }

  /// Watches the user's active registration (where enrollment status is "在學").
  ///
  /// Emits the most recent semester where the user is actively enrolled,
  /// or `null` if no active registration exists. Automatically re-emits
  /// when the underlying data changes (e.g., after [refreshUser] populates
  /// registration data or after cache clear).
  Stream<UserRegistration?> watchActiveRegistration() {
    return (_database.select(_database.userRegistrations)
          ..where(
            (r) => r.enrollmentStatus.equalsValue(EnrollmentStatus.learning),
          )
          ..orderBy([
            (r) => OrderingTerm.desc(r.year),
            (r) => OrderingTerm.desc(r.term),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Converts the image to JPEG, normalizes EXIF orientation, and compresses.
  ///
  /// Throws [FormatException] if the image cannot be decoded.
  static Future<Uint8List> _preprocessAvatar(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.jpeg,
        quality: 85,
        minWidth: 1200,
        minHeight: 1200,
      );
      return result;
    } catch (_) {
      throw const FormatException('Invalid image data');
    }
  }

  // Source - https://stackoverflow.com/a/76074236
  // License - CC BY-SA 4.0
  static Future<bool> _isDecodableImage(Uint8List bytes) async {
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
