import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/features/project/presentation/widgets/project_status_dropdown.dart';
import 'package:slamed_app/features/project/presentation/widgets/project_status_label.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/date_field.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';

class LkhEditView extends StatelessWidget {
  const LkhEditView({super.key, required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
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
            gap,
            Obx(() => DateField(
                  label: 'Tanggal follow-up (opsional)',
                  icon: Icons.event_repeat_outlined,
                  value: c.followUp.value,
                  onTap: () => c.pickFollowUp(context),
                  onClear: c.clearFollowUp,
                )),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Status project'),
        AppCard(
          child: Obx(() {
            final p = c.project.value;
            if (c.loadingProject.value) return const LinearProgressIndicator();
            if (p == null) {
              return const Row(children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status project tidak dapat dimuat, jadi tidak diubah dari sini.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              ]);
            }
            if (!c.canChangeStatus) {
              return ProjectStatusLabel(
                nama: '${p.statusNama ?? 'Belum ada status'} · tidak ada status lanjutan yang tersedia',
                warna: p.statusWarna,
                style: const TextStyle(fontSize: 13),
              );
            }
            return ProjectStatusDropdown(
              statuses: c.statusOptions,
              value: c.statusId.value,
              onChanged: (v) => c.statusId.value = v,
            );
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
              decoration: const InputDecoration(labelText: 'Nama PIC', prefixIcon: Icon(Icons.person_outline), counterText: ''),
            ),
            gap,
            TextField(
              controller: c.nomorPic,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor PIC', prefixIcon: Icon(Icons.phone_outlined), counterText: ''),
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