import 'package:flutter/material.dart';
import 'package:tattoo/welcome_login_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WelcomeLoginPage(),
    );
  }
}
