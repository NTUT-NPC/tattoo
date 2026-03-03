import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'widget_preview_frame.dart';

/// Built-in trailing icon options for [OptionEntryTile].
enum OptionEntryTileActionIcon {
  /// Shows [Icons.navigate_next], typically used for in-app navigation.
  navigateNext,

  /// Shows [Icons.exit_to_app], typically used for external links.
  exitToApp,
}

/// A reusable, tappable option row used in settings/profile style lists.
///
/// The tile renders:
/// 1. A leading widget
/// 2. A title ([title]) and optional description ([description])
/// 3. A trailing action icon, chosen from [actionIcon] or overridden by
///    [customActionIcon]
///
/// [customActionIcon] takes precedence over [actionIcon] when both are set.
///
/// Example:
/// ```dart
/// OptionEntryTile.icon(
///   icon: Icons.person_outline_rounded,
///   title: 'Profile',
///   description: 'View and edit your profile',
///   onTap: () => context.push('/profile'),
/// );
///
/// OptionEntryTile.icon(
///   title: 'Settings',
///   description: 'Default leading icon with custom description',
/// );
///
/// OptionEntryTile.svg(
///   svgIconAsset: 'assets/settings.svg',
///   title: 'Settings',
///   onTap: openSettings,
/// );
///
/// OptionEntryTile(
///   leading: CircleAvatar(child: Text('A')),
///   title: 'Account',
///   onTap: openAccount,
/// );
/// ```
class OptionEntryTile extends StatelessWidget {
  /// Creates an [OptionEntryTile] with a custom leading widget.
  const OptionEntryTile({
    super.key,
    required leading,
    required this.title,
    this.description,
    this.onTap,
    this.actionIcon = OptionEntryTileActionIcon.navigateNext,
    this.customActionIcon,
  }) : _leading = leading,
       _icon = null,
       _svgIconAsset = null;

  /// Creates an [OptionEntryTile] with a built-in [Icon] as the leading widget.
  const OptionEntryTile.icon({
    super.key,
    IconData icon = Icons.adjust_outlined,
    required this.title,
    this.description,
    this.onTap,
    this.actionIcon = OptionEntryTileActionIcon.navigateNext,
    this.customActionIcon,
  }) : _leading = null,
       _icon = icon,
       _svgIconAsset = null;

  /// Creates an [OptionEntryTile] with an SVG asset as the leading widget.
  const OptionEntryTile.svg({
    super.key,
    required String svgIconAsset,
    required this.title,
    this.description,
    this.onTap,
    this.actionIcon = OptionEntryTileActionIcon.navigateNext,
    this.customActionIcon,
  }) : _leading = null,
       _icon = null,
       _svgIconAsset = svgIconAsset;

  /// Custom leading widget shown at the start of the row.
  final Widget? _leading;

  /// Leading icon shown at the start of the row.
  final IconData? _icon;

  /// Leading SVG icon asset path shown at the start of the row.
  final String? _svgIconAsset;

  /// Primary label shown in a prominent text style.
  final String title;

  /// Optional secondary text shown below [title].
  final String? description;

  /// Called when the tile is tapped.
  ///
  /// If null, the tile is rendered in a disabled (non-interactive) state.
  final VoidCallback? onTap;

  /// Built-in trailing icon selection used when [customActionIcon] is null.
  final OptionEntryTileActionIcon actionIcon;

  /// Custom trailing icon widget.
  ///
  /// When provided, this overrides [actionIcon].
  final Icon? customActionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(14);

    return Material(
      color: colorScheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                Center(
                  child: _buildLeading(colorScheme),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (description != null) ...[
                        Text(
                          description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                customActionIcon ??
                    Icon(
                      actionIcon == OptionEntryTileActionIcon.navigateNext
                          ? Icons.navigate_next
                          : Icons.exit_to_app,
                      color: colorScheme.outlineVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(ColorScheme colorScheme) {
    if (_leading != null) return _leading;

    if (_svgIconAsset != null) {
      return SizedBox.square(
        dimension: 24,
        child: SvgPicture.asset(
          _svgIconAsset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
        ),
      );
    }

    return Icon(_icon, color: colorScheme.primary);
  }
}

@Preview(
  name: 'OptionEntryTile - Profile Options Block',
  group: 'OptionEntryTile',
  size: Size(420, 600),
)
Widget optionEntryTileProfileOptionsPreview() {
  return WidgetPreviewFrame(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionEntryTile.icon(
            icon: Icons.image,
            title: t.profile.options.changeAvatar,
            onTap: () {},
          ),
          OptionEntryTile.icon(
            icon: Icons.logout,
            title: t.profile.options.logout,
            onTap: () {},
          ),
          OptionEntryTile.svg(
            svgIconAsset: 'assets/npc_logo.svg',
            title: t.profile.options.npcClub,
            actionIcon: OptionEntryTileActionIcon.exitToApp,
            onTap: () {},
          ),
          OptionEntryTile.icon(
            title: t.general.unknown,
            description:
                'Example tile with a description, using the default icon.',
            onTap: () {},
          ),
          OptionEntryTile(
            title: t.general.unknown,
            description: previewPlaceholder,
            leading: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue,
            ),
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}
