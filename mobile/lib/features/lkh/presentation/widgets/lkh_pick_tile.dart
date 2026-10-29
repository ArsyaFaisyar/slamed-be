import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

/// Kotak unggah: kosong = ajakan ketuk, terisi foto = pratinjau gambar.
class LkhPickTile extends StatelessWidget {
  const LkhPickTile({super.key, required this.icon, required this.label, required this.hint, required this.file, required this.onTap});
  final IconData icon;
  final String label, hint;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    if (file == null) {
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(color: AppColors.glow, borderRadius: radius, border: Border.all(color: AppColors.primaryBorder)),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox(
              height: 92,
              width: double.infinity,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Stack(children: [
        Image.file(File(file!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            color: const Color(0xB30B0E24),
            child: Row(children: [
              const Expanded(child: Text('Foto siap dikirim', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))),
              IconButton(onPressed: onTap, tooltip: 'Ambil ulang $label', icon: const Icon(Icons.refresh_rounded, size: 20)),
            ]),
          ),
        ),
      ]),
    );
  }
}