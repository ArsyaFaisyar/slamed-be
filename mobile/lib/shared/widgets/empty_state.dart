import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.glow),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ]),
        ),
      );
}