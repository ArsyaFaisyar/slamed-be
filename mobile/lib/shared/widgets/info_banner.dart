import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Kotak informasi biru (mis. alasan sebuah data tidak bisa diubah).
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.infoFg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.infoFg))),
        ]),
      );
}