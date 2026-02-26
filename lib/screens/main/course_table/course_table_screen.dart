import 'package:flutter/material.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/i18n/strings.g.dart';

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
      length: _courseTableTabs.length,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: false,
              snap: false,
              toolbarHeight: 56,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
<<<<<<< HEAD
                      _tableOwnerIndicator(context),
=======
                      tableOwnerIndicator(context),
>>>>>>> refs/remotes/origin/score-screen-and-student-service
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              title: const ChipTabSwitcher(tabs: _courseTableTabs),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: _courseTableTabs
                    .map((tab) => _CourseTableTabPlaceholder(semester: tab))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _tableOwnerIndicator(BuildContext context) {
=======
  Widget tableOwnerIndicator(BuildContext context) {
>>>>>>> refs/remotes/origin/score-screen-and-student-service
    const shape = StadiumBorder();

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: shape,
<<<<<<< HEAD
        // TODO: implement course table sharing feature and switch here
=======
>>>>>>> refs/remotes/origin/score-screen-and-student-service
        onTap: () {},
        child: Ink(
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
                  child: Center(
                    // TODO: replace with avatar photo
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '孫',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  // TODO: Design text style here
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: "孫培鈞"),
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
    );
  }
}

const _courseTableTabs = <String>[
  '114-2',
  '114-1',
  '113-2',
  '113-1',
  '112-2',
  '112-1',
  '111-2',
  '111-1',
  '110-2',
];

class _CourseTableTabPlaceholder extends StatelessWidget {
  const _CourseTableTabPlaceholder({required this.semester});

  final String semester;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Course table placeholder: $semester'),
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
    return AspectRatio(
      aspectRatio: 1,
      child: SizedBox.expand(
        child: Material(
          color: Colors.white.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
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
      ),
    );
  }
}
