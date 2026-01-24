import 'package:flutter/material.dart';
import 'package:tattoo/welcome_introduction_page.dart';
import 'package:tattoo/welcome_login_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          WelcomeIntroductionPage(
            onRequestNextPage: () {
              if (!_pageController.hasClients) return;
              // Called by the intro page when the user swipes up at the bottom.
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          const WelcomeLoginPage(),
        ],
      ),
    );
  }
}
