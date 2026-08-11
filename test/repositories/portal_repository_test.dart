import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/portal_repository.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  group('PortalRepository', () {
    late AppDatabase database;
    late _TestPortalService portalService;
    late PortalRepository repository;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      portalService = _TestPortalService();
      final authRepository = AuthRepository(
        portalService: portalService,
        studentQueryService: MockStudentQueryService(),
        database: database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        onSessionCreated: () {},
        onSessionDestroyed: ([exception]) {},
      );
      repository = PortalRepository(
        portalService: portalService,
        database: database,
        authRepository: authRepository,
      );
      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              studentId: '111592347',
              nameZh: '王大同',
              avatarFilename: '',
              email: 't111592347@ntut.edu.tw',
            ),
          );
    });

    tearDown(() => database.close());

    test('cold stream fetches and emits the cached catalog', () async {
      portalService.catalog = _catalog(
        categoryDn: 'OU=aa,OU=aproot',
        categoryName: '教務系統',
        applications: [
          (
            code: 'aa_0010-oauth',
            nameZh: '課程系統',
            nameEn: 'Curriculum System',
            iconUrl: 'https://icon',
          ),
        ],
      );

      final catalog = await repository
          .watchApplicationCatalog()
          .firstWhere((categories) => categories.isNotEmpty)
          .timeout(const Duration(seconds: 5));

      expect(portalService.catalogCalls, 1);
      expect(catalog.single.category.nameZh, '教務系統');
      expect(catalog.single.category.nameEn, 'System of Academic Affairs');
      expect(
        catalog.single.applications.single.application.code,
        'aa_0010-oauth',
      );
      expect(catalog.single.applications.single.isFavorite, isFalse);
      final user = await database.select(database.users).getSingle();
      expect(user.applicationCatalogFetchedAt, isNotNull);

      final cached = await repository.watchApplicationCatalog().first;
      expect(cached, isNotEmpty);
      expect(portalService.catalogCalls, 1);
    });

    test(
      'favorite re-emits and survives category moves and cache clears',
      () async {
        portalService.catalog = _catalog(
          categoryDn: 'OU=aa,OU=aproot',
          categoryName: '教務系統',
          applications: [
            (
              code: 'shared_oauth',
              nameZh: '共用系統',
              nameEn: 'Shared System',
              iconUrl: null,
            ),
          ],
        );
        await repository.refreshApplicationCatalog();

        final favoriteEmission = repository
            .watchApplicationCatalog()
            .firstWhere(
              (categories) =>
                  categories.isNotEmpty &&
                  categories.single.applications.single.isFavorite,
            )
            .timeout(const Duration(seconds: 5));
        await repository.setApplicationFavorite(
          applicationCode: 'shared_oauth',
          isFavorite: true,
        );
        await favoriteEmission;

        portalService.catalog = _catalog(
          categoryDn: 'OU=inf,OU=aproot',
          categoryName: '資訊服務',
          applications: [
            (
              code: 'shared_oauth',
              nameZh: '共用系統新名稱',
              nameEn: null,
              iconUrl: null,
            ),
          ],
        );
        await repository.refreshApplicationCatalog();

        final moved = await repository.watchApplicationCatalog().first;
        expect(moved.single.category.nameZh, '資訊服務');
        expect(
          moved.single.applications.single.application.nameZh,
          '共用系統新名稱',
        );
        expect(
          moved.single.applications.single.application.nameEn,
          'Shared System',
        );
        expect(moved.single.applications.single.isFavorite, isTrue);

        await database.deleteCachedData();
        expect(
          await database.select(database.portalApplicationCategories).get(),
          isEmpty,
        );
        expect(
          await database.select(database.portalApplicationFavorites).get(),
          hasLength(1),
        );
        final user = await database.select(database.users).getSingle();
        expect(user.applicationCatalogFetchedAt, isNull);
      },
    );

    test('refresh removes stale rows and preserves empty categories', () async {
      portalService.catalog = [
        ..._catalog(
          categoryDn: 'OU=aa,OU=aproot',
          categoryName: '教務系統',
          applications: [
            (
              code: 'old_oauth',
              nameZh: '舊系統',
              nameEn: 'Old System',
              iconUrl: null,
            ),
          ],
        ),
        ..._catalog(
          categoryDn: 'OU=sa,OU=aproot',
          categoryName: '學務系統',
          applications: [
            (
              code: 'removed_oauth',
              nameZh: '移除系統',
              nameEn: 'Removed System',
              iconUrl: null,
            ),
          ],
        ),
      ];
      await repository.refreshApplicationCatalog();

      portalService.catalog = _catalog(
        categoryDn: 'OU=aa,OU=aproot',
        categoryName: '教務資訊',
        applications: const [],
      );
      await repository.refreshApplicationCatalog();

      final catalog = await repository.watchApplicationCatalog().first;
      expect(catalog, hasLength(1));
      expect(catalog.single.category.nameZh, '教務資訊');
      expect(catalog.single.applications, isEmpty);
      expect(await database.select(database.portalApplications).get(), isEmpty);
    });

    test('missing English enrichment keeps cached translations', () async {
      portalService.catalog = _catalog(
        categoryDn: 'OU=aa,OU=aproot',
        categoryName: '教務系統',
        applications: [
          (
            code: 'aa_0010-oauth',
            nameZh: '課程系統',
            nameEn: 'Curriculum System',
            iconUrl: null,
          ),
        ],
      );
      await repository.refreshApplicationCatalog();

      portalService.catalog = [
        (
          distinguishedName: 'OU=aa,OU=aproot',
          nameZh: '教務資訊系統',
          nameEn: null,
          applications: [
            (
              code: 'aa_0010-oauth',
              nameZh: '課程系統新版',
              nameEn: null,
              iconUrl: null,
            ),
          ],
        ),
      ];
      await repository.refreshApplicationCatalog();

      final catalog = await repository.watchApplicationCatalog().first;
      expect(catalog.single.category.nameZh, '教務資訊系統');
      expect(catalog.single.category.nameEn, 'System of Academic Affairs');
      expect(
        catalog.single.applications.single.application.nameZh,
        '課程系統新版',
      );
      expect(
        catalog.single.applications.single.application.nameEn,
        'Curriculum System',
      );
    });

    test('concurrent refresh calls share one portal request', () async {
      final gate = Completer<List<PortalApplicationCategoryDto>>();
      portalService.catalogHandler = () => gate.future;

      final first = repository.refreshApplicationCatalog();
      await Future<void>.delayed(Duration.zero);
      final second = repository.refreshApplicationCatalog();
      expect(portalService.catalogCalls, 1);

      gate.complete(
        _catalog(
          categoryDn: 'OU=aa,OU=aproot',
          categoryName: '教務系統',
          applications: const [],
        ),
      );
      await Future.wait([first, second]);

      expect(portalService.catalogCalls, 1);
    });

    test('failed refresh keeps the previous cache and timestamp', () async {
      portalService.catalog = _catalog(
        categoryDn: 'OU=aa,OU=aproot',
        categoryName: '教務系統',
        applications: [
          (
            code: 'cached_oauth',
            nameZh: '快取系統',
            nameEn: 'Cached System',
            iconUrl: null,
          ),
        ],
      );
      await repository.refreshApplicationCatalog();
      final timestamp = (await database.select(database.users).getSingle())
          .applicationCatalogFetchedAt;

      portalService.catalogHandler = () => Future.error(
        DioException(
          requestOptions: RequestOptions(path: 'apPopupFull.do'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        repository.refreshApplicationCatalog(),
        throwsA(isA<DioException>()),
      );

      final catalog = await repository.watchApplicationCatalog().first;
      expect(
        catalog.single.applications.single.application.code,
        'cached_oauth',
      );
      expect(
        (await database.select(database.users).getSingle())
            .applicationCatalogFetchedAt,
        timestamp,
      );
    });
  });
}

List<PortalApplicationCategoryDto> _catalog({
  required String categoryDn,
  required String categoryName,
  required List<PortalApplicationDto> applications,
}) {
  return [
    (
      distinguishedName: categoryDn,
      nameZh: categoryName,
      nameEn: switch (categoryName) {
        '教務系統' => 'System of Academic Affairs',
        '學務系統' => 'Student Affairs System',
        _ => null,
      },
      applications: applications,
    ),
  ];
}

class _TestPortalService extends MockPortalService {
  List<PortalApplicationCategoryDto> catalog = const [];
  Future<List<PortalApplicationCategoryDto>> Function()? catalogHandler;
  int catalogCalls = 0;

  @override
  Future<List<PortalApplicationCategoryDto>> getApplicationCatalog() async {
    catalogCalls++;
    return catalogHandler?.call() ?? catalog;
  }
}
