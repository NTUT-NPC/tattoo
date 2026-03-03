import 'package:flutter/material.dart';

class WidgetPreviewFrame extends StatelessWidget {
  const WidgetPreviewFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
