import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/customer/presentation/widgets/reject_dialog.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

enum CustomerFilter { semua, menunggu, disetujui, ditolak }

class CustomerController extends GetxController {
  CustomerController(this._repo, this._auth);
  final CustomerRepository _repo;
  final AuthController _auth;

  final loading = true.obs;
  final error = RxnString();
  final customers = <Customer>[].obs;

  // Pencarian dan filter (disimpan di controller, jadi bertahan saat pindah tab).
  final query = ''.obs;

  /// Penyetuju langsung melihat pengajuan yang menunggu; Sales melihat semua.
  late final filter = (canApprove ? CustomerFilter.menunggu : CustomerFilter.semua).obs;

  /// Id customer yang sedang disetujui/ditolak (mengunci tombolnya).
  final busyId = RxnInt();

  /// Sales mengajukan customer baru (server menetapkan sales dan areanya).
  bool get canCreate => _auth.role == Roles.sales;

  /// SPV dan SUPERADMIN menyetujui atau menolak pengajuan.
  bool get canApprove => _auth.role == Roles.spv || _auth.role == Roles.superadmin;

  /// Sales boleh memperbaiki pengajuannya selama belum disetujui (server menolak sisanya).
  bool canEdit(Customer x) => _auth.role == Roles.sales && !x.isApproved;

  static String _lc(String? s) => (s ?? '').toLowerCase();

  /// Customer yang lolos kata kunci (belum disaring status).
  List<Customer> get _base {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return customers.toList();
    return customers
        .where((c) =>
            _lc(c.namaInstansi).contains(q) ||
            _lc(c.namaPic).contains(q) ||
            _lc(c.kontakPic).contains(q) ||
            _lc(c.kota).contains(q) ||
            _lc(c.kategori).contains(q) ||
            _lc(c.salesNama).contains(q) ||
            _lc(c.areaNama).contains(q))
        .toList();
  }

  bool _is(Customer c, CustomerFilter f) => switch (f) {
        CustomerFilter.semua => true,
        CustomerFilter.menunggu => c.isPending,
        CustomerFilter.disetujui => c.isApproved,
        CustomerFilter.ditolak => c.isRejected,
      };

  /// Jumlah untuk satu pilihan filter, mengikuti kata kunci.
  int countOf(CustomerFilter f) => _base.where((c) => _is(c, f)).length;

  /// Daftar yang ditampilkan.
  List<Customer> get visible => _base.where((c) => _is(c, filter.value)).toList();

  bool get filtering => query.value.trim().isNotEmpty || filter.value != CustomerFilter.semua;

  void resetFilters() {
    query.value = '';
    filter.value = CustomerFilter.semua;
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _repo.list();
      list.sort((a, b) => b.id.compareTo(a.id));
      customers.assignAll(list);
    } catch (e) {
      // Layar error penuh hanya bila belum ada data; jika sudah ada, daftar dipertahankan.
      if (customers.isEmpty) {
        error.value = errorMessage(e);
      } else {
        showSnack(errorMessage(e));
      }
    } finally {
      loading.value = false;
    }
  }

  void _replace(Customer updated) {
    final i = customers.indexWhere((c) => c.id == updated.id);
    if (i >= 0) customers[i] = updated;
  }

  Future<void> approve(Customer x) async {
    if (busyId.value != null) return;
    final ok = await confirmDialog(
      title: 'Setujui customer?',
      message: '"${x.namaInstansi}" akan disetujui dan bisa dipakai untuk RKH.',
      confirmLabel: 'Setujui',
    );
    if (!ok) return;
    busyId.value = x.id;
    try {
      _replace(await _repo.approve(x.id));
      showSnack('Customer disetujui.');
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busyId.value = null;
    }
  }

  Future<void> reject(Customer x) async {
    if (busyId.value != null) return;
    final alasan = await askRejectionReason(x.namaInstansi);
    if (alasan == null) return;
    busyId.value = x.id;
    try {
      _replace(await _repo.reject(x.id, alasan));
      showSnack('Pengajuan ditolak.');
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busyId.value = null;
    }
  }

  /// Ajukan customer baru.
  Future<void> openForm() async {
    // Tanpa generik: Get.toNamed<bool> memicu cast GetPageRoute -> Route<bool?> yang gagal.
    final ok = await Get.toNamed(AppRoutes.customerForm);
    if (ok == true) load();
  }

  /// Perbaiki pengajuan (Sales). Setelah disimpan, statusnya kembali menunggu.
  Future<void> openEdit(Customer x) async {
    final ok = await Get.toNamed(AppRoutes.customerForm, arguments: x);
    if (ok == true) load();
  }
}