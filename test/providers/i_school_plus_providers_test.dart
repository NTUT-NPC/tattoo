import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';
import 'package:tattoo/services/course/mock_course_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus/mock_i_school_plus_service.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  group('iSchoolPlusAvailabilityProvider', () {
    late AppDatabase database;
    late _TestISchoolPlusService iSchoolPlusService;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      iSchoolPlusService = _TestISchoolPlusService();
      final portalService = MockPortalService();
      final authRepository = AuthRepository(
        portalService: portalService,
        studentQueryService: MockStudentQueryService(),
        database: database,
        secureStorage: const FlutterSecureStorage(),
        isDemo: false,
        onSessionCreated: () {},
        onSessionDestroyed: ([exception]) {},
      );
      final courseRepository = CourseRepository(
        portalService: portalService,
        courseService: MockCourseService(),
        iSchoolPlusService: iSchoolPlusService,
        database: database,
        authRepository: authRepository,
        firebaseService: const FirebaseService(),
      );
      container = ProviderContainer(
        overrides: [
          courseRepositoryProvider.overrideWithValue(courseRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('reports an initially available service', () async {
      await container.read(iSchoolPlusAvailabilityProvider.future);

      expect(
        container.read(iSchoolPlusAvailabilityProvider),
        const AsyncData<void>(null),
      );
      expect(iSchoolPlusService.availabilityCalls, 1);
    });

    test('reports an initially unavailable service', () async {
      final error = StateError('iSchool Plus unavailable');
      iSchoolPlusService.availabilityError = error;

      await expectLater(
        container.read(iSchoolPlusAvailabilityProvider.future),
        throwsA(same(error)),
      );

      final state = container.read(iSchoolPlusAvailabilityProvider);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    });

    test('retries from loading and reports a subsequent success', () async {
      final initialRequest = Completer<void>();
      iSchoolPlusService.availabilityResult = initialRequest.future;
      final subscription = container.listen<AsyncValue<void>>(
        iSchoolPlusAvailabilityProvider,
        (_, _) {},
      );
      final initialFuture = container.read(
        iSchoolPlusAvailabilityProvider.future,
      );
      await pumpEventQueue();
      expect(container.read(iSchoolPlusAvailabilityProvider).isLoading, isTrue);

      initialRequest.complete();
      await initialFuture;
      iSchoolPlusService.availabilityResult = null;
      container.read(iSchoolPlusAvailabilityProvider.notifier).retry();

      expect(container.read(iSchoolPlusAvailabilityProvider).isLoading, isTrue);
      await container.read(iSchoolPlusAvailabilityProvider.future);
      expect(container.read(iSchoolPlusAvailabilityProvider).hasValue, isTrue);
      expect(iSchoolPlusService.availabilityCalls, 2);
      subscription.close();
    });

    test('retains a repeated failure after retry', () async {
      final error = StateError('iSchool Plus unavailable');
      iSchoolPlusService.availabilityError = error;
      await expectLater(
        container.read(iSchoolPlusAvailabilityProvider.future),
        throwsA(same(error)),
      );

      container.read(iSchoolPlusAvailabilityProvider.notifier).retry();
      expect(
        container.read(iSchoolPlusAvailabilityProvider).isLoading,
        isTrue,
      );
      await expectLater(
        container.read(iSchoolPlusAvailabilityProvider.future),
        throwsA(same(error)),
      );

      expect(
        container.read(iSchoolPlusAvailabilityProvider).error,
        same(error),
      );
      expect(iSchoolPlusService.availabilityCalls, 2);
    });

    test('ignores a late failure after markAvailable', () async {
      final oldRequest = Completer<void>();
      iSchoolPlusService.availabilityResult = oldRequest.future;
      final subscription = container.listen<AsyncValue<void>>(
        iSchoolPlusAvailabilityProvider,
        (_, _) {},
      );
      final oldFuture = container.read(iSchoolPlusAvailabilityProvider.future);
      await pumpEventQueue();

      container.read(iSchoolPlusAvailabilityProvider.notifier).markAvailable();
      oldRequest.completeError(StateError('late failure'));
      await oldFuture;

      expect(
        container.read(iSchoolPlusAvailabilityProvider),
        const AsyncData<void>(null),
      );
      subscription.close();
    });
  });
}

class _TestISchoolPlusService extends MockISchoolPlusService {
  Object? availabilityError;
  Future<void>? availabilityResult;
  var availabilityCalls = 0;

  @override
  Future<void> checkAvailability() async {
    availabilityCalls++;
    if (availabilityError case final error?) throw error;
    if (availabilityResult case final result?) return result;
  }
}
