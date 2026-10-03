import 'package:material_ui/material_ui.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Colors shared by interactive and exported timetable cells.
typedef CourseTableCellPalette = ({
  Color container,
  Color border,
  Color foreground,
});

/// Derives the timetable-cell palette from its stable base color.
CourseTableCellPalette courseTableCellPalette(
  Color baseColor,
  Brightness brightness,
) {
  final isDark = brightness == .dark;
  return (
    container: HSLColor.fromColor(baseColor)
        .withLightness(isDark ? 0.7 : 0.9)
        .withSaturation(isDark ? 0.2 : 0.4)
        .toColor(),
    border: HSLColor.fromColor(baseColor)
        .withLightness(0.3)
        .withSaturation(isDark ? 0.5 : 0.6)
        .toColor(),
    foreground: Colors.grey[900]!,
  );
}

const _courseTableColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.amber,
  Colors.cyan,
  Colors.deepOrange,
  Colors.lightGreen,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.lime,
  Colors.brown,
  Colors.blueGrey,
  Colors.redAccent,
  Colors.blueAccent,
  Colors.greenAccent,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
  Colors.pinkAccent,
  Colors.indigoAccent,
  Colors.amberAccent,
  Colors.cyanAccent,
  Colors.deepOrangeAccent,
  Colors.lightGreenAccent,
  Colors.deepPurpleAccent,
  Colors.lightBlueAccent,
  Colors.limeAccent,
  Colors.yellow,
  Colors.grey,
  Colors.yellowAccent,
];

/// Assigns a stable color to every course in a course-table snapshot.
Map<int, Color> buildCourseTableColorMap(CourseTableData courseTableData) {
  final courseIds = {
    ...courseTableData.scheduled.values.map((cell) => cell.id),
    ...courseTableData.unscheduled.map((cell) => cell.id),
  }.toList()..sort();

  return {
    for (var i = 0; i < courseIds.length; i++)
      courseIds[i]: _courseTableColors[i % _courseTableColors.length],
  };
}
