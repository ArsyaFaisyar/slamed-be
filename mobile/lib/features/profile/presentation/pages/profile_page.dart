import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/config/app_config.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';

class ProfilePage extends GetView<AuthController> {
  const ProfilePage({super.key});

  Future<void> _confirmLogout() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      title: const Text('Keluar dari akun?'),
      content: const Text('Anda perlu login lagi untuk memakai aplikasi.'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Get.back(result: true),
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          child: const Text('Keluar'),
        ),
      ],
    ));
    if (ok == true) controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: AppColors.surface, child: Icon(Icons.person, size: 40, color: AppColors.muted));
    return AppScaffold(
      title: 'Profil',
      body: Obx(() {
        final u = controller.user.value;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          FadeSlideIn(
            child: AppCard(
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  child: ClipOval(
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      // foto_profil kosong -> avatar default (tanpa request). Jika ada,
                      // ambil lewat GET /profile/photo (butuh token); gagal -> avatar default.
                      child: (u?.fotoProfil == null)
                          ? fallback
                          : Image.network(
                              '${AppConfig.apiBaseUrl}/profile/photo',
                              headers: {'Authorization': 'Bearer ${controller.token.value}'},
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => fallback,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u?.nama ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (u != null) StatusChip(u.role),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Akun'),
          FadeSlideIn(
            index: 1,
            child: AppCard(
              child: Column(children: [
                _InfoRow(Icons.alternate_email_rounded, 'Username', u?.username),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                _InfoRow(Icons.mail_outline_rounded, 'Email', u?.email),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Kinerja'),
          const FadeSlideIn(
            index: 2,
            child: AppCard(
              child: Row(children: [
                Icon(Icons.track_changes_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Target penyelesaian dihitung dari data RKH dan LKH.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerFg,
                side: const BorderSide(color: AppColors.dangerFg),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(width: 12),
        Expanded(child: Text(value ?? '-', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);
}