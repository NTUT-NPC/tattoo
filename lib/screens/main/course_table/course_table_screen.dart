import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';

class CourseTableScreen extends StatelessWidget {
  const CourseTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text(t.nav.courseTable))),
    );
  }
}
