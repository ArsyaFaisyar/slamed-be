import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/edit_bar.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/info_banner.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class LkhDetailPage extends GetView<LkhDetailController> {
  const LkhDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final editing = c.editing.value;
      final isDone = c.lkh.value.isDone;
      final working = c.busy.value || c.capturing.value;
      return AppScaffold(
        title: editing ? 'Ubah LKH' : 'Detail LKH',
        actions: [
          if (!editing) ...[
            IconButton(onPressed: working ? null : c.startEdit, tooltip: 'Ubah', icon: const Icon(Icons.edit_outlined)),
            // Hapus hanya untuk LKH yang belum selesai.
            if (!isDone)
              IconButton(onPressed: working ? null : c.remove, tooltip: 'Hapus', icon: const Icon(Icons.delete_outline_rounded)),
          ],
        ],
        bottomBar: editing
            ? EditBar(busy: c.busy.value, onCancel: c.cancelEdit, onSave: c.save)
            : isDone
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: PrimaryButton(
                        label: 'Lengkapi foto',
                        icon: Icons.photo_camera_outlined,
                        loading: working,
                        onPressed: c.changePhoto,
                      ),
                    ),
                  ),
        body: editing ? _EditView(c: c) : _DetailView(c: c),
      );
    });
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) => Obx(() {
        final l = c.lkh.value;
        final lokasi = (l.latitude != null && l.longitude != null)
            ? '${l.latitude!.toStringAsFixed(5)}, ${l.longitude!.toStringAsFixed(5)}'
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              accent: l.isDone ? AppColors.successFg : AppColors.warningFg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(c.judulRkh, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                  const SizedBox(width: 8),
                  l.isDone ? const StatusChip.success('DONE') : const StatusChip.warning('BELUM'),
                ]),
                const SizedBox(height: 12),
                MetaRow(Icons.business_outlined, c.customerName),
                const SizedBox(height: 4),
                MetaRow(Icons.event_outlined, 'Kunjungan ${formatDate(l.tanggalKunjungan)}'),
                if (l.namaPic.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.person_outline, l.nomorPic.isEmpty ? l.namaPic : '${l.namaPic} · ${l.nomorPic}'),
                ],
                if (lokasi != null) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.location_on_outlined, lokasi),
                ],
              ]),
            ),
            if (!l.isDone) ...[
              const SizedBox(height: 16),
              const InfoBanner('Foto dokumentasi belum terkirim. Tekan "Lengkapi foto" untuk menyelesaikan LKH.'),
            ],
            const SizedBox(height: 20),
            const SectionTitle('Hasil kunjungan'),
            AppCard(child: Text(l.hasilKunjungan, style: const TextStyle(fontSize: 14, height: 1.4))),
            if ((l.tindakLanjut ?? '').isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionTitle('Tindak lanjut'),
              AppCard(child: Text(l.tindakLanjut!, style: const TextStyle(fontSize: 14, height: 1.4))),
            ],
            const SizedBox(height: 20),
            const SectionTitle('Dokumentasi'),
            _Dokumentasi(c: c),
          ],
        );
      });
}

class _Dokumentasi extends StatelessWidget {
  const _Dokumentasi({required this.c});
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
          if (isDone) ...[
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
        ]);
      });
}

class _EditView extends StatelessWidget {
  const _EditView({required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionTitle('Hasil'),
        AppCard(
          child: Column(children: [
            TextField(
              controller: c.hasil,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Hasil kunjungan', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            gap,
            TextField(
              controller: c.tindak,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Tindak lanjut (opsional)', prefixIcon: Icon(Icons.redo_rounded)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Kontak yang ditemui'),
        AppCard(
          child: Column(children: [
            TextField(
              controller: c.namaPic,
              maxLength: 150,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama PIC', prefixIcon: Icon(Icons.person_outline), counterText: ''),
            ),
            gap,
            TextField(
              controller: c.nomorPic,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor PIC', prefixIcon: Icon(Icons.phone_outlined), counterText: ''),
            ),
          ]),
        ),
        Obx(() {
          final e = c.error.value;
          return e == null ? const SizedBox.shrink() : ErrorBox(e);
        }),
      ],
    );
  }
}