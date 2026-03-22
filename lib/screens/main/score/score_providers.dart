import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/student_repository.dart';

/// Provides semester records (scores, GPA, rankings) for the score screen.
final semesterRecordsProvider =
    FutureProvider.autoDispose<List<SemesterRecordData>>((ref) async {
      try {
        return await ref.watch(studentRepositoryProvider).getSemesterRecords();
      } on NotLoggedInException {
        return [];
      }
    });
