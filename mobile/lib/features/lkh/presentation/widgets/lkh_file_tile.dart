import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';

/// Kartu lampiran dokumen yang sudah dipilih: nama, ukuran, ganti, hapus.
class LkhFileTile extends StatelessWidget {
  const LkhFileTile({super.key, required this.file, required this.bytes, required this.onReplace, required this.onRemove});
  final PlatformFile file;
  final int? bytes;
  final VoidCallback onReplace, onRemove;

  String get _size {
    final b = bytes;
    if (b == null) return '';
    final kb = b / 1024;
    return kb < 1024 ? '${kb.toStringAsFixed(0)} KB' : '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(children: [
          const Icon(Icons.description_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (_size.isNotEmpty) Text(_size, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          IconButton(onPressed: onReplace, tooltip: 'Ganti lampiran', icon: const Icon(Icons.refresh_rounded, size: 20)),
          IconButton(onPressed: onRemove, tooltip: 'Hapus lampiran', icon: const Icon(Icons.close_rounded, size: 20)),
        ]),
      );
}