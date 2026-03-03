import 'package:flutter/material.dart';

/// A vertically centered showcase layout with icon/title header, body, and footer.
///
/// This shell is designed for onboarding or intro-style pages where the main
/// content should stay centered while still allowing scrolling on small screens.
///
/// Example:
/// ```dart
/// ShowcaseShell(
///   icon: const Icon(Icons.school_outlined, size: 64),
///   title: 'Tattoo',
///   subtitle: 'NTUT Course Assistant',
///   body: const Text('Feature list goes here'),
///   footer: const Text('Powered by NTUT'),
/// )
/// ```
class ShowcaseShell extends StatelessWidget {
  /// Creates a centered showcase page scaffold.
  const ShowcaseShell({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.body,
    required this.footer,
  });

  /// Header icon displayed above [title].
  final Widget icon;

  /// Main headline text shown near the top center.
  final String title;

  /// Optional secondary text shown under [title].
  final String? subtitle;

  /// Main content section shown between the header and footer.
  final Widget body;

  /// Bottom section, typically used for branding or a disclaimer.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.1;

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
                  body,

                  Spacer(flex: 2),

                  // Logo and disclaimer
                  footer,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
