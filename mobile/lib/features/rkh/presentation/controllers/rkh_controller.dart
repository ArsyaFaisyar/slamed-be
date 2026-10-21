import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';

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

  int get doneCount => rkh.where((r) => withLkh.contains(r.id)).length;

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

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
    final ok = await Get.toNamed<bool>(AppRoutes.rkhForm);
    if (ok == true) load();
  }
}