import 'package:get/get.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';

class ProspectController extends GetxController {
  ProspectController(this._projectRepo, this._customerRepo);
  final ProjectRepository _projectRepo;
  final CustomerRepository _customerRepo;

  final loading = true.obs;
  final error = RxnString();
  final projects = <Project>[].obs;
  final customers = <int, Customer>{}.obs;

  /// Status yang dipilih sebagai filter; null = semua.
  final selected = RxnString();

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  /// Jumlah project per status, urut dari yang terbanyak. Nilai status berasal
  /// dari data backend (teks bebas), bukan daftar tetap di app.
  List<MapEntry<String, int>> get statusCounts {
    final m = <String, int>{};
    for (final p in projects) {
      m[p.status] = (m[p.status] ?? 0) + 1;
    }
    return m.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
  }

  List<Project> get visible => selected.value == null
      ? projects.toList()
      : projects.where((p) => p.status == selected.value).toList();

  /// Ketuk status yang sama lagi untuk kembali ke "Semua".
  void select(String? status) => selected.value = selected.value == status ? null : status;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final p = await _projectRepo.list();
      final c = await _customerRepo.list();
      p.sort((a, b) => b.id.compareTo(a.id));
      projects.assignAll(p);
      customers
        ..clear()
        ..addAll({for (final x in c) x.id: x});
      if (selected.value != null && !p.any((e) => e.status == selected.value)) selected.value = null;
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }
}