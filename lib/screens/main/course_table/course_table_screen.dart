import 'package:flutter/material.dart';

class CourseTableScreen extends StatelessWidget {
  const CourseTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text('課表'))),
    );
  }
}
