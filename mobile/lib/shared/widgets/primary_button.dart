import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Tombol utama bergradasi biru dengan glow. `loading` menampilkan spinner.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: radius,
              boxShadow: const [BoxShadow(color: AppColors.glow, blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: enabled ? onPressed : null,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                          )
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            if (icon != null) ...[
                              Icon(icon, size: 20, color: AppColors.onPrimary),
                              const SizedBox(width: 8),
                            ],
                            Text(label,
                                style: const TextStyle(
                                    color: AppColors.onPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                          ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}