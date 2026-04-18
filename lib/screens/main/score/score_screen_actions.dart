import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/student_repository.dart';

Future<void> refreshSemesterRecords(WidgetRef ref) async {
  await ref.read(studentRepositoryProvider).refreshSemesterRecords();
}
