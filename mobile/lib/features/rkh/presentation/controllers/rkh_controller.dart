import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/utils/date_range.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_detail_controller.dart';

enum RkhFilter { semua, belumLkh, lkhTerisi }

class RkhController extends GetxController {
  RkhController(this._auth, this._rkhRepo, this._lkhRepo, this._customerRepo);
  final AuthController _auth;
  final RkhRepository _rkhRepo;
  final LkhRepository _lkhRepo;
  final CustomerRepository _customerRepo;

  final loading = true.obs;
  final error = RxnString();
  final rkh = <Rkh>[].obs;
  final withLkh = <int>{}.obs;
  final customers = <int, Customer>{}.obs;

  // Pencarian dan filter (disimpan di controller, jadi bertahan saat pindah tab).
  final query = ''.obs;
  final filter = RkhFilter.semua.obs;
  final range = Rxn<DateTimeRange>();

  int get doneCount => rkh.where((r) => withLkh.contains(r.id)).length;

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  /// RKH yang lolos kata kunci dan rentang tanggal (belum disaring status LKH).
  List<Rkh> get _base {
    final q = query.value.trim().toLowerCase();
    final r = range.value;
    return rkh.where((x) {
      if (r != null && !dateInRange(x.tanggalPelaksanaan, r)) return false;
      if (q.isEmpty) return true;
      return x.judulKegiatan.toLowerCase().contains(q) ||
          x.tipeAktivitas.toLowerCase().contains(q) ||
          customerName(x.customerId).toLowerCase().contains(q);
    }).toList();
  }

  List<Rkh> _byStatus(List<Rkh> base, RkhFilter f) => switch (f) {
        RkhFilter.semua => base,
        RkhFilter.belumLkh => base.where((x) => !withLkh.contains(x.id)).toList(),
        RkhFilter.lkhTerisi => base.where((x) => withLkh.contains(x.id)).toList(),
      };

  /// Jumlah RKH untuk satu pilihan filter, mengikuti kata kunci dan rentang tanggal.
  int countOf(RkhFilter f) => _byStatus(_base, f).length;

  /// Daftar yang ditampilkan.
  List<Rkh> get visible => _byStatus(_base, filter.value);

  bool get filtering => query.value.trim().isNotEmpty || filter.value != RkhFilter.semua || range.value != null;

  void resetFilters() {
    query.value = '';
    filter.value = RkhFilter.semua;
    range.value = null;
  }

  Future<void> load() async {
    final salesId = _auth.role == Roles.sales ? _auth.user.value!.id : null;
    loading.value = true;
    error.value = null;
    try {
      // Berurutan (bukan Future.wait) agar ApiException asli tetap terbaca.
      final r = await _rkhRepo.list(salesId: salesId);
      final l = await _lkhRepo.list(salesId: salesId);
      final c = await _customerRepo.list();
      r.sort((a, b) => b.tanggalPelaksanaan.compareTo(a.tanggalPelaksanaan));
      rkh.assignAll(r);
      withLkh
        ..clear()
        ..addAll(l.map((e) => e.rkhId));
      customers.value = {for (final x in c) x.id: x};
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> openForm() async {
    // Tanpa generik: Get.toNamed<bool> memicu cast GetPageRoute -> Route<bool?> yang gagal.
    final ok = await Get.toNamed(AppRoutes.rkhForm);
    if (ok == true) load();
  }

  /// Buka detail; daftar dimuat ulang setelah kembali (data bisa berubah/terhapus).
  Future<void> openDetail(Rkh r) async {
    await Get.toNamed(
      AppRoutes.rkhDetail,
      arguments: RkhDetailArgs(r, customerName(r.customerId), withLkh.contains(r.id)),
    );
    load();
  }
}