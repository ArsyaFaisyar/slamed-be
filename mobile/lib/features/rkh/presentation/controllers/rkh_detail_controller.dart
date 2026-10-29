import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh_update.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';
import 'package:slamed_app/core/utils/date_picker.dart';

class RkhDetailArgs {
  const RkhDetailArgs(this.rkh, this.customerName, this.hasLkh);
  final Rkh rkh;
  final String customerName;
  final bool hasLkh;
}

class RkhDetailController extends GetxController {
  RkhDetailController(this._repo);
  final RkhRepository _repo;

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

  /// RKH yang sudah punya LKH dikunci: rencana tidak berubah setelah dilaporkan.
  bool get canModify => !hasLkh;

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
    try {
      await _repo.delete(rkh.value.id);
      showSnack('RKH dihapus.');
      Get.back();
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
    }
  }
}