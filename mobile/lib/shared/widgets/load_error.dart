import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class LoadError extends StatelessWidget {
  const LoadError(this.message, this.onRetry, {super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.dangerBg),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.dangerFg),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ),
          ]),
        ),
      );
}