import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';

void showSnack(String message) => Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: AppColors.surfaceHigh,
      colorText: AppColors.text,
      icon: const Icon(Icons.info_outline, color: AppColors.primary),
    );