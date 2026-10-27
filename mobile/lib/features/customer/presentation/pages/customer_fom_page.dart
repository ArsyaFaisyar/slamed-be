import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/customer/presentation/controllers/customer_form_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/info_banner.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';

class CustomerFormPage extends GetView<CustomerFormController> {
  const CustomerFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final e = c.existing;
    const gap = SizedBox(height: 14);
    return AppScaffold(
      title: c.isEdit ? 'Ubah pengajuan' : 'Ajukan customer',
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() => PrimaryButton(
                label: c.isEdit ? 'Simpan dan ajukan ulang' : 'Ajukan customer',
                icon: Icons.send_rounded,
                loading: c.busy.value,
                onPressed: c.submit,
              )),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          InfoBanner(
            c.isEdit
                ? 'Setelah disimpan, pengajuan dikirim ulang ke SPV dan statusnya kembali menunggu persetujuan.'
                : 'Pengajuan dikirim ke SPV. Customer baru bisa dipakai untuk RKH setelah disetujui, dan otomatis menjadi milik Anda di area Anda.',
          ),
          if (e != null && e.isRejected && (e.rejectionReason ?? '').trim().isNotEmpty)
            ErrorBox('Alasan penolakan: ${e.rejectionReason!.trim()}'),
          const SizedBox(height: 20),
          const SectionTitle('Data instansi'),
          AppCard(
            child: Column(children: [
              TextField(
                controller: c.nama,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama instansi', prefixIcon: Icon(Icons.business_outlined)),
              ),
              gap,
              TextField(
                controller: c.kota,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Kota (opsional)', prefixIcon: Icon(Icons.location_city_outlined)),
              ),
              gap,
              Obx(() {
                if (c.loadingCategories.value) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: LinearProgressIndicator());
                }
                if (c.categories.isEmpty) {
                  return TextField(
                    controller: c.kategoriText,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Kategori (opsional)', prefixIcon: Icon(Icons.category_outlined)),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: c.kategori.value,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  decoration: const InputDecoration(labelText: 'Kategori (opsional)', prefixIcon: Icon(Icons.category_outlined)),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tanpa kategori')),
                    for (final k in c.categories) DropdownMenuItem(value: k, child: Text(k, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => c.kategori.value = (v == null || v.isEmpty) ? null : v,
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Kontak PIC'),
          AppCard(
            child: Column(children: [
              TextField(
                controller: c.namaPic,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama PIC (opsional)', prefixIcon: Icon(Icons.person_outline)),
              ),
              gap,
              TextField(
                controller: c.kontakPic,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Kontak PIC (opsional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
            ]),
          ),
          Obx(() {
            final err = c.error.value;
            return err == null ? const SizedBox.shrink() : ErrorBox(err);
          }),
        ],
      ),
    );
  }
}