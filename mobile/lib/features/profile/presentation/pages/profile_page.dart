import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/change_password_sheet.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/section_title.dart';
import 'package:slamed_app/shared/widgets/status_chip.dart';
import 'package:slamed_app/shared/widgets/user_avatar.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  static const _sheetShape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)));

  void _choosePhotoSource() {
    Get.bottomSheet(
      SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil dari kamera'),
            onTap: () {
              Get.back();
              controller.pickPhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () {
              Get.back();
              controller.pickPhoto(ImageSource.gallery);
            },
          ),
        ]),
      ),
      backgroundColor: AppColors.surfaceHigh,
      shape: _sheetShape,
    );
  }

  void _openChangePassword() {
    Get.bottomSheet(
      const ChangePasswordSheet(),
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceHigh,
      shape: _sheetShape,
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await confirmDialog(
      title: 'Keluar dari akun?',
      message: 'Anda perlu login lagi untuk memakai aplikasi.',
      confirmLabel: 'Keluar',
    );
    if (ok) controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AppScaffold(
      title: 'Profil',
      body: Obx(() {
        final u = c.user.value;
        final uploading = c.uploading.value;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          FadeSlideIn(
            child: AppCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(children: [
                      const UserAvatar(size: 96),
                      if (uploading)
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0x99000000)),
                            child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
                          ),
                        ),
                      Positioned(right: 0, bottom: 0, child: _CameraBadge(onTap: uploading ? null : _choosePhotoSource)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(u?.nama ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  if (u != null) ...[
                    const SizedBox(height: 2),
                    Text('@${u.username}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    const SizedBox(height: 10),
                    StatusChip(u.role),
                  ],
                ]),
              ),
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
          const SectionTitle('Keamanan'),
          FadeSlideIn(
            index: 2,
            child: AppCard(
              onTap: _openChangePassword,
              child: const Row(children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(child: Text('Ubah kata sandi', style: TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Kinerja'),
          const FadeSlideIn(
            index: 3,
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

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Ubah foto profil',
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(side: BorderSide(color: AppColors.bg, width: 3)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.photo_camera_rounded, size: 18, color: AppColors.onPrimary),
            ),
          ),
        ),
      );
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