import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/i18n/strings.g.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

Widget _sectionHeaderPreviewFrame({
  required Widget child,
  AlignmentGeometry alignment = Alignment.center,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'SectionHeader - Account Settings',
  group: 'SectionHeader',
  size: Size(420, 80),
)
Widget sectionHeaderAccountSettingsPreview() {
  return _sectionHeaderPreviewFrame(
    child: SectionHeader(title: t.profile.sections.accountSettings),
  );
}
