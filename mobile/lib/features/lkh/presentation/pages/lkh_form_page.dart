import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_form_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';

class LkhFormPage extends GetView<LkhFormController> {
  const LkhFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    const gap = SizedBox(height: 14);
    return AppScaffold(
      title: 'Proses LKH',
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() => PrimaryButton(
                label: 'Kirim LKH',
                icon: Icons.send_rounded,
                loading: c.busy.value,
                onPressed: c.submit,
              )),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        const SectionTitle('Kegiatan'),
        AppCard(
          accent: AppColors.primary,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.rkh.judulKegiatan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            MetaRow(Icons.business_outlined, c.customerName),
            const SizedBox(height: 14),
            Obx(() => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => c.pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal kunjungan', prefixIcon: Icon(Icons.event_outlined)),
                    child: Text(formatDate(c.tanggal.value)),
                  ),
                )),
          ]),
        ),
        const SizedBox(height: 20),
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
        const SectionTitle('Status prospek'),
        Obx(() => Row(children: [
              for (final (i, s) in AppConstants.statusProspek.indexed) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _StatusPill(
                    label: s,
                    selected: c.status.value == s,
                    onTap: () => c.status.value = c.status.value == s ? null : s,
                  ),
                ),
              ],
            ])),
        const SizedBox(height: 20),
        const SectionTitle('Lokasi'),
        AppCard(
          child: Obx(() {
            final p = c.pos.value;
            return Row(children: [
              const Icon(Icons.my_location_rounded, color: AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p == null ? 'Belum diambil (opsional)' : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: c.locating.value ? null : () => c.locate(),
                child: c.locating.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(p == null ? 'Ambil lokasi' : 'Perbarui'),
              ),
            ]);
          }),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Dokumentasi'),
        Obx(() => _PickTile(
              icon: Icons.photo_camera_outlined,
              label: 'Foto dokumentasi',
              hint: 'Wajib · ketuk untuk membuka kamera',
              file: c.foto.value,
              onTap: c.takePhoto,
            )),
        gap,
        Obx(() => _PickTile(
              icon: Icons.attach_file_rounded,
              label: 'Lampiran',
              hint: 'Opsional · pilih dari galeri',
              file: c.lampiran.value,
              onTap: c.pickAttachment,
            )),
        Obx(() {
          final e = c.error.value;
          if (e == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline, size: 18, color: AppColors.dangerFg),
              const SizedBox(width: 8),
              Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: AppColors.dangerFg))),
            ]),
          );
        }),
      ]),
    );
  }
}

/// Pilihan status: DONE hijau, LOSE merah. Ketuk lagi untuk membatalkan pilihan.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final danger = label.toUpperCase() == 'LOSE';
    final fg = danger ? AppColors.dangerFg : AppColors.successFg;
    final bg = danger ? AppColors.dangerBg : AppColors.successBg;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: selected ? bg : AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? fg : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (selected) ...[Icon(Icons.check_rounded, size: 18, color: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? fg : AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

/// Kotak unggah: kosong = ajakan ketuk, terisi = pratinjau gambar.
class _PickTile extends StatelessWidget {
  const _PickTile({required this.icon, required this.label, required this.hint, required this.file, required this.onTap});
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
                Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Stack(children: [
        Image.file(File(file!.path), height: 160, width: double.infinity, fit: BoxFit.cover),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            color: const Color(0xB30B0E24),
            child: Row(children: [
              Expanded(child: Text(file!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
              IconButton(onPressed: onTap, tooltip: 'Ganti $label', icon: const Icon(Icons.refresh_rounded, size: 20)),
            ]),
          ),
        ),
      ]),
    );
  }
}