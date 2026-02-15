import 'package:flutter/material.dart';

enum NoticeType { warning, error, info }

class ClearNotice extends StatelessWidget {
  const ClearNotice({
    super.key,
    this.text = '本資料僅供參考',
    this.icon = const Icon(Icons.info_outline, size: 16),
    this.color,
    this.textStyle,
  });

  final String text;
  final Widget icon;
  final Color? color;
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

class BackgorundedNotice extends StatelessWidget {
  const BackgorundedNotice({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.textStyle,
    this.noticeType = NoticeType.info,
  });

  final String text;
  final Widget? icon;
  final Color? color;
  final TextStyle? textStyle;
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
            mainAxisSize: MainAxisSize.min,
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
