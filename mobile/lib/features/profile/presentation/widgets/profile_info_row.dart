import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow(this.icon, this.label, this.value, {super.key});
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(width: 12),
        Expanded(child: Text(value ?? '-', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);
}