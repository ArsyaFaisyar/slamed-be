import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.muted),
        ),
      );
}