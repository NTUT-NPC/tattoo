import 'package:flutter/material.dart';

const previewPlaceholder =
    'Preview placeholder text for demonstration purposes.';

class WidgetPreviewFrame extends StatelessWidget {
  const WidgetPreviewFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const .all(4.0),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
