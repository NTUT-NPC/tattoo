import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/profile_card.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  static final _imagePicker = ImagePicker();

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
    final imageFile = await _pickAvatarImage();
    if (!context.mounted || imageFile == null) return;

    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('正在更新個人圖片...')));

    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw const FormatException('Selected image is empty');
      }

      await ref.read(authRepositoryProvider).uploadAvatar(imageBytes);
      ref.invalidate(userAvatarProvider);

      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('個人圖片已更新')));
      await _scrollToTop(context);
    } on NotLoggedInException {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('登入狀態已過期，請重新登入')));
      context.go(AppRoutes.intro);
    } on DioException {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('無法連線到伺服器，請檢查網路連線')));
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('更改個人圖片失敗，請稍後再試')));
    }
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

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('尚未實作')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // settings options for the profile tab
    final options = [
      SectionHeader(title: '帳號設定'),
      OptionEntryTile(
        icon: Icons.password,
        title: '更改密碼',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.image,
        title: '更改個人圖片',
        onTap: () => _changeAvatar(context, ref),
      ),

      SectionHeader(title: 'TAT'),
      OptionEntryTile(
        icon: Icons.favorite_border_outlined,
        title: '支持我們',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.info_outline,
        title: '關於 TAT',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        svgIconAsset: "assets/npc_logo.svg",
        title: '北科程式設計研究社',
        onTap: () => _showDemoTap(context),
      ),

      SectionHeader(title: '應用程式設定'),
      OptionEntryTile(
        icon: Icons.settings_outlined,
        title: '偏好設定',
        onTap: () => _showDemoTap(context),
      ),
      OptionEntryTile(
        icon: Icons.logout,
        title: '登出帳號',
        onTap: () => _logout(context, ref),
      ),
    ];

    final notices = [
      // TODO: make notices dynamic and animated.
      SectionHeader(title: "訊息範例"),

      BackgroundNotice(
        text: "目前新版的 TAT 仍在測試階段，若有問題歡迎和我們反映。",
        noticeType: NoticeType.info,
      ),

      BackgroundNotice(
        text: "您的密碼將於 7 天後到期，請盡快更新以免無法登入。",
        noticeType: NoticeType.warning,
      ),

      BackgroundNotice(
        text: "無法連接到伺服器，資料可能不正確。",
        noticeType: NoticeType.error,
      ),
    ];

    return Scaffold(
      body: SafeArea(
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
                      text: "本資料僅供參考，不做其他證明用途",
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
    );
  }
}
