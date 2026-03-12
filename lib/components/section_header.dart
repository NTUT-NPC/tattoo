import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'widget_preview_frame.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.color, super.key});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

@Preview(
  name: 'SectionHeader - Account Settings',
  group: 'SectionHeader',
  size: Size(420, 80),
)
Widget sectionHeaderAccountSettingsPreview() {
  return WidgetPreviewFrame(
    child: SectionHeader(title: t.profile.sections.accountSettings),
  );
}
