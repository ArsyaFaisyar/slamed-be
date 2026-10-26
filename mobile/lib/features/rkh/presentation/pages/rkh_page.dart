import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/core/utils/date_range.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/empty_state.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/load_error.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/progress_row.dart';
import 'package:slamed_app/shared/widgets/search_filter_bar.dart';
import 'package:slamed_app/shared/widgets/skeleton_list.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class RkhPage extends GetView<RkhController> {
  const RkhPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      title: 'RKH',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: c.openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah RKH'),
      ),
      body: Obx(() {
        if (c.loading.value && c.rkh.isEmpty) return const SkeletonList();
        final err = c.error.value;
        if (err != null) return LoadError(err, c.load);

        final list = c.visible;
        final range = c.range.value;
        return Column(children: [
          SearchFilterBar<RkhFilter>(
            hint: 'Cari judul, customer, atau tipe aktivitas',
            query: c.query.value,
            onQuery: (v) => c.query.value = v,
            options: [
              FilterOption(RkhFilter.semua, 'Semua', count: c.countOf(RkhFilter.semua)),
              FilterOption(RkhFilter.belumLkh, 'Belum LKH', count: c.countOf(RkhFilter.belumLkh)),
              FilterOption(RkhFilter.lkhTerisi, 'LKH terisi', count: c.countOf(RkhFilter.lkhTerisi)),
            ],
            selected: c.filter.value,
            onSelected: (f) => c.filter.value = f,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  FadeSlideIn(child: AppCard(child: ProgressRow('RKH terealisasi (sudah ada LKH)', c.doneCount, c.rkh.length))),
                  const SizedBox(height: 16),
                  if (c.rkh.isEmpty)
                    const SizedBox(
                      height: 360,
                      child: EmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'Belum ada RKH',
                        subtitle: 'Tekan "Tambah RKH" untuk merencanakan kunjungan.',
                      ),
                    )
                  else if (list.isEmpty) ...[
                    const SizedBox(
                      height: 320,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ada hasil',
                        subtitle: 'Ubah kata kunci atau filter yang dipakai.',
                      ),
                    ),
                    Center(child: TextButton(onPressed: c.resetFilters, child: const Text('Reset filter'))),
                  ],
                  for (final (i, r) in list.indexed)
                    FadeSlideIn(
                      index: i + 1,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => c.openDetail(r),
                          accent: c.withLkh.contains(r.id) ? AppColors.successFg : AppColors.warningFg,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(
                                child: Text(r.judulKegiatan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              ),
                              const SizedBox(width: 8),
                              StatusChip(r.status),
                            ]),
                            const SizedBox(height: 10),
                            MetaRow(Icons.business_outlined, c.customerName(r.customerId)),
                            const SizedBox(height: 4),
                            MetaRow(Icons.event_outlined, formatDate(r.tanggalPelaksanaan)),
                            const SizedBox(height: 4),
                            MetaRow(Icons.category_outlined, r.tipeAktivitas),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: c.withLkh.contains(r.id)
                                  ? const StatusChip.success('LKH terisi')
                                  : const StatusChip.warning('Belum LKH'),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]);
      }),
    );
  }
}