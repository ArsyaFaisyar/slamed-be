import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/customer/presentation/controllers/customer_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/empty_state.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/load_error.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/search_filter_bar.dart';
import 'package:slamed_app/shared/widgets/skeleton_list.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class CustomerPage extends GetView<CustomerController> {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      title: 'Customer',
      floatingActionButton: c.canCreate
          ? FloatingActionButton.extended(
              onPressed: c.openForm,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Ajukan customer'),
            )
          : null,
      body: Obx(() {
        if (c.loading.value && c.customers.isEmpty) return const SkeletonList();
        final err = c.error.value;
        if (err != null) return LoadError(err, c.load);

        final list = c.visible;
        final f = c.filter.value;
        return Column(children: [
          SearchFilterBar<CustomerFilter>(
            hint: c.canApprove ? 'Cari instansi, sales, PIC, atau kota' : 'Cari instansi, PIC, kota, atau kategori',
            query: c.query.value,
            onQuery: (v) => c.query.value = v,
            options: [
              FilterOption(CustomerFilter.semua, 'Semua', count: c.countOf(CustomerFilter.semua)),
              FilterOption(CustomerFilter.menunggu, 'Menunggu', count: c.countOf(CustomerFilter.menunggu)),
              FilterOption(CustomerFilter.disetujui, 'Disetujui', count: c.countOf(CustomerFilter.disetujui)),
              FilterOption(CustomerFilter.ditolak, 'Ditolak', count: c.countOf(CustomerFilter.ditolak)),
            ],
            selected: f,
            onSelected: (v) => c.filter.value = v,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (c.customers.isEmpty)
                    SizedBox(
                      height: 360,
                      child: EmptyState(
                        icon: Icons.business_outlined,
                        title: 'Belum ada customer',
                        subtitle: c.canCreate
                            ? 'Tekan "Ajukan customer" untuk mengajukan instansi baru.'
                            : 'Pengajuan customer dari Sales akan tampil di sini.',
                      ),
                    )
                  else if (list.isEmpty) ...[
                    SizedBox(
                      height: 320,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: f == CustomerFilter.menunggu && c.query.value.trim().isEmpty
                            ? 'Tidak ada yang menunggu'
                            : 'Tidak ada hasil',
                        subtitle: 'Ubah kata kunci atau filter yang dipakai.',
                      ),
                    ),
                    Center(child: TextButton(onPressed: c.resetFilters, child: const Text('Tampilkan semua'))),
                  ],
                  for (final (i, x) in list.indexed)
                    FadeSlideIn(
                      index: i,
                      child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _CustomerCard(x: x, c: c)),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.x, required this.c});
  final Customer x;
  final CustomerController c;

  @override
  Widget build(BuildContext context) {
    final kota = x.kota?.trim() ?? '';
    final pic = x.namaPic?.trim() ?? '';
    final kontak = x.kontakPic?.trim() ?? '';
    final kategori = x.kategori?.trim() ?? '';
    final sales = x.salesNama?.trim() ?? '';
    final area = x.areaNama?.trim() ?? '';
    final alasan = x.rejectionReason?.trim() ?? '';
    final busy = c.busyId.value == x.id;
    final canEdit = c.canEdit(x);

    final accent = x.isApproved ? AppColors.successFg : (x.isRejected ? AppColors.dangerFg : AppColors.warningFg);
    final chip = x.isApproved
        ? const StatusChip.success('Disetujui')
        : (x.isRejected ? const StatusChip.danger('Ditolak') : const StatusChip.warning('Menunggu'));

    return AppCard(
      accent: accent,
      onTap: canEdit ? () => c.openEdit(x) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(x.namaInstansi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          const SizedBox(width: 8),
          chip,
        ]),
        if (kota.isNotEmpty) ...[const SizedBox(height: 10), MetaRow(Icons.location_city_outlined, kota)],
        if (kategori.isNotEmpty) ...[const SizedBox(height: 4), MetaRow(Icons.category_outlined, kategori)],
        if (pic.isNotEmpty) ...[const SizedBox(height: 4), MetaRow(Icons.person_outline, pic)],
        if (kontak.isNotEmpty) ...[const SizedBox(height: 4), MetaRow(Icons.phone_outlined, kontak)],
        if (c.canApprove && (sales.isNotEmpty || area.isNotEmpty)) ...[
          const SizedBox(height: 4),
          MetaRow(Icons.badge_outlined, [if (sales.isNotEmpty) 'Sales $sales', if (area.isNotEmpty) area].join(' · ')),
        ],
        if (x.isRejected && alasan.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
            child: Text('Alasan penolakan: $alasan', style: const TextStyle(fontSize: 12, color: AppColors.dangerFg)),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 10),
          Text(
            x.isRejected ? 'Ketuk untuk memperbaiki dan mengajukan ulang.' : 'Ketuk untuk mengubah (pengajuan dikirim ulang ke SPV).',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
        if (c.canApprove && x.isPending) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => c.reject(x),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerFg,
                  side: const BorderSide(color: AppColors.dangerFg),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : () => c.approve(x),
                icon: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: const Text('Setujui'),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}