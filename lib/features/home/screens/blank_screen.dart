import 'package:flutter/material.dart';

class BlankScreen extends StatelessWidget {
  const BlankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Feature'),
      ),
      body: const Center(
        child: Text('Coming Soon...'),
      ),
    );
  }
}
