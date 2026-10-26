import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/profile/data/profile_repository.dart';
import 'package:slamed_app/features/profile/domain/profile_rules.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController(this._repo);
  final ProfileRepository _repo;

  final lama = TextEditingController();
  final baru = TextEditingController();
  final konfirmasi = TextEditingController();

  final hideLama = true.obs;
  final hideBaru = true.obs;
  final hideKonfirmasi = true.obs;
  final busy = false.obs;
  final error = RxnString();

  @override
  void onClose() {
    lama.dispose();
    baru.dispose();
    konfirmasi.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (busy.value) return;
    final err = validatePasswordChange(lama: lama.text, baru: baru.text, konfirmasi: konfirmasi.text);
    if (err != null) {
      error.value = err;
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      await _repo.changePassword(lama.text, baru.text);
      Get.back();
      showSnack('Password berhasil diubah.');
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      busy.value = false;
    }
  }
}