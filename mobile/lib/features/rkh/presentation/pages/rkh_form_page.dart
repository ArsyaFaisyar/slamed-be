import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/core/utils/date_format.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_form_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';

class RkhFormPage extends GetView<RkhFormController> {
  const RkhFormPage({super.key});

  /// Penjelasan di bawah dropdown project saat belum bisa dipilih.
  String? _projectHint(RkhFormController c) {
    if (c.customerId.value == null) return 'Pilih customer terlebih dahulu';
    if (c.loadingProjects.value) return 'Memuat project...';
    if (c.projects.isEmpty) return 'Customer ini belum punya project. Tambahkan project di web terlebih dahulu.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    const gap = SizedBox(height: 14);
    return AppScaffold(
      title: 'Tambah RKH',
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() => PrimaryButton(
                label: 'Simpan RKH',
                icon: Icons.check_rounded,
                loading: c.busy.value,
                onPressed: c.submit,
              )),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        const SectionTitle('Tujuan kunjungan'),
        AppCard(
          child: Column(children: [
            Obx(() => DropdownButtonFormField<int>(
                  initialValue: c.customerId.value,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  decoration: const InputDecoration(labelText: 'Customer', prefixIcon: Icon(Icons.business_outlined)),
                  items: [
                    for (final x in c.customers)
                      DropdownMenuItem(value: x.id, child: Text(x.namaInstansi, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: c.pickCustomer,
                )),
            gap,
            Obx(() => DropdownButtonFormField<int>(
                  // key: dropdown dibangun ulang saat customer berganti agar pilihan project ter-reset.
                  key: ValueKey('project-${c.customerId.value}-${c.projects.length}'),
                  initialValue: c.projectId.value,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  decoration: InputDecoration(
                    labelText: 'Project / prospek',
                    prefixIcon: const Icon(Icons.folder_open_outlined),
                    helperText: _projectHint(c),
                    helperMaxLines: 2,
                  ),
                  items: [
                    for (final p in c.projects)
                      DropdownMenuItem(value: p.id, child: Text(p.namaProject, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: c.projects.isEmpty ? null : (v) => c.projectId.value = v,
                )),
          ]),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Jadwal'),
        AppCard(
          child: Obx(() => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => c.pickDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal pelaksanaan',
                    prefixIcon: Icon(Icons.event_outlined),
                    helperText: 'Maksimal ${AppConstants.maxHariKeDepan} hari dari hari ini',
                  ),
                  child: Text(formatDate(c.pelaksanaan.value)),
                ),
              )),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Detail kegiatan'),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: c.judul,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Judul kegiatan', prefixIcon: Icon(Icons.title_rounded)),
            ),
            gap,
            TextField(
              controller: c.rencana,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Rencana kegiatan', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            gap,
            TextField(
              controller: c.tipe,
              decoration: const InputDecoration(labelText: 'Tipe aktivitas', prefixIcon: Icon(Icons.category_outlined)),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in AppConstants.tipeAktivitasSaran) ActionChip(label: Text(t), onPressed: () => c.tipe.text = t),
            ]),
            gap,
            TextField(
              controller: c.biaya,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Estimasi biaya harian (Rp)',
                prefixIcon: Icon(Icons.payments_outlined),
                helperText: 'Satu nilai untuk semua customer di tanggal yang sama',
              ),
            ),
          ]),
        ),
        Obx(() {
          final e = c.error.value;
          if (e == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline, size: 18, color: AppColors.dangerFg),
              const SizedBox(width: 8),
              Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: AppColors.dangerFg))),
            ]),
          );
        }),
      ]),
    );
  }
}