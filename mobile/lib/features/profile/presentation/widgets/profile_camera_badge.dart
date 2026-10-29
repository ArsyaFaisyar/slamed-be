import 'package:flutter/material.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

class ProfileCameraBadge extends StatelessWidget {
  const ProfileCameraBadge({super.key, required this.onTap});
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