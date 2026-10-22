import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/data/models/captcha.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';

class LoginController extends GetxController {
  LoginController(this._auth);
  final AuthController _auth;

  final username = TextEditingController();
  final password = TextEditingController();
  final answer = TextEditingController();
  final captcha = Rxn<Captcha>();
  final error = RxnString();
  final busy = false.obs;
  final obscure = true.obs;


  @override
  void onInit() {
    super.onInit();
    loadCaptcha();
  }

  @override
  void onClose() {
    username.dispose();
    password.dispose();
    answer.dispose();
    super.onClose();
  }
  void toggleObscure() => obscure.toggle();

  Future<void> loadCaptcha() async {
    try {
      captcha.value = await _auth.fetchCaptcha();
      answer.clear();
    } catch (e) {
      error.value = errorMessage(e);
    }
  }

  Future<void> submit() async {
    if (captcha.value == null || username.text.isEmpty || password.text.isEmpty) {
      error.value = 'Lengkapi username, password, dan CAPTCHA.';
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      await _auth.login(username.text.trim(), password.text, captcha.value!, answer.text);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      error.value = errorMessage(e);
      loadCaptcha(); // CAPTCHA sekali pakai
    } finally {
      busy.value = false;
    }
  }
}