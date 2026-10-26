import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/load_error.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/progress_row.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/skeleton_list.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class LkhPage extends GetView<LkhController> {
  const LkhPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      title: 'LKH',
      body: Obx(() {
        if (c.loading.value && c.rkh.isEmpty && c.lkh.isEmpty) return const SkeletonList();
        final err = c.error.value;
        if (err != null) return LoadError(err, c.load);
        final pending = c.pending;
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              FadeSlideIn(child: AppCard(child: ProgressRow('LKH terisi', c.rkh.length - pending.length, c.rkh.length))),
              const SizedBox(height: 20),
              const SectionTitle('Perlu LKH'),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text('Semua RKH sudah punya LKH.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final (i, r) in pending.indexed)
                FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      accent: AppColors.warningFg,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.judulKegiatan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        MetaRow(Icons.business_outlined, c.customerName(r.customerId)),
                        const SizedBox(height: 4),
                        MetaRow(Icons.event_outlined, formatDate(r.tanggalPelaksanaan)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => c.openForm(r),
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Tulis LKH'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const SectionTitle('Riwayat LKH'),
              if (c.lkh.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Belum ada LKH.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final (i, l) in c.lkh.indexed)
                FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => c.openDetail(l),
                      accent: l.isDone ? AppColors.successFg : AppColors.warningFg,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(formatDate(l.tanggalKunjungan), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                          l.isDone ? const StatusChip.success('DONE') : const StatusChip.warning('BELUM'),
                        ]),
                        const SizedBox(height: 8),
                        Text(l.hasilKunjungan, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        if (l.namaPic.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          MetaRow(Icons.person_outline, l.nomorPic.isEmpty ? l.namaPic : '${l.namaPic} · ${l.nomorPic}'),
                        ],
                        if (l.latitude != null && l.longitude != null) ...[
                          const SizedBox(height: 8),
                          MetaRow(Icons.location_on_outlined, '${l.latitude!.toStringAsFixed(4)}, ${l.longitude!.toStringAsFixed(4)}'),
                        ],
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}