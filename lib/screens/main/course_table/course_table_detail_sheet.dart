import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/utils/auto_spacing.dart';

Future<void> showCourseTableDetailSheet(
  BuildContext context, {
  required CourseTableCellData cell,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    constraints: BoxConstraints(
      minWidth: MediaQuery.sizeOf(context).width,
      maxWidth: MediaQuery.sizeOf(context).width,
    ),
    builder: (context) => CourseTableDetailSheet(cell: cell),
  );
}

class CourseTableDetailSheet extends StatelessWidget {
  const CourseTableDetailSheet({
    super.key,
    required this.cell,
  });

  final CourseTableCellData cell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: .fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            SizedBox(
              width: .infinity,
              child: Column(
                crossAxisAlignment: .center,
                children: [
                  Text(
                    (cell.courseName.isNotEmpty
                            ? cell.courseName
                            : cell.number ?? t.general.unknown)
                        .spaced,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: .infinity,
              child: Card(
                margin: .all(8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: .circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                color: theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: .all(12),
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 6,
                    children: [
                      // TODO: replace with course name when available
                      if (cell.number case final number?) Text('課號: $number'),
                      Text('教室: ${cell.classroomName ?? '-'}'.spaced),
                      Text('學分: ${cell.credits}'),
                      Text('時數: ${cell.hours}'),
                      Text('連續節數: ${cell.span}'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
            // TODO: scroll up to show more course query features like classmate, course outline, etc.
          ],
        ),
      ),
    );
  }
}
