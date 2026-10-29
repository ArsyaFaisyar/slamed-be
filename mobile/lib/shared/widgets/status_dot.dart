import 'package:flutter/material.dart';
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 10});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}