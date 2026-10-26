// import 'package:flutter/material.dart';
// import 'package:slamed_app/core/theme/app_colors.dart';
// import 'package:slamed_app/features/dashboard/domain/role_dashboard_data.dart';
// import 'package:slamed_app/features/dashboard/presentation/widgets/stat_tile.dart';
// import 'package:slamed_app/shared/widgets/app_card.dart';
// import 'package:slamed_app/shared/widgets/empty_state.dart';
// import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
// import 'package:slamed_app/shared/widgets/section_title.dart';
// import 'package:slamed_app/shared/widgets/status_chip.dart';

// class RoleDashboardView extends StatelessWidget {
//   const RoleDashboardView({super.key, required this.data});
//   final RoleDashboardData data;

//   (Color, Color) _tone(MetricTone t) => switch (t) {
//         MetricTone.info => (AppColors.infoFg, AppColors.infoBg),
//         MetricTone.success => (AppColors.successFg, AppColors.successBg),
//         MetricTone.warning => (AppColors.warningFg, AppColors.warningBg),
//         MetricTone.danger => (AppColors.dangerFg, AppColors.dangerBg),
//       };

//   @override
//   Widget build(BuildContext context) {
//     if (data.metrics.isEmpty && data.sections.isEmpty) {
//       return SizedBox(
//         height: 300,
//         child: EmptyState(icon: Icons.insights_outlined, title: data.title, subtitle: data.subtitle),
//       );
//     }
//     var n = 0;
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       FadeSlideIn(
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(data.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
//           const SizedBox(height: 2),
//           Text(data.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
//         ]),
//       ),
//       if (data.isSample) ...[
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
//           child: const Row(children: [
//             Icon(Icons.science_outlined, size: 18, color: AppColors.warningFg),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text('Data contoh. Belum terhubung ke backend.',
//                   style: TextStyle(fontSize: 13, color: AppColors.warningFg)),
//             ),
//           ]),
//         ),
//       ],
//       const SizedBox(height: 16),
//       if (data.metrics.isNotEmpty)
//         FadeSlideIn(
//           index: 1,
//           child: GridView(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//               mainAxisExtent: 112,
//             ),
//             children: [
//               for (final m in data.metrics)
//                 StatTile(icon: m.icon, label: m.label, value: m.value, color: _tone(m.tone).$1),
//             ],
//           ),
//         ),
//       for (final s in data.sections) ...[
//         const SizedBox(height: 20),
//         SectionTitle(s.title),
//         for (final item in s.items)
//           FadeSlideIn(
//             index: 2 + n++,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: AppCard(
//                 accent: _tone(item.tone).$1,
//                 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
//                     if (item.badge != null) ...[
//                       const SizedBox(width: 8),
//                       StatusChip(item.badge!, fg: _tone(item.tone).$1, bg: _tone(item.tone).$2),
//                     ],
//                   ]),
//                   const SizedBox(height: 4),
//                   Text(item.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
//                 ]),
//               ),
//             ),
//           ),
//       ],
//     ]);
//   }
// }