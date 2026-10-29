import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/features/project/presentation/widgets/project_status_label.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/meta_row.dart';

/// Status project saat ini (nama + warna) dan nama project-nya.
class LkhStatusProjectCard extends StatelessWidget {
  const LkhStatusProjectCard({super.key, required this.c});
  final LkhDetailController c;

  @override
  Widget build(BuildContext context) => Obx(() {
        if (c.loadingProject.value) {
          return const AppCard(child: LinearProgressIndicator());
        }
        final p = c.project.value;
        if (p == null) {
          return AppCard(
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.projectError.value ?? 'Status project tidak tersedia.',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ),
              TextButton(onPressed: c.loadProject, child: const Text('Coba lagi')),
            ]),
          );
        }
        return AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ProjectStatusLabel(
              nama: p.statusNama ?? 'Belum ada status',
              warna: p.statusWarna,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            MetaRow(Icons.folder_open_outlined, p.namaProject),
          ]),
        );
      });
}