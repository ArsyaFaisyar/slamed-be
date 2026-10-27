import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/utils/color_utils.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

/// Satu pil filter: nama status, jumlah project, urutan tampil, dan warnanya.
class ProspectStatusGroup {
  const ProspectStatusGroup(this.nama, this.count, this.urutan, this.color);
  final String nama;
  final int count, urutan;
  final Color? color;
}

class ProspectController extends GetxController {
  ProspectController(this._projectRepo, this._customerRepo);
  final ProjectRepository _projectRepo;
  final CustomerRepository _customerRepo;

  static const noStatus = 'Tanpa status';

  final loading = true.obs;
  final error = RxnString();
  final projects = <Project>[].obs;
  final customers = <int, Customer>{}.obs;

  /// Nama status yang dipilih sebagai filter; null = semua.
  final selected = RxnString();

  /// Nomor permintaan terakhir; hasil dari permintaan lama diabaikan.
  int _seq = 0;

  String customerName(int id) => customers[id]?.namaInstansi ?? 'Customer #$id';

  /// Nama status project (dari `status_rel`), atau "Tanpa status".
  String statusOf(Project p) {
    final s = p.statusNama?.trim();
    return (s == null || s.isEmpty) ? noStatus : s;
  }

  /// Warna status dari backend; null jika kosong atau bukan format hex.
  Color? statusColor(Project p) => parseHexColor(p.statusWarna);

  /// Pil filter, urut menurut `urutan` status (yang tidak punya urutan di akhir).
  List<ProspectStatusGroup> get statusGroups {
    final byName = <String, ProspectStatusGroup>{};
    for (final p in projects) {
      final n = statusOf(p);
      final prev = byName[n];
      byName[n] = ProspectStatusGroup(
        n,
        (prev?.count ?? 0) + 1,
        p.statusUrutan ?? (1 << 30),
        prev?.color ?? statusColor(p),
      );
    }
    return byName.values.toList()
      ..sort((a, b) {
        final c = a.urutan.compareTo(b.urutan);
        return c != 0 ? c : a.nama.compareTo(b.nama);
      });
  }

  List<Project> get visible =>
      selected.value == null ? projects.toList() : projects.where((p) => statusOf(p) == selected.value).toList();

  /// Ketuk status yang sama lagi untuk kembali ke "Semua".
  void select(String? status) => selected.value = selected.value == status ? null : status;

  Future<void> load() async {
    final seq = ++_seq;
    loading.value = true;
    error.value = null;
    try {
      final p = await _projectRepo.list();
      final c = await _customerRepo.list();
      if (seq != _seq) return; // sudah ada permintaan yang lebih baru
      p.sort((a, b) => b.id.compareTo(a.id));
      projects.assignAll(p);
      customers
        ..clear()
        ..addAll({for (final x in c) x.id: x});
      if (selected.value != null && !p.any((e) => statusOf(e) == selected.value)) {
        selected.value = null;
      }
    } catch (e, st) {
      debugPrint('[PROSPEK] load gagal: $e');
      debugPrintStack(stackTrace: st, maxFrames: 6);
      if (seq != _seq) return;
      // Layar error penuh hanya bila belum ada data; jika sudah ada, daftar dipertahankan.
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