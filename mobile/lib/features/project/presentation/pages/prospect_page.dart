import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/presentation/controllers/prospect_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/empty_state.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/load_error.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/skeleton_list.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class ProspectPage extends GetView<ProspectController> {
  const ProspectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      title: 'Prospek',
      body: Obx(() {
        if (c.loading.value && c.projects.isEmpty) return const SkeletonList();
        final err = c.error.value;
        if (err != null) return LoadError(err, c.load);

        final groups = c.statusGroups;
        final list = c.visible;
        final sel = c.selected.value;

        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              FadeSlideIn(
                child: AppCard(
                  accent: AppColors.primary,
                  child: Row(children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Total project', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        Text('${c.projects.length}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              if (c.projects.isEmpty)
                const SizedBox(
                  height: 360,
                  child: EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'Belum ada prospek',
                    subtitle: 'Project atau prospek yang ditugaskan kepada Anda akan tampil di sini.',
                  ),
                )
              else ...[
                SizedBox(
                  height: 40,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _FilterPill(label: 'Semua ${c.projects.length}', selected: sel == null, onTap: () => c.select(null)),
                    for (final g in groups) ...[
                      const SizedBox(width: 8),
                      _FilterPill(label: '${g.nama} ${g.count}', selected: sel == g.nama, onTap: () => c.select(g.nama)),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                for (final (i, p) in list.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProjectCard(p: p, c: c),
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.p, required this.c});
  final Project p;
  final ProspectController c;

  @override
  Widget build(BuildContext context) {
    final color = c.statusColor(p);
    final label = c.statusOf(p);
    final nilai = formatRupiah(p.nilaiProyek);
    final closing = p.estimasiClosing;

    return AppCard(
      accent: color ?? AppColors.infoFg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(p.namaProject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 8),
          color == null ? StatusChip(label) : StatusChip(label, fg: color, bg: color.withValues(alpha: 0.16)),
        ]),
        const SizedBox(height: 10),
        MetaRow(Icons.business_outlined, c.customerName(p.customerId)),
        if (nilai != null) ...[
          const SizedBox(height: 4),
          MetaRow(Icons.payments_outlined, nilai),
        ],
        if (closing != null) ...[
          const SizedBox(height: 4),
          MetaRow(Icons.event_available_outlined, 'Estimasi closing ${formatDate(closing)}'),
        ],
        if ((p.deskripsi ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            p.deskripsi!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ]),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onPrimary : AppColors.muted,
              ),
            ),
          ),
        ),
      );
}