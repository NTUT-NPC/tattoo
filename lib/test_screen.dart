import 'package:flutter/material.dart';
import 'package:tattoo/services/portal_service.dart';

class TestPage extends StatelessWidget {
  const TestPage({
    super.key,
    required this.username,
    required this.user,
  });

  final String username;
  final UserDTO user;

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
