import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';
import 'package:tattoo/shells/adaptive_navigation_scaffold.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _shownPasswordWarning = false;

  void _onDestinationSelected(int index) {
    final route =
        widget.navigationShell.route.branches[index].defaultRoute?.path;
    if (route == AppRoutes.profile) {
      ref.invalidate(dangerZoneActionProvider);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _showPasswordExpirySnackbar(BuildContext context, int days) {
    final t = Translations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            t.profile.passwordExpiry.warning(days: days).spaced,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      userProfileProvider.select((a) => a.asData?.value?.passwordExpiresInDays),
      (_, days) {
        if (days != null && !_shownPasswordWarning) {
          _shownPasswordWarning = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showPasswordExpirySnackbar(context, days);
          });
        }
      },
    );

    return AdaptiveNavigationScaffold(
      body: widget.navigationShell,
      destinations: <AdaptiveNavigationDestination>[
        AdaptiveNavigationDestination(
          icon: Icon(Icons.home),
          label: t.nav.home,
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.dashboard),
          label: t.nav.courseTable,
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.school),
          label: t.nav.scores,
        ),
        AdaptiveNavigationDestination(
          icon: Icon(Icons.account_circle),
          label: t.nav.profile,
        ),
      ],
      selectedIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
    );
  }
}
