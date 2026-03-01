import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScrollableShowcaseTemplate extends StatelessWidget {
  const ScrollableShowcaseTemplate({
    super.key,
    required this.verticalPadding,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.theme,
    required this.content,
    required this.bottom,
  });

  final double verticalPadding;
  final SvgPicture icon;
  final String title;
  final String? subtitle;
  final ThemeData theme;
  final Column content;
  final Column bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                verticalPadding,
                0,
                // Extra padding to avoid bottom bar overlap
                verticalPadding + 16,
              ),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(flex: 1),

                  // Logo and title
                  Column(
                    spacing: 4,
                    children: [
                      icon,
                      Text(
                        title,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),

                  Spacer(flex: 1),

                  // Features list
                  content,

                  Spacer(flex: 2),

                  // Logo and disclaimer
                  bottom,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
