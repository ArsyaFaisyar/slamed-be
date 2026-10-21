import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';

/// Route yang butuh login dialihkan ke halaman login bila sesi tidak ada.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<AuthController>().isLoggedIn ? null : const RouteSettings(name: AppRoutes.login);
}