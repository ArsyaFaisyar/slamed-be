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
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_detail_controller.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_form_controller.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';

/// semua: kedua daftar. perluLkh: RKH yang belum punya LKH.
/// belum / done: riwayat LKH menurut status_lkh.
enum LkhFilter { semua, perluLkh, belum, done }

class LkhController extends GetxController {
  LkhController(this._auth, this._rkhRepo, this._lkhRepo, this._customerRepo);
  final AuthController _auth;
  final RkhRepository _rkhRepo;
  final LkhRepository _lkhRepo;
  final CustomerRepository _customerRepo;

  final loading = true.obs;
  final error = RxnString();
  final rkh = <Rkh>[].obs;
  final lkh = <Lkh>[].obs;
  final customers = <int, Customer>{}.obs;

  // Pencarian dan filter (disimpan di controller, jadi bertahan saat pindah tab).
  final query = ''.obs;
  final filter = LkhFilter.semua.obs;
  final range = Rxn<DateTimeRange>();

  /// RKH yang belum punya LKH, urut dari jadwal terdekat.
  List<Rkh> get pending {
    final filled = lkh.map((e) => e.rkhId).toSet();
    return rkh.where((r) => !filled.contains(r.id)).toList()
      ..sort((a, b) => a.tanggalPelaksanaan.compareTo(b.tanggalPelaksanaan));
  }

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  Rkh? _rkhOf(int id) {
    for (final r in rkh) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// RKH tanpa LKH yang lolos kata kunci dan rentang tanggal pelaksanaan.
  List<Rkh> get _pendingBase {
    final q = query.value.trim().toLowerCase();
    final r = range.value;
    return pending.where((x) {
      if (r != null && !dateInRange(x.tanggalPelaksanaan, r)) return false;
      if (q.isEmpty) return true;
      return x.judulKegiatan.toLowerCase().contains(q) ||
          x.tipeAktivitas.toLowerCase().contains(q) ||
          customerName(x.customerId).toLowerCase().contains(q);
    }).toList();
  }

  /// LKH yang lolos kata kunci dan rentang tanggal kunjungan (belum disaring status).
  List<Lkh> get _historyBase {
    final q = query.value.trim().toLowerCase();
    final r = range.value;
    return lkh.where((l) {
      if (r != null && !dateInRange(l.tanggalKunjungan, r)) return false;
      if (q.isEmpty) return true;
      final rk = _rkhOf(l.rkhId);
      return (rk?.judulKegiatan ?? '').toLowerCase().contains(q) ||
          (rk == null ? '' : customerName(rk.customerId)).toLowerCase().contains(q) ||
          l.namaPic.toLowerCase().contains(q) ||
          l.hasilKunjungan.toLowerCase().contains(q);
    }).toList();
  }

  /// Jumlah untuk satu pilihan filter, mengikuti kata kunci dan rentang tanggal.
  int countOf(LkhFilter f) => switch (f) {
        LkhFilter.semua => _pendingBase.length + _historyBase.length,
        LkhFilter.perluLkh => _pendingBase.length,
        LkhFilter.belum => _historyBase.where((l) => !l.isDone).length,
        LkhFilter.done => _historyBase.where((l) => l.isDone).length,
      };

  /// Daftar "Perlu LKH" yang ditampilkan menurut filter aktif.
  List<Rkh> get pendingVisible =>
      (filter.value == LkhFilter.semua || filter.value == LkhFilter.perluLkh) ? _pendingBase : <Rkh>[];

  /// Riwayat LKH yang ditampilkan menurut filter aktif.
  List<Lkh> get historyVisible => switch (filter.value) {
        LkhFilter.perluLkh => <Lkh>[],
        LkhFilter.semua => _historyBase,
        LkhFilter.belum => _historyBase.where((l) => !l.isDone).toList(),
        LkhFilter.done => _historyBase.where((l) => l.isDone).toList(),
      };

  bool get filtering => query.value.trim().isNotEmpty || filter.value != LkhFilter.semua || range.value != null;

  void resetFilters() {
    query.value = '';
    filter.value = LkhFilter.semua;
    range.value = null;
  }

  Future<void> load() async {
    final salesId = _auth.role == Roles.sales ? _auth.user.value!.id : null;
    loading.value = true;
    error.value = null;
    try {
      final r = await _rkhRepo.list(salesId: salesId);
      final l = await _lkhRepo.list(salesId: salesId);
      final c = await _customerRepo.list();
      l.sort((a, b) => b.tanggalKunjungan.compareTo(a.tanggalKunjungan));
      rkh.assignAll(r);
      lkh.assignAll(l);
      customers.value = {for (final x in c) x.id: x};
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> openForm(Rkh r) async {
    // PIC customer dipakai untuk mengisi form otomatis; pengguna tetap bisa mengubahnya.
    final cust = customers[r.customerId];
    // Tanpa generik: Get.toNamed<bool> memicu cast GetPageRoute -> Route<bool?> yang gagal.
    final ok = await Get.toNamed(
      AppRoutes.lkhForm,
      arguments: LkhFormArgs(
        r,
        customerName(r.customerId),
        namaPic: cust?.namaPic,
        nomorPic: cust?.kontakPic,
      ),
    );
    if (ok == true) load();
  }

  /// Buka detail; daftar dimuat ulang setelah kembali (data bisa berubah/terhapus).
  Future<void> openDetail(Lkh l) async {
    final r = _rkhOf(l.rkhId);
    await Get.toNamed(
      AppRoutes.lkhDetail,
      arguments: LkhDetailArgs(
        l,
        r?.judulKegiatan ?? 'RKH #${l.rkhId}',
        r == null ? '-' : customerName(r.customerId),
      ),
    );
    load();
  }
}