import 'package:flutter/widgets.dart';

class PositionView extends StatelessWidget {
  const PositionView({required this.position, super.key});

  final double position;

  @override
  Widget build(BuildContext context) {
    return Container(
      // ignore: prefer_const_constructors
      margin: EdgeInsets.fromLTRB(0, 0, 0, 8.0),
      child: Text('Position: ${position.toStringAsFixed(3)}'),
    );
  }
}
