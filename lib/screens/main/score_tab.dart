import 'package:flutter/material.dart';

class ScoreTab extends StatelessWidget {
  const ScoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成績')),
      body: const Center(child: Text('成績')),
    );
  }
}
