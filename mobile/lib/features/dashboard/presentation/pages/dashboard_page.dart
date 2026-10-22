import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class DashboardPage extends GetView<AuthController> {
  const DashboardPage({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          FadeSlideIn(
            child: Obx(() {
              final u = controller.user.value;
              // SALES/SPV tidak punya tab Profil, jadi header ini jalan masuknya.
              final canOpenProfile = Roles.isField(u?.role);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: canOpenProfile ? () => Get.toNamed(AppRoutes.profile) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                      child: Text(_initials(u?.nama ?? ''),
                          style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        Text(u?.nama ?? '-',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    if (u != null) StatusChip(u.role),
                    if (canOpenProfile) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ]),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const FadeSlideIn(
            index: 1,
            child: AppCard(
              accent: AppColors.primary,
              child: Row(children: [
                Icon(Icons.track_changes_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Target penyelesaian', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Ringkasan target dan kinerja akan tampil di sini.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}