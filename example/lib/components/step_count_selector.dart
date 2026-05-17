import 'package:flutter/material.dart';

class StepCountSelector extends StatelessWidget {
  const StepCountSelector({required this.stepCount, required this.onChange, super.key});

  final int stepCount;
  final Function(int) onChange;

  void handleLess() {
    onChange(stepCount - 1);
  }

  void handleMore() {
    onChange(stepCount + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Steps'),
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: handleLess),
        Text(stepCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.arrow_forward), onPressed: handleMore),
      ],
    );
  }
}
