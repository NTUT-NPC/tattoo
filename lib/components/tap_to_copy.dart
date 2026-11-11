import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';

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
                  SnackBar(content: Text(t.general.copiedToClipboard.spaced)),
                );
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      t.general.copyToClipboardFailed.spaced,
                    ),
                  ),
                );
            }
          },
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
