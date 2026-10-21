import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Satu baris info dengan ikon kecil (customer, tanggal, tipe, dst.).
class MetaRow extends StatelessWidget {
  const MetaRow(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: AppColors.muted)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]);
}