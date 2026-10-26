import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/core/utils/date_range.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/empty_state.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/load_error.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/progress_row.dart';
import 'package:slamed_app/shared/widgets/search_filter_bar.dart';
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

        final f = c.filter.value;
        final showPending = f == LkhFilter.semua || f == LkhFilter.perluLkh;
        final showHistory = f != LkhFilter.perluLkh;
        final pending = c.pendingVisible;
        final history = c.historyVisible;
        final filtering = c.filtering;
        final range = c.range.value;
        final totalPending = c.pending.length;

        return Column(children: [
          SearchFilterBar<LkhFilter>(
            hint: 'Cari judul, customer, PIC, atau hasil',
            query: c.query.value,
            onQuery: (v) => c.query.value = v,
            options: [
              FilterOption(LkhFilter.semua, 'Semua', count: c.countOf(LkhFilter.semua)),
              FilterOption(LkhFilter.perluLkh, 'Perlu LKH', count: c.countOf(LkhFilter.perluLkh)),
              FilterOption(LkhFilter.belum, 'BELUM', count: c.countOf(LkhFilter.belum)),
              FilterOption(LkhFilter.done, 'DONE', count: c.countOf(LkhFilter.done)),
            ],
            selected: f,
            onSelected: (v) => c.filter.value = v,
            range: range,
            onPickRange: () async {
              final r = await pickDateRange(context, range);
              if (r != null) c.range.value = r;
            },
            onClearRange: () => c.range.value = null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  FadeSlideIn(child: AppCard(child: ProgressRow('LKH terisi', c.rkh.length - totalPending, c.rkh.length))),
                  const SizedBox(height: 20),
                  if (filtering && pending.isEmpty && history.isEmpty) ...[
                    const SizedBox(
                      height: 320,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ada hasil',
                        subtitle: 'Ubah kata kunci atau filter yang dipakai.',
                      ),
                    ),
                    Center(child: TextButton(onPressed: c.resetFilters, child: const Text('Reset filter'))),
                  ] else ...[
                    if (showPending && (pending.isNotEmpty || !filtering)) ...[
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
                    ],
                    if (showHistory && (history.isNotEmpty || !filtering)) ...[
                      const SectionTitle('Riwayat LKH'),
                      if (history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('Belum ada LKH.', style: TextStyle(color: AppColors.muted)),
                        ),
                      for (final (i, l) in history.indexed)
                        FadeSlideIn(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () => c.openDetail(l),
                              accent: l.isDone ? AppColors.successFg : AppColors.warningFg,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(formatDate(l.tanggalKunjungan), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ),
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
                  ],
                ],
              ),
            ),
          ),
        ]);
      }),
    );
  }
}