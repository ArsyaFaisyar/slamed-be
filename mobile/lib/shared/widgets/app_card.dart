import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Warna garis aksen di tepi kiri (mis. status).
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final content = accent == null
        ? Padding(padding: padding, child: child)
        : IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 4, color: accent),
              Expanded(child: Padding(padding: padding, child: child)),
            ]),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: radius,
            border: Border.all(color: AppColors.divider),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRRect(borderRadius: radius, child: content),
          ),
        ),
      ),
    );
  }
}