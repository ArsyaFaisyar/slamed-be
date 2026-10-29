import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/core/utils/date_picker.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh_update.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/features/rkh/domain/rkh_edit_rules.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

/// Argumen navigasi ke detail RKH.
class RkhDetailArgs {
  const RkhDetailArgs(this.rkh, this.customerName, this.hasLkh);
  final Rkh rkh;
  final String customerName;
  final bool hasLkh;
}

class RkhDetailController extends GetxController {
  RkhDetailController(this._repo, this._auth);
  final RkhRepository _repo;
  final AuthController _auth;

  late final Rx<Rkh> rkh;
  late final String customerName;
  late final bool hasLkh;

  final judul = TextEditingController();
  final rencana = TextEditingController();
  final tipe = TextEditingController();
  final biaya = TextEditingController();

  final tanggal = DateTime.now().obs;
  final editing = false.obs;
  final busy = false.obs;
  final error = RxnString();

  /// Alasan RKH terkunci (null bila boleh diubah): milik sales lain, sudah punya LKH, atau sudah CLOSED.
  String? get lockReason =>
      rkhLockReason(rkh: rkh.value, hasLkh: hasLkh, role: _auth.role, userId: _auth.user.value?.id);

  bool get canModify => lockReason == null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as RkhDetailArgs;
    rkh = args.rkh.obs;
    customerName = args.customerName;
    hasLkh = args.hasLkh;
  }

  @override
  void onClose() {
    judul.dispose();
    rencana.dispose();
    tipe.dispose();
    biaya.dispose();
    super.onClose();
  }

  void startEdit() {
    final r = rkh.value;
    judul.text = r.judulKegiatan;
    rencana.text = r.rencanaKegiatan;
    tipe.text = r.tipeAktivitas;
    biaya.text = rupiahInputText(r.estimasiBiayaHarian); // "150000.00" -> "150.000"
    tanggal.value = r.tanggalPelaksanaan;
    error.value = null;
    editing.value = true;
  }

  void cancelEdit() {
    error.value = null;
    editing.value = false;
  }

  Future<void> pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = await pickDateInRange(
      context,
      initial: tanggal.value,
      first: today,
      last: today.add(const Duration(days: AppConstants.maxHariKeDepan)),
    );
    if (d != null) tanggal.value = d;
  }

  Future<void> save() async {
    final j = judul.text.trim(), r = rencana.text.trim(), t = tipe.text.trim();
    if (j.isEmpty || r.isEmpty || t.isEmpty) {
      error.value = 'Judul, rencana, dan tipe aktivitas wajib diisi.';
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      rkh.value = await _repo.update(
        rkh.value.id,
        RkhUpdate(
          tanggalPelaksanaan: tanggal.value,
          judulKegiatan: j,
          rencanaKegiatan: r,
          tipeAktivitas: t,
          // Kolom berisi "150.000"; server menerima digit polos.
          estimasiBiayaHarian: rupiahDigits(biaya.text),
        ),
      );
      editing.value = false;
      showSnack('RKH diperbarui.');
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      busy.value = false;
    }
  }

  Future<void> remove() async {
    final ok = await confirmDialog(
      title: 'Hapus RKH?',
      message: '"${rkh.value.judulKegiatan}" akan dihapus permanen.',
    );
    if (!ok) return;
    busy.value = true;
    var berhasil = false;
    try {
      await _repo.delete(rkh.value.id);
      berhasil = true;
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
    }
    if (berhasil) {
      // Tutup halaman dulu. Snackbar yang masih tampil membuat Get.back() hanya menutup snackbar.
      Get.back();
      showSnack('RKH dihapus.');
    }
  }
}