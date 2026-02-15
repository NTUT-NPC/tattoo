import 'package:flutter/material.dart';

class ClearNotice extends StatelessWidget {
  const ClearNotice({
    super.key,
    this.text = '本資料僅供參考',
    this.icon = const Icon(Icons.info_outline, size: 16),
    this.color,
  });

  final String text;
  final Widget icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          IconTheme(
            data: IconThemeData(color: color),
            child: icon,
          ),
          Flexible(
            child: Text(
              text,
              style: color == null ? null : TextStyle(color: color),
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
