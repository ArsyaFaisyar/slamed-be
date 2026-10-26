import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/data/models/app_user.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/dashboard/data/dummy_role_dashboard.dart';
import 'package:slamed_app/features/dashboard/domain/dashboard_stats.dart';
import 'package:slamed_app/features/dashboard/domain/role_dashboard_data.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';

class DashboardController extends GetxController {
  DashboardController(this._auth, this._rkhRepo, this._lkhRepo, this._customerRepo);
  final AuthController _auth;
  final RkhRepository _rkhRepo;
  final LkhRepository _lkhRepo;
  final CustomerRepository _customerRepo;

  final loading = true.obs;
  final error = RxnString();
  final rkh = <Rkh>[].obs;
  final lkh = <Lkh>[].obs;
  final customers = <int, Customer>{}.obs;
  final period = DashboardPeriod.week.obs;

  /// True bila data LKH berhasil dimuat; bila false, target hanya dari RKH.
  final lkhLoaded = false.obs;

  /// Ringkasan untuk role non-lapangan (saat ini data contoh).
  final roleData = Rxn<RoleDashboardData>();

  /// Diisi HomeController agar Beranda bisa membuka tab lain.
  void Function()? openRkh;
  void Function()? openProfile;

  Rxn<AppUser> get user => _auth.user;
  Rxn<Uint8List> get photo => _auth.photo;
  bool get isField => Roles.isField(_auth.role);

  DashboardStats get stats => DashboardStats.compute(
        rkh: rkh,
        lkh: lkhLoaded.value ? lkh : null,
        period: period.value,
        now: DateTime.now(),
      );

  String periodLabel(DashboardPeriod p) => switch (p) {
        DashboardPeriod.week => 'Minggu ini',
        DashboardPeriod.month => 'Bulan ini',
        DashboardPeriod.all => 'Semua',
      };

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  void setPeriod(DashboardPeriod p) => period.value = p;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!isField) {
      roleData.value = DummyRoleDashboard.forRole(_auth.role);
      loading.value = false;
      return;
    }
    final salesId = _auth.role == Roles.sales ? _auth.user.value!.id : null;
    loading.value = true;
    error.value = null;
    try {
      // Berurutan (bukan Future.wait) agar ApiException asli tetap terbaca.
      final r = await _rkhRepo.list(salesId: salesId);
      final c = await _customerRepo.list();

      // LKH opsional: dimatikan atau gagal tidak boleh merusak Beranda.
      List<Lkh>? l;
      if (AppConstants.lkhEnabled) {
        try {
          l = await _lkhRepo.list(salesId: salesId);
        } catch (_) {
          l = null;
        }
      }

      rkh.assignAll(r);
      lkh.assignAll(l ?? const <Lkh>[]);
      lkhLoaded.value = l != null;
      customers
        ..clear()
        ..addAll({for (final x in c) x.id: x});
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }
}