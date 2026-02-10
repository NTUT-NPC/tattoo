import 'package:flutter/material.dart';

class TableTab extends StatelessWidget {
  const TableTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text('課表'))),
    );
  }
}
