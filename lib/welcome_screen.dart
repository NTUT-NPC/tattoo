import 'package:flutter/material.dart';
import 'package:tattoo/welcome_introduction_page.dart';
import 'package:tattoo/welcome_login_page.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

Future<void> springToNextPage(PageController controller) {
  if (!controller.hasClients) return Future.value();
  final ScrollPositionWithSingleContext position =
      controller.position as ScrollPositionWithSingleContext;
  final PageMetrics metrics = position as PageMetrics;
  final double viewportDimension = metrics.viewportDimension;
  final double viewportFraction = controller.viewportFraction;
  final double pageExtent = viewportDimension * viewportFraction;
  if (pageExtent == 0) return Future.value();

  final double currentPage = metrics.page ?? (position.pixels / pageExtent);
  final int targetPage = currentPage.floor() + 1;
  double targetPixels = targetPage * pageExtent;
  targetPixels = targetPixels.clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((position.pixels - targetPixels).abs() < 0.5) {
    return Future.value();
  }

  final physics = const PageScrollPhysics();
  final simulation = ScrollSpringSimulation(
    physics.spring,
    position.pixels,
    targetPixels,
    0,
    tolerance: physics.toleranceFor(position),
  );
  return position.animateWith(simulation);
}

Future<void> springToPreviousPage(PageController controller) {
  if (!controller.hasClients) return Future.value();
  final ScrollPositionWithSingleContext position =
      controller.position as ScrollPositionWithSingleContext;
  final PageMetrics metrics = position as PageMetrics;
  final double viewportDimension = metrics.viewportDimension;
  final double viewportFraction = controller.viewportFraction;
  final double pageExtent = viewportDimension * viewportFraction;
  if (pageExtent == 0) return Future.value();

  final double currentPage = metrics.page ?? (position.pixels / pageExtent);
  final int targetPage = currentPage.ceil() - 1;
  double targetPixels = targetPage * pageExtent;
  targetPixels = targetPixels.clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((position.pixels - targetPixels).abs() < 0.5) {
    return Future.value();
  }

  final physics = const PageScrollPhysics();
  final simulation = ScrollSpringSimulation(
    physics.spring,
    position.pixels,
    targetPixels,
    0,
    tolerance: physics.toleranceFor(position),
  );
  return position.animateWith(simulation);
}

extension _ScrollPositionWithSingleContextAnimation
    on ScrollPositionWithSingleContext {
  Future<void> animateWith(Simulation simulation) {
    final activity = DrivenScrollActivity.simulation(
      this,
      simulation,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }
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
              // Called by the intro page when the user swipes up at the bottom.
              springToNextPage(_pageController);
            },
          ),
          WelcomeLoginPage(
            onRequestPreviousPage: () {
              springToPreviousPage(_pageController);
            },
          ),
        ],
      ),
    );
  }
}
