import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';

/// A cached portal application together with its app-local favorite state.
typedef PortalApplicationData = ({
  PortalApplication application,
  bool isFavorite,
});

/// A cached portal category and its applications in portal display order.
typedef PortalApplicationCategoryData = ({
  PortalApplicationCategory category,
  List<PortalApplicationData> applications,
});

/// Provides the session-scoped [PortalRepository] instance.
final portalRepositoryProvider = Provider<PortalRepository>((ref) {
  ref.watch(sessionProvider);
  return PortalRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Manages the NTUT Portal application catalog and app-local favorites.
class PortalRepository {
  final PortalService _portalService;
  final AppDatabase _database;
  final AuthRepository _authRepository;
  Completer<void>? _refreshInFlight;

  PortalRepository({
    required this._portalService,
    required this._database,
    required this._authRepository,
  });

  /// Watches the current user's cached application catalog.
  ///
  /// Cached data and favorite changes are emitted through the same Drift
  /// stream. Missing data is fetched before the first empty value is yielded;
  /// stale data is yielded immediately and refreshed in the background.
  /// Network errors are absorbed so cached data remains available.
  Stream<List<PortalApplicationCategoryData>> watchApplicationCatalog() async* {
    const ttl = Duration(days: 1);

    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) {
      yield const [];
      return;
    }

    final categories = _database.portalApplicationCategories;
    final applications = _database.portalApplications;
    final favorites = _database.portalApplicationFavorites;
    final query =
        _database.select(categories).join([
            leftOuterJoin(
              applications,
              applications.category.equalsExp(categories.id),
            ),
            leftOuterJoin(
              favorites,
              favorites.user.equalsExp(categories.user) &
                  favorites.applicationCode.equalsExp(applications.code),
            ),
          ])
          ..where(categories.user.equals(user.id))
          ..orderBy([
            OrderingTerm.asc(categories.position),
            OrderingTerm.asc(applications.position),
          ]);

    await for (final rows in query.watch()) {
      final data = _mapCatalogRows(rows);
      final currentUser = await (_database.select(
        _database.users,
      )..where((row) => row.id.equals(user.id))).getSingleOrNull();
      if (currentUser == null) {
        yield const [];
        return;
      }

      var refreshedMissingCache = false;
      if (currentUser.applicationCatalogFetchedAt == null) {
        refreshedMissingCache = true;
        try {
          await refreshApplicationCatalog();
        } catch (_) {
          // Absorb: yield empty or stale data below.
        }
      }

      yield data;

      if (refreshedMissingCache) continue;
      final freshUser = await (_database.select(
        _database.users,
      )..where((row) => row.id.equals(user.id))).getSingleOrNull();
      final age = switch (freshUser?.applicationCatalogFetchedAt) {
        final fetchedAt? => DateTime.now().difference(fetchedAt),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshApplicationCatalog();
        } catch (_) {
          // Absorb: stale data is already visible through the stream.
        }
      }
    }
  }

  /// Fetches the complete catalog and atomically synchronizes the local cache.
  ///
  /// Concurrent calls coalesce. The portal session is refreshed through
  /// [AuthRepository] when needed; no service-specific SSO is required because
  /// this data comes from the portal itself.
  Future<void> refreshApplicationCatalog() {
    if (_refreshInFlight case final existing?) return existing.future;

    final completer = Completer<void>();
    _refreshInFlight = completer;
    unawaited(_completeRefresh(completer));
    return completer.future;
  }

  Future<void> _completeRefresh(Completer<void> completer) async {
    try {
      await _refreshApplicationCatalog();
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<void> _refreshApplicationCatalog() async {
    final user = await _database.select(_database.users).getSingle();
    final catalog = await _authRepository.withAuth(
      _portalService.getApplicationCatalog,
    );

    await _database.transaction(() async {
      final cachedEnglishNames =
          await (_database
                  .select(
                    _database.portalApplications,
                  )
                  .join([
                    innerJoin(
                      _database.portalApplicationCategories,
                      _database.portalApplicationCategories.id.equalsExp(
                        _database.portalApplications.category,
                      ),
                    ),
                  ])
                ..where(
                  _database.portalApplicationCategories.user.equals(user.id),
                ))
              .get();
      final cachedApplicationNameEnByCode = <String, String>{};
      for (final row in cachedEnglishNames) {
        final application = row.readTable(_database.portalApplications);
        if (application.nameEn case final name?) {
          cachedApplicationNameEnByCode[application.code] = name;
        }
      }

      final fetchedCategoryIds = <int>{};
      for (final (categoryPosition, categoryDto) in catalog.indexed) {
        final category = await _database
            .into(_database.portalApplicationCategories)
            .insertReturning(
              PortalApplicationCategoriesCompanion.insert(
                user: user.id,
                distinguishedName: categoryDto.distinguishedName,
                nameZh: categoryDto.nameZh,
                nameEn: Value(categoryDto.nameEn),
                position: categoryPosition,
              ),
              onConflict: DoUpdate(
                (old) => PortalApplicationCategoriesCompanion(
                  nameZh: Value(categoryDto.nameZh),
                  nameEn: .absentIfNull(categoryDto.nameEn),
                  position: Value(categoryPosition),
                ),
                target: [
                  _database.portalApplicationCategories.user,
                  _database.portalApplicationCategories.distinguishedName,
                ],
              ),
            );
        fetchedCategoryIds.add(category.id);

        final fetchedApplicationIds = <int>{};
        for (final (applicationPosition, applicationDto)
            in categoryDto.applications.indexed) {
          final nameEn =
              applicationDto.nameEn ??
              cachedApplicationNameEnByCode[applicationDto.code];
          final application = await _database
              .into(_database.portalApplications)
              .insertReturning(
                PortalApplicationsCompanion.insert(
                  category: category.id,
                  code: applicationDto.code,
                  nameZh: applicationDto.nameZh,
                  nameEn: Value(nameEn),
                  iconUrl: Value(applicationDto.iconUrl),
                  position: applicationPosition,
                ),
                onConflict: DoUpdate(
                  (old) => PortalApplicationsCompanion(
                    nameZh: Value(applicationDto.nameZh),
                    nameEn: .absentIfNull(nameEn),
                    iconUrl: Value(applicationDto.iconUrl),
                    position: Value(applicationPosition),
                  ),
                  target: [
                    _database.portalApplications.category,
                    _database.portalApplications.code,
                  ],
                ),
              );
          fetchedApplicationIds.add(application.id);
        }

        final staleApplications =
            _database.delete(
              _database.portalApplications,
            )..where((row) {
              final inCategory = row.category.equals(category.id);
              return fetchedApplicationIds.isEmpty
                  ? inCategory
                  : inCategory & row.id.isNotIn(fetchedApplicationIds);
            });
        await staleApplications.go();
      }

      final staleCategories =
          _database.delete(
            _database.portalApplicationCategories,
          )..where((row) {
            final belongsToUser = row.user.equals(user.id);
            return fetchedCategoryIds.isEmpty
                ? belongsToUser
                : belongsToUser & row.id.isNotIn(fetchedCategoryIds);
          });
      await staleCategories.go();

      await (_database.update(
        _database.users,
      )..where((row) => row.id.equals(user.id))).write(
        UsersCompanion(
          applicationCatalogFetchedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Sets one app-local favorite without changing NTUT Portal bookmarks.
  Future<void> setApplicationFavorite({
    required String applicationCode,
    required bool isFavorite,
  }) async {
    if (applicationCode.isEmpty) {
      throw ArgumentError.value(
        applicationCode,
        'applicationCode',
        'Application code cannot be empty.',
      );
    }

    final user = await _database.select(_database.users).getSingle();
    if (isFavorite) {
      await _database
          .into(_database.portalApplicationFavorites)
          .insert(
            PortalApplicationFavoritesCompanion.insert(
              user: user.id,
              applicationCode: applicationCode,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return;
    }

    await (_database.delete(_database.portalApplicationFavorites)..where(
          (row) =>
              row.user.equals(user.id) &
              row.applicationCode.equals(applicationCode),
        ))
        .go();
  }

  List<PortalApplicationCategoryData> _mapCatalogRows(
    List<TypedResult> rows,
  ) {
    final grouped = <int, PortalApplicationCategoryData>{};
    for (final row in rows) {
      final category = row.readTable(_database.portalApplicationCategories);
      final group = grouped.putIfAbsent(
        category.id,
        () => (category: category, applications: []),
      );
      final application = row.readTableOrNull(_database.portalApplications);
      if (application == null) continue;
      group.applications.add((
        application: application,
        isFavorite:
            row.readTableOrNull(_database.portalApplicationFavorites) != null,
      ));
    }
    return grouped.values.toList();
  }
}
