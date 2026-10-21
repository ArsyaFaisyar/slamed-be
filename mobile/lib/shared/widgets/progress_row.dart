import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class ProgressRow extends StatelessWidget {
  const ProgressRow(this.label, this.done, this.total, {super.key});
  final String label;
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$label $done dari $total',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('$done/$total · ${(p * 100).round()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: p),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(height: 10, color: AppColors.divider),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: 10, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}