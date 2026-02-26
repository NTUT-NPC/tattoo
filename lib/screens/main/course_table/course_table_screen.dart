import 'package:flutter/material.dart';
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
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
                    tableOwnerIndicator(context),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                t.nav.courseTable,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tableOwnerIndicator(BuildContext context) {
    const shape = StadiumBorder();

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: shape,
        onTap: () {},
        child: Ink(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
          decoration: ShapeDecoration(shape: shape, color: Colors.grey[300]),
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
          color: Colors.grey[300],
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
