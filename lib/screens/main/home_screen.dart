import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';
import 'package:tattoo/screens/whats_new_providers.dart';
import 'package:tattoo/screens/whats_new_screen.dart';
import 'package:tattoo/services/update_service.dart';
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
  bool _versionCheckScheduled = false;
  bool _checkingVersion = false;
  bool _versionCheckAgain = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _versionSnackbar;

  @override
  void initState() {
    super.initState();
    ref.listenManual(updateConfigProvider, (_, _) {
      _versionSnackbar?.close();
      _versionSnackbar = null;
      _scheduleVersionNotification();
    });
    _scheduleVersionNotification();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(
        userProfileProvider.select(
          (profile) => profile.asData?.value?.passwordExpiresInDays,
        ),
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
    });
  }

  void _scheduleVersionNotification() {
    if (_checkingVersion) {
      _versionCheckAgain = true;
      return;
    }
    if (_versionCheckScheduled) return;
    _versionCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _versionCheckScheduled = false;
      if (!mounted || _checkingVersion) return;
      _checkingVersion = true;
      try {
        await _maybeShowVersionNotification();
      } catch (error, stack) {
        debugPrint('Failed to show version notification: $error\n$stack');
      } finally {
        _checkingVersion = false;
        if (_versionCheckAgain) {
          _versionCheckAgain = false;
          _scheduleVersionNotification();
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _maybeShowVersionNotification() async {
    final config = ref.read(updateConfigProvider);
    if (config case final config?) {
      _maybeShowAppUpdateNotification(config);
      return;
    }
    await _maybeShowWhatsNewNotification();
  }

  void _maybeShowAppUpdateNotification(VersionConfig config) {
    if (config.isForcedUpdate || ref.read(optionalUpdateDismissedProvider)) {
      return;
    }
    ref.read(optionalUpdateDismissedProvider.notifier).dismiss();
    _showVersionSnackbar(
      config: config,
      content: Text(t.forceUpdate.title),
      action: SnackBarAction(
        label: t.forceUpdate.view,
        onPressed: () => context.push(AppRoutes.update),
      ),
    );
  }

  Future<void> _maybeShowWhatsNewNotification() async {
    if (ref.read(whatsNewPromptProvider) || currentWhatsNewFeatures().isEmpty) {
      return;
    }
    final whatsNew = ref.read(whatsNewPromptProvider.notifier);
    final version = await getCurrentSemVer();
    if (!await whatsNew.shouldPrompt(version)) return;
    if (!mounted || ref.read(whatsNewPromptProvider)) return;
    // Re-check after storage awaits so an update always takes priority.
    if (ref.read(updateConfigProvider) != null) {
      _scheduleVersionNotification();
      return;
    }
    whatsNew.markPromptScheduled();
    _showVersionSnackbar(
      config: null,
      content: Text(t.whatsNew.announcement.spaced),
      onVisible: () async {
        try {
          await whatsNew.recordPromptVisible(version);
        } catch (error) {
          debugPrint('Failed to save new-feature prompt count: $error');
        }
      },
      action: SnackBarAction(
        label: t.whatsNew.view.spaced,
        onPressed: () async {
          await whatsNew.markSeen(version);
          if (mounted) context.push(AppRoutes.whatsNew);
        },
      ),
    );
  }

  /// Owns only the visible version notification, never another queued warning.
  void _showVersionSnackbar({
    required VersionConfig? config,
    required Widget content,
    required SnackBarAction action,
    VoidCallback? onVisible,
  }) {
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        behavior: .fixed,
        duration: const Duration(seconds: 8),
        persist: false,
        action: action,
        onVisible: () {
          _versionSnackbar = controller;
          // A queued notification may have become obsolete behind a warning.
          if (!mounted || ref.read(updateConfigProvider) != config) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_versionSnackbar == controller) controller.close();
            });
            return;
          }
          onVisible?.call();
        },
      ),
    );
    controller.closed.then((_) {
      if (_versionSnackbar == controller) _versionSnackbar = null;
    });
  }

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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t.profile.passwordExpiry.warning(days: days).spaced,
        ),
        // SnackBar defaults persist=true when an action is set; we want the
        // warning to auto-dismiss so the user isn't left staring at it.
        persist: false,
        action: SnackBarAction(
          label: t.profile.passwordExpiry.action,
          onPressed: () => context.push(AppRoutes.changePassword),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
