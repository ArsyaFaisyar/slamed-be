import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/features/lkh/presentation/widgets/lkh_dokumentasi_section.dart';
import 'package:slamed_app/features/lkh/presentation/widgets/lkh_status_project_card.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/info_banner.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class LkhDetailView extends StatelessWidget {
  const LkhDetailView({super.key, required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) => Obx(() {
        final l = c.lkh.value;
        final lokasi = (l.latitude != null && l.longitude != null)
            ? '${l.latitude!.toStringAsFixed(5)}, ${l.longitude!.toStringAsFixed(5)}'
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              accent: l.isDone ? AppColors.successFg : AppColors.warningFg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(c.judulRkh, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                  const SizedBox(width: 8),
                  l.isDone ? StatusChip.success(l.statusLabel) : StatusChip.warning(l.statusLabel),
                ]),
                const SizedBox(height: 12),
                MetaRow(Icons.business_outlined, c.customerName),
                const SizedBox(height: 4),
                MetaRow(Icons.event_outlined, 'Kunjungan ${formatDate(l.tanggalKunjungan)}'),
                if (l.namaPic.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.person_outline, l.nomorPic.isEmpty ? l.namaPic : '${l.namaPic} · ${l.nomorPic}'),
                ],
                if (lokasi != null) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.location_on_outlined, lokasi),
                ],
                if (l.tanggalFollowUp != null) ...[
                  const SizedBox(height: 4),
                  MetaRow(Icons.event_repeat_outlined, 'Follow-up ${formatDate(l.tanggalFollowUp!)}'),
                ],
              ]),
            ),
            if (!l.isDone) ...[
              const SizedBox(height: 16),
              InfoBanner(c.hasFoto
                  ? 'LKH berstatus Belum. Ubah datanya bila perlu, lalu tekan "Tandai selesai".'
                  : 'Foto dokumentasi belum terkirim. Tekan "Lengkapi foto" untuk menyelesaikan LKH.'),
            ],
            const SizedBox(height: 20),
            const SectionTitle('Status project'),
            LkhStatusProjectCard(c: c),
            const SizedBox(height: 20),
            const SectionTitle('Hasil kunjungan'),
            AppCard(child: Text(l.hasilKunjungan, style: const TextStyle(fontSize: 14, height: 1.4))),
            if ((l.tindakLanjut ?? '').isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionTitle('Tindak lanjut'),
              AppCard(child: Text(l.tindakLanjut!, style: const TextStyle(fontSize: 14, height: 1.4))),
            ],
            const SizedBox(height: 20),
            const SectionTitle('Dokumentasi'),
            LkhDokumentasiSection(c: c),
          ],
        );
      });
}