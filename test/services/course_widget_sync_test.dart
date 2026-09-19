import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/services/course_widget_platform.dart';
import 'package:tattoo/services/course_widget_sync.dart';

void main() {
  group('CourseWidgetSyncController', () {
    late StreamController<void> changes;
    late FakeCourseWidgetPlatform platform;
    late LatestCachedCourseTable? latest;
    late CourseWidgetSyncController controller;
    late List<String> renderedVariants;

    setUp(() {
      changes = StreamController<void>.broadcast();
      platform = FakeCourseWidgetPlatform();
      latest = _cache('initial');
      renderedVariants = [];
      controller =
          CourseWidgetSyncController(
              () => changes.stream,
              () async => latest,
              platform,
            )
            ..attachRenderer((input) async {
              final name =
                  input.cache.courseTable.scheduled.values.single.courseName;
              final variant = '$name:${input.brightness.name}';
              renderedVariants.add(variant);
              return Uint8List.fromList(variant.codeUnits);
            })
            ..setPresentation(_presentation);
    });

    tearDown(() async {
      await changes.close();
    });

    test('startup reconciliation renders and commits once', () async {
      await controller.start();
      await controller.reconcile();
      await pumpEventQueue();

      expect(renderedVariants, ['initial:light', 'initial:dark']);
      expect(
        platform.operations.where((entry) => entry.startsWith('commit:')),
        hasLength(1),
      );
    });

    test('burst invalidations render only the latest cache snapshot', () async {
      await controller.start();
      await controller.reconcile();
      await pumpEventQueue();
      renderedVariants.clear();

      for (final name in ['first', 'second', 'latest']) {
        latest = _cache(name);
        changes.add(null);
      }
      await Future<void>.delayed(
        CourseWidgetSyncController.debounceDuration +
            const Duration(milliseconds: 50),
      );
      await pumpEventQueue();

      expect(renderedVariants, ['latest:light', 'latest:dark']);
    });

    test('equivalent canonical input neither renders nor commits', () async {
      await controller.start();
      await controller.reconcile();
      await pumpEventQueue();
      final commitCount = platform.operations
          .where((entry) => entry.startsWith('commit:'))
          .length;

      latest = _cache('initial');
      await controller.reconcile();
      await pumpEventQueue();

      expect(renderedVariants, ['initial:light', 'initial:dark']);
      expect(
        platform.operations.where((entry) => entry.startsWith('commit:')),
        hasLength(commitCount),
      );
    });

    test('a newer input during rendering discards the old PNG', () async {
      final firstRender = Completer<Uint8List>();
      controller.attachRenderer((input) {
        final name = input.cache.courseTable.scheduled.values.single.courseName;
        final variant = '$name:${input.brightness.name}';
        renderedVariants.add(variant);
        if (name == 'initial') return firstRender.future;
        return Future.value(Uint8List.fromList(variant.codeUnits));
      });
      await controller.start();
      await controller.reconcile();
      await pumpEventQueue();

      latest = _cache('newer');
      await controller.reconcile();
      firstRender.complete(Uint8List.fromList('stale'.codeUnits));
      await pumpEventQueue(times: 10);

      expect(renderedVariants, [
        'initial:light',
        'newer:light',
        'newer:dark',
      ]);
      final commits = platform.operations
          .where((entry) => entry.startsWith('commit:'))
          .toList();
      expect(commits, hasLength(1));
      expect(commits.single, endsWith(':newer:light|newer:dark'));
    });

    for (final clearMethod in ['stopAndClear', 'invalidateAndClear']) {
      test('$clearMethod leaves clear final after an old render', () async {
        final render = Completer<Uint8List>();
        controller.attachRenderer((_) => render.future);
        await controller.start();
        await controller.reconcile();
        await pumpEventQueue();

        final cleared = switch (clearMethod) {
          'stopAndClear' => controller.stopAndClear(),
          _ => controller.invalidateAndClear(),
        };
        await cleared;
        render.complete(Uint8List.fromList([1, 2, 3]));
        await pumpEventQueue(times: 10);

        expect(platform.operations.last, 'clear');
        expect(
          platform.operations.where((entry) => entry.startsWith('commit:')),
          isEmpty,
        );
      });
    }

    test('stop waits for an entered commit before clearing', () async {
      platform.commitGate = Completer<void>();
      await controller.start();
      await controller.reconcile();
      await pumpEventQueue();

      final stopped = controller.stopAndClear();
      await pumpEventQueue();
      expect(platform.operations.last, startsWith('commit:'));
      platform.commitGate!.complete();
      await stopped;

      expect(platform.operations.last, 'clear');
    });
  });
}

final _presentation = (
  locale: 'en-US',
  lightColors: ColorScheme.fromSeed(seedColor: Colors.blue),
  darkColors: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
);

LatestCachedCourseTable _cache(String name) {
  final cell = (
    id: 10,
    number: 'A',
    span: 1,
    crossesNoon: false,
    courseName: name,
    classroomName: 'Room',
    teacherNames: const <String>[],
    credits: 1.0,
    hours: 1,
  );
  return (
    semester: const Semester(
      id: 1,
      year: 114,
      term: 1,
      inCourseSemesterList: true,
      inScoreSemesterList: false,
    ),
    courseTable: (
      scheduled: {(day: DayOfWeek.monday, period: Period.first): cell},
      unscheduled: const <CourseTableCellData>[],
      hasWeekdayCourse: true,
      hasSaturdayCourse: false,
      hasSundayCourse: false,
      hasAMCourse: true,
      hasPMCourse: false,
      hasNoonCourse: false,
      hasEveningCourse: false,
      earliestPeriod: Period.first,
      latestPeriod: Period.first,
      totalCredits: 1,
      totalHours: 1,
    ),
  );
}

class FakeCourseWidgetPlatform implements CourseWidgetPlatform {
  final operations = <String>[];
  Completer<void>? commitGate;
  String? fingerprint;
  ValueChanged<String>? routeHandler;

  @override
  Future<void> clear() async {
    operations.add('clear');
    fingerprint = null;
  }

  @override
  Future<void> commitBitmaps({
    required Uint8List lightPng,
    required Uint8List darkPng,
    required String fingerprint,
  }) async {
    final light = String.fromCharCodes(lightPng);
    final dark = String.fromCharCodes(darkPng);
    operations.add('commit:$fingerprint:$light|$dark');
    await commitGate?.future;
    this.fingerprint = fingerprint;
  }

  @override
  Future<String?> readFingerprint() async {
    operations.add('read');
    return fingerprint;
  }

  @override
  void setRouteHandler(ValueChanged<String>? handler) {
    routeHandler = handler;
  }

  @override
  Future<String?> takePendingRoute() async => null;
}
