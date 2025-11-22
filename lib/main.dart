import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tattoo/data/course_client.dart';
import 'package:tattoo/data/i_school_plus_client.dart';
import 'package:tattoo/data/portal_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Tattoo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var _selectedService = PortalServiceCode.courseService;
  final _portalClient = PortalClient();
  final _courseClient = CourseClient();
  final _iSchoolPlusClient = ISchoolPlusClient();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    Stopwatch stopwatch = Stopwatch()..start();

    final user = await _portalClient.login(
      _usernameController.text,
      _passwordController.text,
    );
    inspect(user);

    await _portalClient.sso(_selectedService);

    switch (_selectedService) {
      case PortalServiceCode.courseService:
        final semesterList = await _courseClient.getCourseSemesterList(
          _usernameController.text,
        );
        inspect(semesterList);

        final courseSchedule = await _courseClient.getCourseTable(
          username: _usernameController.text,
          semester: semesterList.first,
        );
        inspect(courseSchedule);

        final course = await _courseClient.getCourse(
          courseSchedule
              .firstWhere((schedule) => schedule.course?.id != null)
              .course!,
        );
        inspect(course);
        break;
      case PortalServiceCode.iSchoolPlusService:
        await _portalClient.sso(PortalServiceCode.courseService);

        final semesterList = await _courseClient.getCourseSemesterList(
          _usernameController.text,
        );

        final courseSchedule = await _courseClient.getCourseTable(
          username: _usernameController.text,
          semester: semesterList.first,
        );

        final courses = courseSchedule.where((course) => course.number != null);
        inspect(courses);

        final students = await _iSchoolPlusClient.getStudents(
          courses.first.number!,
        );
        inspect(students);

        for (final course in courses) {
          final files = await _iSchoolPlusClient.getMaterials(course.number!);
          if (files.isEmpty) continue;
          inspect(files);
          break;
        }
        break;
      default:
        break;
    }

    stopwatch.stop();
    log('Completed in ${stopwatch.elapsedMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Project Tattoo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16.0,
              children: [
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                  ),
                  controller: _usernameController,
                  autofillHints: const [AutofillHints.username],
                ),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
                  obscureText: true,
                ),
                DropdownMenu<PortalServiceCode>(
                  initialSelection: PortalServiceCode.courseService,
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedService = value;
                    });
                  },
                  dropdownMenuEntries: [
                    for (final service in PortalServiceCode.values)
                      DropdownMenuEntry(value: service, label: service.name),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _login,
        tooltip: 'Login',
        child: const Icon(Icons.login),
      ),
    );
  }
}
