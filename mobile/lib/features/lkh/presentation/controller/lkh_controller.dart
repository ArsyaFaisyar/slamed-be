import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_form_controller.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';

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

  /// RKH yang belum punya LKH, urut dari jadwal terdekat.
  List<Rkh> get pending {
    final filled = lkh.map((e) => e.rkhId).toSet();
    return rkh.where((r) => !filled.contains(r.id)).toList()
      ..sort((a, b) => a.tanggalPelaksanaan.compareTo(b.tanggalPelaksanaan));
  }

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

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
    // Tanpa generik: Get.toNamed<bool> memicu cast GetPageRoute -> Route<bool?> yang gagal.
    final ok = await Get.toNamed(
      AppRoutes.lkhForm,
      arguments: LkhFormArgs(r, customerName(r.customerId)),
    );
    if (ok == true) load();
  }
}