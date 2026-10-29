import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';

class LkhDokumentasiSection extends StatelessWidget {
  const LkhDokumentasiSection({super.key, required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) => Obx(() {
        final working = c.busy.value || c.capturing.value;
        final isDone = c.lkh.value.isDone;
        final bytes = c.fotoBytes.value;
        final lampiran = c.lampiran;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (working) const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(bytes, height: 220, width: double.infinity, fit: BoxFit.cover, gaplessPlayback: true),
            )
          else if (c.loadingFiles.value)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator())
          else
            const AppCard(
              child: Row(children: [
                Icon(Icons.no_photography_outlined, color: AppColors.muted),
                SizedBox(width: 12),
                Expanded(child: Text('Belum ada foto dokumentasi.', style: TextStyle(fontSize: 13))),
              ]),
            ),
          if (!isDone && c.hasFoto && c.canEdit) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: working ? null : c.changePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Ambil ulang foto'),
            ),
          ],
          const SizedBox(height: 12),
          if (lampiran != null)
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.description_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lampiran.namaFile, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(lampiran.tipeFile, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ]),
                ),
              ]),
            ),
          if (!isDone && c.canEdit) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: working ? null : c.changeLampiran,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(lampiran == null ? 'Unggah lampiran' : 'Ganti lampiran'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Lampiran: PDF, Word, atau Excel, maks. 5 MB. Membuka dokumen belum tersedia di app.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ]);
      });
}