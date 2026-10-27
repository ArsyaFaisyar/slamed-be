import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/color_utils.dart';
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
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
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
          const SectionTitle('Status project'),
          AppCard(
            child: Obx(() {
              if (c.loadingStatus.value) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator());
              }
              if (c.statusError.value != null || c.statuses.isEmpty) {
                return const Row(children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status project tidak dapat dimuat, jadi tidak diubah dari form ini.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                ]);
              }
              final nama = c.projectNama.value;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (nama != null) ...[
                  MetaRow(Icons.folder_open_outlined, nama),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  initialValue: c.statusId.value,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  decoration: const InputDecoration(
                    labelText: 'Status project',
                    prefixIcon: Icon(Icons.flag_outlined),
                    helperText: 'Ubah jika status prospek berubah setelah kunjungan. Status tidak dapat dimundurkan.',
                    helperMaxLines: 2,
                  ),
                  items: [
                    for (final s in c.statuses)
                      DropdownMenuItem(
                        value: s.id,
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: parseHexColor(s.warna) ?? AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.nama, overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                  ],
                  onChanged: (v) => c.statusId.value = v,
                ),
              ]);
            }),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Kontak yang ditemui'),
          AppCard(
            child: Column(children: [
              TextField(
                controller: c.namaPic,
                maxLength: 150,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama PIC',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
              ),
              gap,
              TextField(
                controller: c.nomorPic,
                maxLength: 30,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor PIC',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Lokasi'),
          AppCard(
            child: Obx(() {
              final p = c.fotoPos.value;
              return Row(children: [
                Icon(
                  p == null ? Icons.location_searching_rounded : Icons.my_location_rounded,
                  color: p == null ? AppColors.muted : AppColors.successFg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p == null
                        ? 'Lokasi dicatat otomatis saat foto dokumentasi diambil.'
                        : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)} (±${p.accuracy.round()} m)\nSesuai lokasi pengambilan foto',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]);
            }),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Dokumentasi'),
          Obx(() => _PickTile(
                icon: Icons.photo_camera_outlined,
                label: 'Foto dokumentasi',
                hint: 'Wajib · langsung dari kamera · maks. 2 MB',
                file: c.foto.value,
                onTap: c.takePhoto,
              )),
          Obx(() => c.capturing.value
              ? const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator())
              : const SizedBox.shrink()),
          gap,
          Obx(() {
            final f = c.lampiran.value;
            final bytes = c.lampiranBytes.value;
            if (f == null) {
              return _PickTile(
                icon: Icons.attach_file_rounded,
                label: 'Lampiran dokumen',
                hint: 'Opsional · PDF, Word, Excel · maks. 5 MB',
                file: null,
                onTap: c.pickAttachment,
              );
            }
            return _FileTile(file: f, bytes: bytes, onReplace: c.pickAttachment, onRemove: c.clearAttachment);
          }),
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
        ],
      ),
    );
  }
}

/// Kotak unggah: kosong = ajakan ketuk, terisi foto = pratinjau gambar.
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

/// Kartu lampiran dokumen yang sudah dipilih: nama, ukuran, ganti, hapus.
class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.bytes, required this.onReplace, required this.onRemove});
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