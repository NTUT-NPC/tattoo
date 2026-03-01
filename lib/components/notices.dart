import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';

/// Preset styles used by [BackgroundNotice].
enum NoticeType { warning, error, info }

/// A lightweight inline notice with optional icon and custom text style.
///
/// This widget is intended for subtle informational messages that do not
/// require a bordered background.
///
/// See also: `OptionEntryTile` in `tattoo/lib/components/option_entry_tile.dart`.
class ClearNotice extends StatelessWidget {
  /// Creates a plain text notice row.
  ClearNotice({
    super.key,
    String? text,
    this.icon = const Icon(Icons.info_outline, size: 16),
    this.color,
    this.textStyle,
  }) : text = text ?? t.general.dataDisclaimer;

  /// Message text shown in the notice.
  final String text;

  /// Leading icon displayed before [text].
  final Widget icon;

  /// Foreground color for text and icon theme.
  ///
  /// The icon color is only applied when [icon] is an [Icon] (or any widget
  /// that reads [IconTheme]). If [icon] is another custom widget, this color
  /// does not automatically change that widget's appearance.
  ///
  /// Defaults to `Colors.grey[600]` when omitted.
  final Color? color;

  /// Optional text style override for [text].
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          IconTheme(
            data: IconThemeData(color: resolvedColor),
            child: icon,
          ),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style:
                  textStyle?.copyWith(color: resolvedColor) ??
                  TextStyle(color: resolvedColor),
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}

/// A centered vertical notice with an optional top icon and rich text body.
///
/// This widget is useful for empty states or explanatory hints where text may
/// need mixed styles via [InlineSpan].
///
/// Usage:
/// ```dart
/// ClearNoticeVertical(
///   text: const TextSpan(
///     text: '尚無資料，請稍後再試',
///   ),
///   color: Colors.grey,
/// )
/// ```
///
/// Rich text example:
/// ```dart
/// ClearNoticeVertical(
///   icon: const Icon(Icons.school_outlined),
///   text: TextSpan(
///     children: [
///       const TextSpan(text: '請先完成 '),
///       TextSpan(
///         text: '課程加選',
///         style: TextStyle(
///           color: Theme.of(context).colorScheme.primary,
///           fontWeight: FontWeight.w700,
///         ),
///       ),
///       const TextSpan(text: ' 後再查看。'),
///     ],
///   ),
/// )
/// ```
class ClearNoticeVertical extends StatelessWidget {
  /// Rich text content displayed under the icon.
  final InlineSpan text;

  /// Optional icon shown above [text].
  ///
  /// Falls back to a grey `Icons.info_outline` icon sized by screen height.
  final Widget? icon;

  /// Foreground color for text and icon theme.
  ///
  /// The icon color is only applied when [icon] is an [Icon] (or any widget
  /// that reads [IconTheme]). If [icon] is another custom widget, this color
  /// does not automatically change that widget's appearance.
  ///
  /// Defaults to `Colors.grey[600]` when omitted.
  final Color? color;

  /// Creates a vertical notice with rich-text support.
  const ClearNoticeVertical({
    super.key,
    required this.text,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? Colors.grey[600];

    return Column(
      spacing: 8.0,
      children: [
        SizedBox(
          child: IconTheme(
            data: IconThemeData(
              color: resolvedColor,
              size: 24,
            ),
            child: icon ?? const Icon(Icons.info_outline),
          ),
        ),
        Text.rich(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.6,
            color: resolvedColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A bordered notice chip with a tinted background and semantic presets.
///
/// Usage:
/// ```dart
/// Column(
///   children: const [
///     OptionEntryTile(
///       icon: Icons.info_outline,
///       title: 'About',
///     ),
///     BackgroundNotice(
///       text: 'Important notice',
///       noticeType: NoticeType.warning,
///     ),
///   ],
/// )
/// ```
///
/// See also: `OptionEntryTile` in `tattoo/lib/components/option_entry_tile.dart`.
class BackgroundNotice extends StatelessWidget {
  /// Creates a bordered notice with background tint.
  const BackgroundNotice({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.textStyle,
    this.noticeType = NoticeType.info,
  });

  /// Message text shown in the notice.
  final String text;

  /// Optional leading icon. Falls back to a preset icon by [noticeType].
  final Widget? icon;

  /// Optional accent color. Falls back to a preset color by [noticeType].
  ///
  /// The icon color is only applied when [icon] is an [Icon] (or any widget
  /// that reads [IconTheme]). If [icon] is another custom widget, this color
  /// does not automatically change that widget's appearance.
  final Color? color;

  /// Optional text style override for [text].
  final TextStyle? textStyle;

  /// Preset palette/icon style when [color] or [icon] is not provided.
  final NoticeType noticeType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? _presetColor(context);
    final resolvedIcon = icon ?? Icon(_presetIcon(), size: 24);
    final resolvedTextStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 12))
            .merge(textStyle)
            .copyWith(color: resolvedColor, fontWeight: FontWeight.w800);
    final borderRadius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: resolvedColor, width: 1.6),
          color: resolvedColor.withValues(alpha: 0.08),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              IconTheme(
                data: IconThemeData(color: resolvedColor, size: 16),
                child: resolvedIcon,
              ),
              Expanded(
                child: Text(
                  text,
                  style: resolvedTextStyle,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _presetColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (noticeType) {
      case NoticeType.warning:
        return colorScheme.tertiary;
      case NoticeType.error:
        return colorScheme.error;
      case NoticeType.info:
        return colorScheme.primary;
    }
  }

  IconData _presetIcon() {
    switch (noticeType) {
      case NoticeType.warning:
        return Icons.warning_amber_rounded;
      case NoticeType.error:
        return Icons.error_outline;
      case NoticeType.info:
        return Icons.info_outline;
    }
  }
}
