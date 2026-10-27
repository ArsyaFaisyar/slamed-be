// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:slamed_app/core/theme/app_colors.dart';
// import 'package:slamed_app/features/lkh/presentation/controller/lkh_form_controller.dart';
// import 'package:slamed_app/features/project/domain/status_color.dart';

// class ProjectStatusField extends StatelessWidget {
//   const ProjectStatusField({super.key, required this.c});
//   final LkhFormController c;

//   @override
//   Widget build(BuildContext context) => Obx(() {
//         if (c.loadingStatuses.value) {
//           return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
//         }
//         final err = c.statusError.value;
//         if (err != null) {
//           return Row(children: [
//             Expanded(
//               child: Text('Status project tidak dapat dimuat. $err', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
//             ),
//             TextButton(onPressed: c.loadStatuses, child: const Text('Coba lagi')),
//           ]);
//         }
//         if (c.statuses.isEmpty) {
//           return const Text('Belum ada status project aktif.', style: TextStyle(color: AppColors.muted));
//         }
//         final locked = c.statusSynced.value;
//         return DropdownButtonFormField<int>(
//           key: ValueKey('status-${c.statuses.length}-${c.statusId.value}-$locked'),
//           initialValue: c.statusId.value,
//           isExpanded: true,
//           dropdownColor: AppColors.surfaceHigh,
//           borderRadius: BorderRadius.circular(14),
//           decoration: InputDecoration(
//             labelText: 'Status project (opsional)',
//             prefixIcon: const Icon(Icons.flag_outlined),
//             helperText: locked
//                 ? 'Status project sudah tersimpan.'
//                 : (c.statusHint ?? 'Ubah hanya bila tahap project berubah setelah kunjungan ini.'),
//             helperMaxLines: 2,
//           ),
//           items: [
//             for (final s in c.statuses)
//               DropdownMenuItem(
//                 value: s.id,
//                 child: Row(children: [
//                   Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(color: statusColor(s.warna) ?? AppColors.infoFg, shape: BoxShape.circle),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(child: Text(s.nama, overflow: TextOverflow.ellipsis)),
//                 ]),
//               ),
//           ],
//           onChanged: locked ? null : c.pickStatus,
//         );
//       });
// }