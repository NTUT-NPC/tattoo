import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';

class TapToCopy extends StatelessWidget {
  const TapToCopy({
    super.key,
    required this.copyText,
    required this.child,
    this.enableHapticFeedback = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  });

  final String copyText;
  final Widget child;
  final bool enableHapticFeedback;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: .circular(8),
          ),
          onTap: () async {
            if (enableHapticFeedback) HapticFeedback.lightImpact();
            try {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(t.$wip('已複製到剪貼簿'))),
                );
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(t.$wip('複製到剪貼簿失敗'))),
                );
            }
          },
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
