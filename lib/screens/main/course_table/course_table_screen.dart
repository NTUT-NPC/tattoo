import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';

class CourseTableScreen extends StatelessWidget {
  const CourseTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
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
                    Row(
                      children: [],
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
