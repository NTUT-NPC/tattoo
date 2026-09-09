import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/portal_repository.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';
import 'package:tattoo/utils/localized.dart';

final _portalApplicationCatalogProvider = StreamProvider(
  (ref) => ref.watch(portalRepositoryProvider).watchApplicationCatalog(),
);

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key});

  Future<void> _openNtutService(
    BuildContext context,
    WidgetRef ref,
    String serviceCode,
  ) async {
    try {
      await launchNtutService(
        ref.read(authRepositoryProvider),
        serviceCode,
      );
    } on DioException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.errors.connectionFailed)),
        );
    }
  }

  Future<void> _setFavorite(
    BuildContext context,
    WidgetRef ref,
    String applicationCode,
    bool isFavorite,
  ) async {
    try {
      await ref
          .read(portalRepositoryProvider)
          .setApplicationFavorite(
            applicationCode: applicationCode,
            isFavorite: isFavorite,
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.errors.occurred)));
    }
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(portalRepositoryProvider).refreshApplicationCatalog();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.errors.occurred)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.portal)),
      body: SafeArea(
        child: ref
            .watch(_portalApplicationCatalogProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(t.errors.connectionFailed)),
              data: (categories) => _PortalCatalog(
                categories: categories,
                onRefresh: () => _refresh(context, ref),
                onOpen: (code) => _openNtutService(context, ref, code),
                onFavoriteChanged: (code, favorite) =>
                    _setFavorite(context, ref, code, favorite),
              ),
            ),
      ),
    );
  }
}

class _PortalCatalog extends StatelessWidget {
  const _PortalCatalog({
    required this.categories,
    required this.onRefresh,
    required this.onOpen,
    required this.onFavoriteChanged,
  });

  final List<PortalApplicationCategoryData> categories;
  final RefreshCallback onRefresh;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String code, bool favorite) onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => category.applications.isNotEmpty)
        .toList();
    final favorites = visibleCategories
        .expand((category) => category.applications)
        .where((application) => application.isFavorite)
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const .all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: .center,
                spacing: 12,
                children: [
                  ClearNotice(text: t.portal.sourceNotice.spaced),
                  _PortalCard(
                    title: t.portal.openPortal,
                    onTap: () => launchUrl(
                      .parse('https://nportal.ntut.edu.tw'),
                    ),
                  ),
                  if (visibleCategories.isEmpty)
                    ClearNotice(text: t.portal.empty),
                  if (favorites.isNotEmpty) ...[
                    SectionHeader(title: t.portal.favorites),
                    for (final favorite in favorites)
                      _ApplicationCard(
                        application: favorite,
                        onOpen: onOpen,
                        onFavoriteChanged: onFavoriteChanged,
                      ),
                  ],
                  for (final category in visibleCategories)
                    Column(
                      crossAxisAlignment: .center,
                      spacing: 4,
                      children: [
                        SectionHeader(
                          title: localized(
                            category.category.nameZh,
                            category.category.nameEn,
                          ).spaced,
                        ),
                        for (final application in category.applications)
                          _ApplicationCard(
                            application: application,
                            onOpen: onOpen,
                            onFavoriteChanged: onFavoriteChanged,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onOpen,
    required this.onFavoriteChanged,
  });

  final PortalApplicationData application;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String code, bool favorite) onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final data = application.application;
    return Card(
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: () => onOpen(data.code),
        child: Padding(
          padding: const .only(left: 16, top: 4, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  localized(data.nameZh, data.nameEn).spaced,
                  maxLines: 2,
                  overflow: .ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: application.isFavorite
                    ? t.portal.removeFavorite
                    : t.portal.addFavorite,
                onPressed: () async {
                  await onFavoriteChanged(
                    data.code,
                    !application.isFavorite,
                  );
                },
                icon: Icon(
                  application.isFavorite ? Icons.star : Icons.star_border,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: .antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: .infinity,
          child: Padding(
            padding: const .symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              textAlign: .start,
              maxLines: 2,
              overflow: .ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
