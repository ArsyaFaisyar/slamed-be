import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
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

  /// Selesai = status CLOSED (diisi backend saat LKH dibuat) atau sudah punya
  /// LKH (hanya bila data LKH dimuat). Status DRAFT/OPEN dihitung terbuka.
  bool isDone(Rkh r) => r.status.toUpperCase() == 'CLOSED' || withLkh.contains(r.id);

  int get doneCount => rkh.where(isDone).length;

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  Future<void> load() async {
    final salesId = _auth.role == Roles.sales ? _auth.user.value!.id : null;
    loading.value = true;
    error.value = null;
    try {
      // Berurutan (bukan Future.wait) agar ApiException asli tetap terbaca.
      final r = await _rkhRepo.list(salesId: salesId);
      final c = await _customerRepo.list();

      // LKH opsional: dimatikan atau gagal tidak boleh merusak daftar RKH.
      var l = const <Lkh>[];
      if (AppConstants.lkhEnabled) {
        try {
          l = await _lkhRepo.list(salesId: salesId);
        } catch (_) {
          l = const <Lkh>[];
        }
      }

      r.sort((a, b) => b.tanggalPelaksanaan.compareTo(a.tanggalPelaksanaan));
      rkh.assignAll(r);
      withLkh
        ..clear()
        ..addAll(l.map((e) => e.rkhId));
      customers
        ..clear()
        ..addAll({for (final x in c) x.id: x});
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
}