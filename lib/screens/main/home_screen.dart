import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';

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
          content: Text(t.profile.passwordExpiry.warning(days: days)),
          action: SnackBarAction(
            label: t.profile.passwordExpiry.action,
            onPressed: () => messenger.showSnackBar(
              SnackBar(content: Text(t.general.notImplemented)),
            ), // TODO: navigate to change-password flow
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

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: t.nav.courseTable,
          ),
          NavigationDestination(icon: Icon(Icons.school), label: t.nav.scores),
          NavigationDestination(
            icon: Icon(Icons.switch_access_shortcut_outlined),
            label: t.nav.portal,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: t.nav.profile,
          ),
        ],
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
