// ignore_for_file: unused_field

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/providers/database_provider.dart';
import 'package:tattoo/providers/service_providers.dart';
import 'package:tattoo/services/portal_service.dart';

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
    throw UnimplementedError();
  }

  /// Checks if there's an active authenticated session.
  ///
  /// Does not throw.
  Future<bool> isLoggedIn() async {
    throw UnimplementedError();
  }

  /// Logs out and clears all local user data.
  Future<void> logout() async {
    throw UnimplementedError();
  }

  /// Gets the current user's profile from local storage.
  ///
  /// Returns `null` if not logged in. Does not make network requests.
  Future<User?> getCurrentUser() async {
    throw UnimplementedError();
  }

  /// Fetches the user's avatar image.
  ///
  /// Returns raw image bytes (JPEG). Use with `Image.memory(bytes)`.
  ///
  /// Throws [Exception] on network failure.
  Future<Uint8List> getAvatar(String filename) async {
    throw UnimplementedError();
  }
}
