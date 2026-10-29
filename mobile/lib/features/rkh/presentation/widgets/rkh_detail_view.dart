import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_detail_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/info_banner.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class RkhDetailView extends StatelessWidget {
  const RkhDetailView({super.key, required this.c});
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
            if (c.lockReason != null) ...[
              const SizedBox(height: 16),
              InfoBanner(c.lockReason!),
            ],
          ],
        );
      });
}