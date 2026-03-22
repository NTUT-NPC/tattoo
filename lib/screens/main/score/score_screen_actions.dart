import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/student_repository.dart';
import 'package:tattoo/screens/main/score/score_providers.dart';

Future<List<SemesterRecordData>> refreshSemesterRecords(WidgetRef ref) async {
  final records = await ref
      .read(studentRepositoryProvider)
      .getSemesterRecords(refresh: true);
  ref.invalidate(semesterRecordsProvider);
  return records;
}
