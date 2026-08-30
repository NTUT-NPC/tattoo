import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';

/// Width at which the main navigation changes from a bar to a rail.
const navigationRailBreakpoint = 580.0;

/// Minimum width reserved for the compact navigation rail.
const navigationRailMinWidth = 80.0;

/// Shared data used to build bar and rail navigation destinations.
class AdaptiveNavigationDestination {
  const AdaptiveNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
}

/// Displays bottom navigation in compact windows and a rail in wide windows.
class AdaptiveNavigationScaffold extends StatelessWidget {
  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget body;
  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail =
            constraints.maxWidth >= navigationRailBreakpoint;

        return Scaffold(
          body: useNavigationRail
              ? Row(
                  children: [
                    NavigationRail(
                      minWidth: navigationRailMinWidth,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      groupAlignment: 1,
                      labelType: .all,
                      scrollable: true,
                      leading: Padding(
                        padding: const .only(top: 8),
                        child: SvgPicture.asset(
                          'assets/tat_icon.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      destinations: [
                        for (final destination in destinations)
                          NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon: destination.selectedIcon,
                            label: Text(destination.label),
                          ),
                      ],
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                    ),
                    Expanded(
                      child: CenteredMaxWidthFrame(child: body),
                    ),
                  ],
                )
              : CenteredMaxWidthFrame(child: body),
          bottomNavigationBar: useNavigationRail
              ? null
              : NavigationBar(
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: destination.label,
                      ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
        );
      },
    );
  }
}
