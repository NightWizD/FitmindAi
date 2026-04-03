import 'package:flutter/material.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness')),
      body: const Center(child: Text('Fitness Screen')),
    );
  }
}
