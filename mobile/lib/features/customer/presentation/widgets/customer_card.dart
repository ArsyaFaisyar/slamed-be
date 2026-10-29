import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/customer/presentation/controllers/customer_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.x, required this.c});
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