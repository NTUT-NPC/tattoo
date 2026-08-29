import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';

class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({super.key});

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Show the optional update snackbar once on first mount, after the frame is
    // ready so ScaffoldMessenger is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowUpdateSnackbar();
    });
  }

  /// Shows a floating snackbar when an optional update is pending and the user
  /// has not already dismissed it this session.
  void _maybeShowUpdateSnackbar() {
    if (!mounted) return;
    final config = ref.read(updateConfigProvider);

    // If it's a forced update, ensure no optional snackbar is left hanging.
    if (config?.isForcedUpdate == true) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }

    final dismissed = ref.read(optionalUpdateDismissedProvider);
    if (config == null || dismissed) return;

    // Mark as dismissed so the snackbar isn't re-shown on hot-reload / re-entry.
    ref.read(optionalUpdateDismissedProvider.notifier).dismiss();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.forceUpdate.title),
        behavior: .fixed,
        duration: const Duration(seconds: 8),
        // Breaking change in Flutter 3.38, when snack bar with action, auto-dismiss will be disaable unless set persist=false.
        persist: false,
        action: SnackBarAction(
          label: t.forceUpdate.view,
          onPressed: () => context.push(AppRoutes.update),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-show snackbar when Remote Config pushes a fresh optional update during
    // the session (UpdateService resets optionalUpdateDismissedProvider first).
    // If it's a forced update, this will clear any existing snackbar.
    ref.listen(updateConfigProvider, (_, config) {
      if (config == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        });
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowUpdateSnackbar();
      });
    });

    final options = [
      OptionEntryTile.svg(
        svgIconAsset: "assets/tat_icon.svg",
        actionIcon: .exitToApp,
        title: t.home.projectTattoo.title.spaced,
        description: t.home.projectTattoo.description,
        onTap: () => launchUrl(.parse(t.home.projectTattoo.url)),
      ),
      OptionEntryTile.icon(
        icon: Icons.explore_outlined,
        actionIcon: .exitToApp,
        title: t.home.ideation.title.spaced,
        description: t.home.ideation.description,
        onTap: () => launchUrl(
          .parse(t.home.ideation.url),
        ),
      ),
      OptionEntryTile.svg(
        svgIconAsset: "assets/npc_logo.svg",
        actionIcon: .exitToApp,
        title: t.home.npcClub.title,
        description: t.home.npcClub.description,
        onTap: () => launchUrl(.parse(t.home.npcClub.url)),
      ),
      ...(_showVoteEntry()
          ? <Widget>[
              OptionEntryTile.icon(
                icon: Icons.how_to_vote_outlined,
                title: t.nav.vote,
                description: t.home.vote.description.spaced,
                onTap: () => context.push(AppRoutes.kioskLoginQr),
              ),
            ]
          : <Widget>[]),
      OptionEntryTile.icon(
        icon: Icons.qr_code_scanner,
        title: t.scanner.loginIStudy.spaced,
        onTap: () => context.push(AppRoutes.scanner),
      ),
      OptionEntryTile.icon(
        icon: Icons.switch_access_shortcut_outlined,
        title: t.nav.portal,
        onTap: () => context.push(AppRoutes.portal),
      ),
      OptionEntryTile.icon(
        icon: Icons.calendar_month,
        title: t.nav.calendar,
        onTap: () => context.push(AppRoutes.calendar),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.home)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                spacing: 8,
                children: options,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _showVoteEntry() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 8))
    .isBefore(.utc(2026, 5, 16));
