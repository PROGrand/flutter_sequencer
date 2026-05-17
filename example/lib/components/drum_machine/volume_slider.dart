import 'package:flutter/material.dart';

class VolumeSlider extends StatelessWidget {
  const VolumeSlider({required this.value, required this.onChange, super.key});

  final double value;
  final Function(double) onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Volume:'),
        Slider(value: value, onChanged: onChange),
      ],
    );
  }
}
