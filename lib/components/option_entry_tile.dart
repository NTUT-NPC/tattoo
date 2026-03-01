import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
/// 1. A leading icon ([icon], [svgIconAsset], or [customLeading])
/// 2. A title ([title]) and optional description ([description])
/// 3. A trailing action icon, chosen from [actionIcon] or overridden by
///    [customActionIcon]
///
/// [customActionIcon] takes precedence over [actionIcon] when both are set.
///
/// Example:
/// ```dart
/// OptionEntryTile(
///   icon: Icons.person_outline_rounded,
///   title: 'Profile',
///   description: 'View and edit your profile',
///   onTap: () => context.push('/profile'),
/// );
///
/// OptionEntryTile(
///   svgIconAsset: 'assets/settings.svg',
///   title: 'Settings',
///   onTap: openSettings,
/// );
///
/// OptionEntryTile(
///   customLeading: CircleAvatar(child: Text('A')),
///   title: 'Account',
///   onTap: openAccount,
/// );
/// ```
class OptionEntryTile extends StatelessWidget {
  /// Creates an [OptionEntryTile].
  const OptionEntryTile({
    super.key,
    this.icon = Icons.adjust_outlined,
    this.svgIconAsset,
    this.customLeading,
    required this.title,
    this.description,
    this.onTap,
    this.actionIcon = OptionEntryTileActionIcon.navigateNext,
    this.customActionIcon,
  }) : assert(
         icon != null || svgIconAsset != null || customLeading != null,
         'Either icon, svgIconAsset, or customLeading must be provided.',
       );

  /// Leading icon shown at the start of the row.
  ///
  /// Defaults to [Icons.adjust_outlined] when not provided.
  final IconData? icon;

  /// Leading SVG icon asset path shown at the start of the row.
  ///
  /// When multiple leading options are provided, priority is:
  /// [customLeading] > [svgIconAsset] > [icon].
  final String? svgIconAsset;

  /// Custom leading widget shown at the start of the row.
  final Widget? customLeading;

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
                  child: customLeading ??
                      (svgIconAsset != null
                          ? SizedBox.square(
                              dimension: 24,
                              child: SvgPicture.asset(
                                svgIconAsset!,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                colorFilter: ColorFilter.mode(
                                  colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            )
                          : Icon(icon, color: colorScheme.primary)),
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
}
