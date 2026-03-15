import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/user_providers.dart';

// TODO: Import mock data from demo mode when implemented
const _placeholderOwnerName = '載入中';
const _placeholderAvatarInitial = '載';
const _loadingSemesterTabLabels = ['114-2', '114-1', '113-2'];

class CourseTableScreen extends StatelessWidget {
  const CourseTableScreen({super.key});

  void _showDemoTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.general.notImplemented)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: displayedSemesterTabLabels.isEmpty
          ? 1
          : displayedSemesterTabLabels.length,
      child: Scaffold(
        // A scaffold appbar to handle status bar height.
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              primary: false,
              toolbarHeight: 56,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TableOwnerIndicator(
                        context: context,
                        profileAsync: profileAsync,
                        avatarAsync: avatarAsync,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 8,
                        children: [
                          _CircularIconButton(
                            icon: Icons.refresh_outlined,
                            onTap: () => _showDemoTap(context),
                          ),
                          _CircularIconButton(
                            icon: Icons.share_outlined,
                            onTap: () => _showDemoTap(context),
                          ),
                          _CircularIconButton(
                            icon: Icons.more_vert_outlined,
                            onTap: () => _showDemoTap(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverAppBar(
              primary: false,
              floating: true,
              snap: true,
              pinned: false,
              toolbarHeight: 48,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 0,
              title: displayedSemesterTabLabels.isEmpty
                  ? const SizedBox.shrink()
                  : IgnorePointer(
                      ignoring: isSemesterLoading,
                      child: AppSkeleton(
                        enabled: isSemesterLoading,
                        child: ChipTabSwitcher(
                          tabs: displayedSemesterTabLabels,
                        ),
                      ),
                    ),
            ),
          ],
          body: switch (semestersAsync) {
            AsyncError(:final error) => Center(
              child: Text('Error: $error'),
            ),
            AsyncData(value: final semesters) when semesters.isEmpty => Center(
              child: Text(
                profileAsync.asData?.value == null
                    ? t.general.notLoggedIn
                    : t.courseTable.notFound,
              ),
            ),
            AsyncData(value: final semesters) => TabBarView(
              children: [
                for (final semester in semesters)
                  Consumer(
                    builder: (context, ref, child) {
                      final courseTableAsync = ref.watch(
                        courseTableProvider(semester),
                      );

                      return switch (courseTableAsync) {
                        AsyncError(:final error) => Center(
                          child: Text('Error: $error'),
                        ),
                        _ => LayoutBuilder(
                          builder: (context, constraints) {
                            return CourseTableGrid(
                              key: ValueKey(_semesterLabel(semester)),
                              courseTableData:
                                  courseTableAsync.asData?.value ??
                                  CourseTableData(),
                              loading:
                                  courseTableAsync.isLoading &&
                                  !courseTableAsync.hasValue,
                              viewportWidth: constraints.maxWidth,
                              viewportHeight: constraints.maxHeight,
                            );
                          },
                        ),
                      };
                    },
                  ),
              ],
            ),
            _ => LayoutBuilder(
              builder: (context, constraints) {
                return CourseTableGrid(
                  courseTableData: CourseTableData(),
                  loading: true,
                  viewportWidth: constraints.maxWidth,
                  viewportHeight: constraints.maxHeight,
                );
              },
            ),
          },
        ),
      ),
    );
  }
}

class _TableOwnerIndicator extends ConsumerWidget {
  const _TableOwnerIndicator();

  static const double _height = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final avatarAsync = ref.watch(userAvatarProvider);
    final profile = profileAsync.asData?.value;
    final avatarFile = avatarAsync.asData?.value;
    final isLoading = profileAsync is AsyncLoading<User?> && profile == null;
    final ownerName = switch (profileAsync) {
      AsyncLoading() => _placeholderOwnerName,
      AsyncData(value: null) => t.general.notLoggedIn,
      AsyncError() => t.general.unknown,
      _ when profile?.nameZh.isNotEmpty == true => profile!.nameZh,
      _ => t.general.unknown,
    };
    final avatarInitial = switch (profile?.nameZh) {
      final name? when name.isNotEmpty => name.substring(0, 1),
      _ when isLoading => _placeholderAvatarInitial,
      _ => '?',
    };

    const shape = StadiumBorder();

    return AppSkeleton(
      enabled: isLoading,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: shape,
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.black12,
          highlightColor: Colors.black12,
          // TODO: implement course table sharing feature and switch here
          onTap: () {},
          child: Ink(
            height: _height,
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
            decoration: ShapeDecoration(
              shape: shape,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: ClipOval(
                      child: switch (avatarFile) {
                        final file? => Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                        null => Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              avatarInitial,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      },
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    // TODO: Design text style here
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(text: ownerName),
                      // TODO: Enable this dropdown indicator when course table sharing feature is implemented
                      // WidgetSpan(
                      //   alignment: PlaceholderAlignment.middle,
                      //   child: Icon(
                      //     Icons.arrow_drop_down_outlined,
                      //     size:
                      //         (DefaultTextStyle.of(context).style.fontSize ?? 14) *
                      //         1.5,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashFactory: InkRipple.splashFactory,
          splashColor: Colors.black12,
          highlightColor: Colors.black12,
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = constraints.biggest.shortestSide * 0.45;

              return Center(
                child: Icon(icon, size: iconSize),
              );
            },
          ),
        ),
      ),
    );
  }
}
