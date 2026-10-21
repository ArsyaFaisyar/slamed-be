import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

class ProspectController extends GetxController {
  ProspectController(this._projectRepo, this._customerRepo);
  final ProjectRepository _projectRepo;
  final CustomerRepository _customerRepo;

  final loading = true.obs;
  final error = RxnString();
  final projects = <Project>[].obs;
  final customers = <int, Customer>{}.obs;

  /// Status (sudah dinormalisasi) yang dipilih sebagai filter; null = semua.
  final selected = RxnString();

  /// Nomor permintaan terakhir; hasil dari permintaan lama diabaikan.
  int _seq = 0;

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  /// Status seragam (trim + uppercase) agar "Done" dan "DONE" tidak terpecah.
  String statusOf(Project p) {
    final s = p.status.trim().toUpperCase();
    return s.isEmpty ? 'TANPA STATUS' : s;
  }

  List<MapEntry<String, int>> get statusCounts {
    final m = <String, int>{};
    for (final p in projects) {
      final s = statusOf(p);
      m[s] = (m[s] ?? 0) + 1;
    }
    return m.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
  }

  List<Project> get visible => selected.value == null
      ? projects.toList()
      : projects.where((p) => statusOf(p) == selected.value).toList();

  /// Ketuk status yang sama lagi untuk kembali ke "Semua".
  void select(String? status) => selected.value = selected.value == status ? null : status;

  Future<void> load() async {
    final seq = ++_seq;
    loading.value = true;
    error.value = null;
    try {
      final p = await _projectRepo.list();
      final c = await _customerRepo.list();
      if (seq != _seq) return;
      p.sort((a, b) => b.id.compareTo(a.id));
      projects.assignAll(p);
      customers
        ..clear()
        ..addAll({for (final x in c) x.id: x});
      if (selected.value != null && !p.any((e) => statusOf(e) == selected.value)) {
        selected.value = null;
      }
    } catch (e, st) {
      // Cetak error asli (mis. TypeError saat parsing) agar penyebabnya terlihat.
      debugPrint('[PROSPEK] load gagal: $e');
      debugPrintStack(stackTrace: st, maxFrames: 6);
      if (seq != _seq) return;
      if (projects.isEmpty) {
        error.value = errorMessage(e);
      } else {
        showSnack(errorMessage(e));
      }
    } finally {
      if (seq == _seq) loading.value = false;
    }
  }
}