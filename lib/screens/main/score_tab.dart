import 'package:flutter/material.dart';

class ScoreTab extends StatelessWidget {
  const ScoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('成績'))),
    );
  }
}
