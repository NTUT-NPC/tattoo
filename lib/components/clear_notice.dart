import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          IconTheme(
            data: IconThemeData(color: color),
            child: icon,
          ),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: textStyle?.copyWith(color: color) ??
                  (color == null ? null : TextStyle(color: color)),
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
