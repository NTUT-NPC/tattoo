import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.scores)),
      body: Center(child: Text(t.nav.scores)),
    );
  }
}
