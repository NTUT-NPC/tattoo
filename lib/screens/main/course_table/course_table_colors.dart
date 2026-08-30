import 'package:flutter/material.dart';
import 'package:tattoo/repositories/course_repository.dart';

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
