import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';

/// Avatar pengguna untuk Beranda dan Profil. Foto diambil dari `AuthController.photo`
/// (satu sumber, dimuat sekali); tanpa foto atau gagal dimuat, tampil inisial.
/// Ukurannya persegi dan tetap, jadi tata letak di sekitarnya tidak bergeser.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.size, this.ring = true});
  final double size;

  /// Cincin gradasi tipis di sekeliling foto.
  final bool ring;

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final u = auth.user.value;
      final bytes = auth.photo.value;
      final pad = ring ? 3.0 : 0.0;
      final inner = size - pad * 2;

      final fallback = ColoredBox(
        color: AppColors.surfaceHigh,
        child: Center(
          child: Text(
            _initials(u?.nama),
            style: TextStyle(fontSize: inner * 0.36, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ),
      );

      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(pad),
        decoration: ring ? const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient) : null,
        child: ClipOval(
          child: SizedBox.square(
            dimension: inner,
            child: bytes == null
                ? fallback
                : Image.memory(
                    bytes,
                    width: inner,
                    height: inner,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      );
    });
  }
}