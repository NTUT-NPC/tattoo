import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tattoo/data/course_client.dart';
import 'package:tattoo/data/i_school_plus_client.dart';
import 'package:tattoo/data/portal_client.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeLoginPage extends StatefulWidget {
  const WelcomeLoginPage({super.key});

  @override
  State<WelcomeLoginPage> createState() => _WelcomeLoginPageState();
}

class _WelcomeLoginPageState extends State<WelcomeLoginPage> {
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
    final double screenHeight = MediaQuery.of(context).size.height;

    // A helper function to style login fields
    loginDecoration(String hintText) {
      final surfaceColor = Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest;
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        filled: true,
        fillColor: surfaceColor,
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 24,
              children: [
                // welcome title
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: [
                      const TextSpan(text: '歡迎加入'),
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text: '北科生活',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // login instruction
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[600],
                    ),
                    children: [
                      const TextSpan(text: '請使用'),
                      TextSpan(
                        text: '北科校園入口網站',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(Uri.parse('https://nportal.ntut.edu.tw'));
                          },
                      ),
                      const TextSpan(text: '的帳號密碼登入。'),
                    ],
                  ),
                ),

                // login form
                AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 16,
                    children: [
                      TextField(
                        controller: _usernameController,
                        maxLines: 1,
                        decoration: loginDecoration('學號'),
                      ),
                      TextField(
                        controller: _passwordController,
                        maxLines: 1,
                        decoration: loginDecoration('密碼'),
                        autofillHints: const [AutofillHints.password],
                        obscureText: true,
                      ),
                    ],
                  ),
                ),

                // login button
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('登入'),
                ),

                // terms of privacy
                Column(
                  spacing: 8.0,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: screenHeight * 0.03,
                      color: Colors.grey[600],
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          color: Colors.grey[600],
                        ),
                        children: [
                          const TextSpan(text: '登入資訊將被安全地儲存在您的裝置中'),
                          const TextSpan(text: '\n'),
                          const TextSpan(text: '登入即表示您同意我們的'),
                          TextSpan(
                            text: '隱私條款',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(
                                  Uri.parse(
                                    'https://example.com/terms-of-service',
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
