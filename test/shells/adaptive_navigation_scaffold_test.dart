import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/shells/adaptive_navigation_scaffold.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';

void main() {
  const destinations = [
    AdaptiveNavigationDestination(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    AdaptiveNavigationDestination(
      icon: Icon(Icons.school),
      label: 'Scores',
    ),
  ];

  Future<void> setWindowSize(
    WidgetTester tester, {
    required double width,
    double height = 800,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('centered frame fills narrow windows', (tester) async {
    await setWindowSize(tester, width: 400);
    const childKey = Key('frame-child');

    await tester.pumpWidget(
      const MaterialApp(
        home: CenteredMaxWidthFrame(
          child: SizedBox(key: childKey),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(childKey)).width, 400);
    expect(tester.getTopLeft(find.byKey(childKey)).dx, 0);
  });

  testWidgets('centered frame caps and centers wide windows', (tester) async {
    await setWindowSize(tester, width: 800);
    const childKey = Key('frame-child');

    await tester.pumpWidget(
      const MaterialApp(
        home: CenteredMaxWidthFrame(
          child: SizedBox(key: childKey),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(childKey)).width, contentMaxWidth);
    expect(
      tester.getTopLeft(find.byKey(childKey)).dx,
      (800 - contentMaxWidth) / 2,
    );
  });

  testWidgets('uses navigation bar below 580 pixels', (tester) async {
    await setWindowSize(tester, width: 579);

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationScaffold(
          body: const SizedBox(),
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('uses navigation rail from 580 pixels', (tester) async {
    await setWindowSize(tester, width: 580);

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationScaffold(
          body: const SizedBox(),
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('caps the wide main frame at 660 pixels', (tester) async {
    await setWindowSize(tester, width: 1000);
    const bodyKey = Key('navigation-body');

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationScaffold(
          body: const SizedBox(key: bodyKey),
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );

    final railWidth = tester.getSize(find.byType(NavigationRail)).width;
    expect(railWidth, greaterThanOrEqualTo(navigationRailMinWidth));
    expect(
      tester.getSize(find.byKey(bodyKey)).width,
      lessThanOrEqualTo(contentMaxWidth),
    );
    expect(
      tester.getSize(find.byType(Scaffold).first).width,
      mainFrameMaxWidth,
    );
    expect(
      tester.getTopLeft(find.byType(Scaffold).first).dx,
      (1000 - mainFrameMaxWidth) / 2,
    );
  });

  testWidgets('forwards destination selection', (tester) async {
    await setWindowSize(tester, width: 579);
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationScaffold(
          body: const SizedBox(),
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (index) => selectedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('Scores'));
    await tester.pump();

    expect(selectedIndex, 1);
  });
}
