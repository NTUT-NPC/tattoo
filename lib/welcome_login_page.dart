import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

class WelcomeLoginPage extends StatefulWidget {
  const WelcomeLoginPage({super.key});

  @override
  State<WelcomeLoginPage> createState() => _WelcomeLoginPageState();
}

class _WelcomeLoginPageState extends State<WelcomeLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var _selectedService = PortalServiceCode.courseService;
  final _portalClient = PortalService();
  final _courseClient = CourseService();
  final _iSchoolPlusClient = ISchoolPlusService();

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
              .course!
              .id!,
        );
        inspect(course);
        break;
      case PortalServiceCode.iSchoolPlusService:
        // Open-Source System Software and Practice
        const courseNumber = "340689";
        final materials = await _iSchoolPlusClient.getMaterials(courseNumber);

        final redirectMaterial = await _iSchoolPlusClient.getMaterial(
          materials[0],
        );
        inspect(redirectMaterial);

        final pdfMaterial = await _iSchoolPlusClient.getMaterial(materials[1]);
        inspect(pdfMaterial);

        // Course recording materials are unimplemented
        try {
          final courseRecordingMaterial = await _iSchoolPlusClient.getMaterial(
            materials.last,
          );
          inspect(courseRecordingMaterial);
        } catch (e) {
          inspect(e.toString());
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
        title: const Text('Project Tattoo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            spacing: 24.0,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16.0,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                      ),
                      controller: _usernameController,
                      autofillHints: const [AutofillHints.username],
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.password],
                      obscureText: true,
                    ),
                  ],
                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _login,
        tooltip: 'Login',
        child: const Icon(Icons.login),
      ),
    );
  }
}
