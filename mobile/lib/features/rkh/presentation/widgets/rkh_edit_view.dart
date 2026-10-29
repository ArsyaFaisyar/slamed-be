import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_detail_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/date_field.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';

class RkhEditView extends StatelessWidget {
  const RkhEditView({super.key, required this.c});
  final RkhDetailController c;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionTitle('Ubah kegiatan'),
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
            Obx(() => DateField(
                  label: 'Tanggal pelaksanaan',
                  value: c.tanggal.value,
                  onTap: () => c.pickDate(context),
                )),
            gap,
            TextField(
              controller: c.biaya,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: const InputDecoration(labelText: 'Estimasi biaya harian (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
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