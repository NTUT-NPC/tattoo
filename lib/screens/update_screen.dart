import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';

/// A full-screen update UI.
///
/// If `config.isForcedUpdate == true`, this acts as a non-dismissible gate,
/// and the router blocks navigation away from it.
/// If `config.isForcedUpdate == false`, this acts as an informational screen
/// with a back button and a "Later" button.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(updateConfigProvider);
    if (config == null) return const Scaffold();

    final requiredVersion = config.requiredVersion;
    final detail = config.detail;
    final isForced = config.isForcedUpdate;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.system_update_outlined, size: 80),
                    const SizedBox(height: 32),
                    Text(
                      t.forceUpdate.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.forceUpdate.message.spaced,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (requiredVersion.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.forceUpdate.requiredVersion(version: requiredVersion),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (isForced) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.forceUpdate.isForced,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        detail,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 40),
                    FilledButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(t.forceUpdate.updateButton),
                    ),
                    if (!isForced) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(t.forceUpdate.later),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    // Platform-specific store URLs — adjust to your actual app IDs.
    const compiledUrl = String.fromEnvironment('STORE_URL');
    final String url;
    if (compiledUrl.isNotEmpty && compiledUrl != 'https://ntut.app') {
      url = compiledUrl;
    } else {
      // Fallback platform-specific store URLs when compile-time STORE_URL is not set
      // e.g. for local/manual builds.
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        url = 'https://apps.apple.com/app/id1513875597';
      } else {
        url = 'https://play.google.com/store/apps/details?id=club.ntut.npc.tat';
      }
    }
    await launchUrl(Uri.parse(url), inExternalApplication: true);
  }
}
