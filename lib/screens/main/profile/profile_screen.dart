import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tattoo/screens/main/profile/profile_card.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  static final _imagePicker = ImagePicker();
  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(authRepositoryProvider).getUser(refresh: true);
    await Future.wait([
      ref.refresh(userProfileProvider.future),
      ref.refresh(userAvatarProvider.future),
      ref.refresh(activeRegistrationProvider.future),
    ]);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    if (context.mounted) context.go(AppRoutes.intro);
  }

  Future<XFile?> _pickAvatarImage() {
    // Use OS picker to select a single image without broad media access.
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final imageFile = await _pickAvatarImage();
      if (!context.mounted || imageFile == null) return;

      _showMessage(context, t.profile.avatar.uploading);

      final imageBytes = await imageFile.readAsBytes();
      await ref.read(authRepositoryProvider).uploadAvatar(imageBytes);
      ref.invalidate(userAvatarProvider);

      if (!context.mounted) return;
      _showMessage(context, t.profile.avatar.uploadSuccess);
      await _scrollToTop(context);
    } catch (error) {
      if (!context.mounted) return;
      final message = _mapChangeAvatarError(error);
      _showMessage(context, message);
    }
  }

  String _mapChangeAvatarError(Object error) {
    return switch (error) {
      AvatarTooLargeException() => t.profile.avatar.tooLarge,
      FormatException() => t.profile.avatar.invalidFormat,
      NotLoggedInException() => t.errors.sessionExpired,
      InvalidCredentialsException() => t.errors.credentialsInvalid,
      DioException() => t.errors.connectionFailed,
      _ => t.profile.avatar.uploadFailed,
    };
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scrollToTop(BuildContext context) async {
    final scrollController = PrimaryScrollController.maybeOf(context);
    if (scrollController == null || !scrollController.hasClients) return;

    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _openInBrowser(
    BuildContext context,
    WidgetRef ref,
    PortalServiceCode serviceCode,
  ) async {
    try {
      final url = await ref
          .read(authRepositoryProvider)
          .withAuth(
            () => ref.read(portalServiceProvider).getSsoUrl(serviceCode.code),
          );
      final launched = await launchUrl(url);
      if (!launched) throw Exception('Could not open browser');
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Failed to open: $e');
    }
  }

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.general.notImplemented)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // settings options for the profile tab
    final options = [
      SectionHeader(title: t.profile.sections.accountSettings),
      OptionEntryTile(
        icon: Icons.password,
        title: t.profile.options.changePassword,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.image,
        title: t.profile.options.changeAvatar,
        onTap: () => _changeAvatar(context, ref),
      ),

      SectionHeader(title: t.$wip('資訊系統')),
      OptionEntryTile(
        icon: Icons.open_in_browser,
        title: t.$wip('學生查詢專區'),
        onTap: () =>
            _openInBrowser(context, ref, PortalServiceCode.studentQueryService),
      ),

      SectionHeader(title: 'TAT'),
      OptionEntryTile(
        icon: Icons.favorite_border_outlined,
        title: t.profile.options.supportUs,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.info_outline,
        title: t.profile.options.about,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        svgIconAsset: "assets/npc_logo.svg",
        title: t.profile.options.npcClub,
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: t.profile.sections.appSettings),
      OptionEntryTile(
        icon: Icons.settings_outlined,
        title: t.profile.options.preferences,
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.logout,
        title: t.profile.options.logout,
        onTap: () => _logout(context, ref),
      ),
    ];

    final notices = [
      // TODO: make notices dynamic and animated.
      SectionHeader(title: t.profile.sections.notices),

      BackgroundNotice(
        text: t.profile.notices.betaTesting,
        noticeType: NoticeType.info,
      ),

      BackgroundNotice(
        text: t.profile.notices.passwordExpiring,
        noticeType: NoticeType.warning,
      ),

      BackgroundNotice(
        text: t.profile.notices.connectionError,
        noticeType: NoticeType.error,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    spacing: 16,
                    children: [
                      ProfileCard(),

                      ClearNotice(
                        text: t.profile.dataDisclaimer,
                      ),

                      Column(
                        spacing: 8,
                        children: notices,
                      ),

                      Column(
                        spacing: 8,
                        children: options,
                      ),

                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) => ClearNotice(
                          text: snapshot.hasData
                              ? "TAT ${snapshot.data!.version} (${snapshot.data!.buildNumber})"
                              : "TAT",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
