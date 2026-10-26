import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_detail_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/edit_bar.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/info_banner.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class RkhDetailPage extends GetView<RkhDetailController> {
  const RkhDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final editing = c.editing.value;
      return AppScaffold(
        title: editing ? 'Ubah RKH' : 'Detail RKH',
        actions: [
          if (!editing && c.canModify) ...[
            IconButton(onPressed: c.busy.value ? null : c.startEdit, tooltip: 'Ubah', icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: c.busy.value ? null : c.remove, tooltip: 'Hapus', icon: const Icon(Icons.delete_outline_rounded)),
          ],
        ],
        bottomBar: editing ? EditBar(busy: c.busy.value, onCancel: c.cancelEdit, onSave: c.save) : null,
        body: editing ? _EditView(c: c) : _DetailView(c: c),
      );
    });
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.c});
  final RkhDetailController c;

  @override
  Widget build(BuildContext context) => Obx(() {
        final r = c.rkh.value;
        final biaya = formatRupiah(r.estimasiBiayaHarian);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              accent: c.hasLkh ? AppColors.successFg : AppColors.warningFg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(r.judulKegiatan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                  const SizedBox(width: 8),
                  StatusChip(r.status),
                ]),
                const SizedBox(height: 12),
                MetaRow(Icons.business_outlined, c.customerName),
                const SizedBox(height: 4),
                MetaRow(Icons.event_note_outlined, 'Tanggal rencana ${formatDate(r.tanggalRencana)}'),
                const SizedBox(height: 4),
                MetaRow(Icons.event_outlined, 'Pelaksanaan ${formatDate(r.tanggalPelaksanaan)}'),
                const SizedBox(height: 4),
                MetaRow(Icons.category_outlined, r.tipeAktivitas),
                if (biaya != null) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.payments_outlined, 'Estimasi biaya harian $biaya'),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: c.hasLkh ? const StatusChip.success('LKH terisi') : const StatusChip.warning('Belum LKH'),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Rencana kegiatan'),
            AppCard(child: Text(r.rencanaKegiatan, style: const TextStyle(fontSize: 14, height: 1.4))),
            if (!c.canModify) ...[
              const SizedBox(height: 16),
              const InfoBanner('RKH ini sudah punya LKH, jadi tidak dapat diubah atau dihapus.'),
            ],
          ],
        );
      });
}

class _EditView extends StatelessWidget {
  const _EditView({required this.c});
  final RkhDetailController c;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionTitle('Ubah kegiatan'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: c.judul,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Judul kegiatan', prefixIcon: Icon(Icons.title_rounded)),
            ),
            gap,
            TextField(
              controller: c.rencana,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Rencana kegiatan', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            gap,
            TextField(
              controller: c.tipe,
              decoration: const InputDecoration(labelText: 'Tipe aktivitas', prefixIcon: Icon(Icons.category_outlined)),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in AppConstants.tipeAktivitasSaran) ActionChip(label: Text(t), onPressed: () => c.tipe.text = t),
            ]),
            gap,
            Obx(() => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => c.pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal pelaksanaan', prefixIcon: Icon(Icons.event_outlined)),
                    child: Text(formatDate(c.tanggal.value)),
                  ),
                )),
            gap,
            TextField(
              controller: c.biaya,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Estimasi biaya harian (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
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