import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_attachment.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_update.dart';
import 'package:slamed_app/features/lkh/data/photo_capture.dart';
import 'package:slamed_app/features/lkh/domain/lkh_edit_rules.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/features/project/domain/project_status_rules.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';
import 'package:slamed_app/core/utils/date_picker.dart';

/// Argumen navigasi ke detail LKH.
class LkhDetailArgs {
  const LkhDetailArgs(this.lkh, this.judulRkh, this.customerName, {this.projectId});
  final Lkh lkh;
  final String judulRkh, customerName;

  /// Project milik RKH dari LKH ini (null bila RKH-nya tidak ditemukan).
  final int? projectId;
}

class LkhDetailController extends GetxController {
  LkhDetailController(this._repo, this._auth, this._projects);
  final LkhRepository _repo;
  final AuthController _auth;
  final ProjectRepository _projects;

  late final Rx<Lkh> lkh;
  late final String judulRkh, customerName;
  int? _projectId;

  final hasil = TextEditingController();
  final tindak = TextEditingController();
  final namaPic = TextEditingController();
  final nomorPic = TextEditingController();
  final followUp = Rxn<DateTime>();

  // Status project (dari project milik RKH).
  final project = Rxn<Project>();
  final allStatuses = <ProjectStatus>[].obs;
  final statusId = RxnInt(); // pilihan saat mengubah
  final loadingProject = true.obs;
  final projectError = RxnString();

  final attachments = <LkhAttachment>[].obs;
  final fotoBytes = Rxn<Uint8List>();
  final loadingFiles = true.obs;
  final editing = false.obs;
  final busy = false.obs; // menyimpan / mengunggah
  final capturing = false.obs; // kamera + GPS
  final error = RxnString();

  /// Lampiran dokumen yang ada (backend menyimpan satu per jenis), atau null.
  LkhAttachment? get lampiran {
    for (final a in attachments) {
      if (!a.isFoto) return a;
    }
    return null;
  }

  bool get hasFoto => attachments.any((a) => a.isFoto);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as LkhDetailArgs;
    lkh = args.lkh.obs;
    judulRkh = args.judulRkh;
    customerName = args.customerName;
    _projectId = args.projectId;
    loadFiles();
    loadProject();
  }

  @override
  void onClose() {
    hasil.dispose();
    tindak.dispose();
    namaPic.dispose();
    nomorPic.dispose();
    super.onClose();
  }

  /// Muat daftar berkas dan, jika ada foto, isinya (untuk ditampilkan).
  Future<void> loadFiles() async {
    loadingFiles.value = true;
    try {
      final list = await _repo.attachments(lkh.value.id);
      attachments.assignAll(list);
      final fotos = list.where((a) => a.isFoto).toList();
      fotoBytes.value = fotos.isEmpty ? null : await _repo.attachmentBytes(fotos.last.id);
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      loadingFiles.value = false;
    }
  }

  /// Muat project beserta daftar status aktif (untuk menampilkan dan mengubah status).
  Future<void> loadProject() async {
    final id = _projectId;
    if (id == null) {
      projectError.value = 'Project untuk LKH ini tidak ditemukan.';
      loadingProject.value = false;
      return;
    }
    loadingProject.value = true;
    projectError.value = null;
    try {
      final p = await _projects.get(id);
      final list = await _projects.statuses();
      final cur = p.statusId;
      // Status saat ini yang sudah tidak aktif tetap ditampilkan.
      if (cur != null && !list.any((s) => s.id == cur)) {
        list.add(ProjectStatus(
          id: cur,
          nama: p.statusNama ?? 'Status #$cur',
          warna: p.statusWarna,
          urutan: p.statusUrutan ?? (1 << 30),
          isActive: false,
        ));
      }
      list.sort((a, b) => a.urutan.compareTo(b.urutan));
      allStatuses.assignAll(list);
      project.value = p;
    } catch (e) {
      projectError.value = errorMessage(e);
    } finally {
      loadingProject.value = false;
    }
  }

  /// Status yang boleh dipilih: tidak boleh mundur dari status project saat ini.
  List<ProjectStatus> get statusOptions =>
      allowedStatusTargets(all: allStatuses, currentId: project.value?.statusId);

  /// Status dapat diubah hanya bila project sudah termuat dan ada pilihan selain status saat ini.
  bool get canChangeStatus => project.value != null && statusOptions.length > 1;

  LkhEditState get editState =>
      lkhEditState(lkh: lkh.value, role: _auth.role, userId: _auth.user.value?.id);

  /// false bila LKH milik sales lain.
  bool get canEdit => editState != LkhEditState.notOwner;

  Future<void> _setStatus(String status) async {
    lkh.value = await _repo.update(lkh.value.id, LkhUpdate(statusLkh: status));
  }

  /// Tombol Ubah. LKH DONE harus dikembalikan ke BELUM dulu sebelum bisa diedit.
  Future<void> requestEdit() async {
    if (busy.value || editState == LkhEditState.notOwner) return;
    if (editState == LkhEditState.needsRevert) {
      final ok = await confirmDialog(
        title: 'Kembalikan ke OPEN?',
        message: 'LKH ini sudah DONE. Agar bisa diubah, statusnya dikembalikan ke OPEN dulu. '
            'Setelah selesai mengubah, tandai DONE lagi.',
        confirmLabel: 'Kembalikan',
      );
      if (!ok) return;
      busy.value = true;
      try {
        await _setStatus(AppConstants.statusLkhNotYet);
      } catch (e) {
        showSnack(errorMessage(e));
        return;
      } finally {
        busy.value = false;
      }
    }
    startEdit();
  }

  /// Tandai DONE lagi setelah selesai mengubah (foto dokumentasi harus sudah ada).
  Future<void> markDone() async {
    if (busy.value) return;
    if (!hasFoto) {
      showSnack('Foto dokumentasi wajib ada sebelum LKH ditandai selesai.');
      return;
    }
    busy.value = true;
    var ok = false;
    try {
      await _setStatus(AppConstants.statusLkhDone);
      ok = true;
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
    }
    if (ok) {
      // Tutup halaman dulu. Snackbar yang masih tampil membuat Get.back() hanya menutup snackbar.
      Get.back();
      showSnack('LKH ditandai selesai.');
    }
  }

  void startEdit() {
    final l = lkh.value;
    hasil.text = l.hasilKunjungan;
    tindak.text = l.tindakLanjut ?? '';
    namaPic.text = l.namaPic;
    nomorPic.text = l.nomorPic;
    followUp.value = l.tanggalFollowUp;
    statusId.value = project.value?.statusId;
    error.value = null;
    editing.value = true;
  }

  void cancelEdit() {
    error.value = null;
    editing.value = false;
  }

    Future<void> pickFollowUp(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final d = await pickDateInRange(
      context,
      initial: followUp.value,
      fallbackInitial: today.add(const Duration(days: 1)),
      first: today,
      last: today.add(const Duration(days: 365)),
    );
    if (d != null) followUp.value = d;
  }

  void clearFollowUp() => followUp.value = null;

  Future<void> save() async {
    final h = hasil.text.trim(), n = namaPic.text.trim(), p = nomorPic.text.trim();
    if (h.isEmpty || n.isEmpty || p.isEmpty) {
      error.value = 'Hasil kunjungan, nama PIC, dan nomor PIC wajib diisi.';
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      lkh.value = await _repo.update(
        lkh.value.id,
        LkhUpdate(
          hasilKunjungan: h,
          tindakLanjut: tindak.text.trim(),
          tanggalFollowUp: followUp.value,
          namaPic: n,
          nomorPic: p,
        ),
      );
      // Status project hanya dikirim bila berubah dari status saat ini.
      final target = statusId.value;
      final pid = _projectId;
      if (pid != null && target != null && target != project.value?.statusId) {
        try {
          project.value = await _projects.updateStatus(pid, target);
        } catch (e) {
          error.value = 'LKH sudah tersimpan, tetapi status project gagal diubah: ${errorMessage(e)}';
          return; // tetap di mode ubah agar bisa dicoba lagi
        }
      }
      editing.value = false;
      showSnack('LKH diperbarui.');
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      busy.value = false;
    }
  }

  /// Ambil foto dokumentasi (baru atau pengganti). Server menandai LKH DONE saat foto terkirim.
  Future<void> changePhoto() async {
    if (busy.value || capturing.value) return;
    if (hasFoto) {
      final ok = await confirmDialog(
        title: 'Ambil ulang foto?',
        message: 'Foto dokumentasi yang lama akan diganti dengan foto baru.',
        confirmLabel: 'Ambil foto',
      );
      if (!ok) return;
    }
    capturing.value = true;
    try {
      final r = await PhotoCapture.take(label: 'RKH #${lkh.value.rkhId}');
      if (r.error != null) {
        showSnack(r.error!);
        return;
      }
      if (!r.isOk) return; // dibatalkan
      busy.value = true;
      await _repo.uploadAttachment(lkh.value.id, r.file!.path, jenis: AppConstants.jenisFoto);
      try {
        // Lokasi LKH disamakan dengan lokasi foto; kegagalannya tidak membatalkan unggahan.
        await _repo.update(lkh.value.id, LkhUpdate(latitude: r.position!.latitude, longitude: r.position!.longitude));
      } catch (_) {}
      lkh.value = await _repo.get(lkh.value.id);
      await loadFiles();
      showSnack('Foto terkirim.');
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
      capturing.value = false;
    }
  }

  /// Unggah lampiran dokumen (PDF/Word/Excel). Lampiran lama diganti oleh server.
  Future<void> changeLampiran() async {
    if (busy.value || capturing.value) return;
    try {
      final r = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.ekstensiLampiran,
        allowMultiple: false,
      );
      if (r == null || r.files.isEmpty) return;
      final f = r.files.single;
      if (f.path == null) {
        showSnack('File tidak dapat diakses. Pilih file dari penyimpanan perangkat.');
        return;
      }
      if (f.size > AppConstants.maxLampiranBytes) {
        showSnack('Ukuran lampiran melebihi 5 MB.');
        return;
      }
      final lama = lampiran;
      if (lama != null) {
        final ok = await confirmDialog(
          title: 'Ganti lampiran?',
          message: 'Lampiran lama (${lama.namaFile}) akan diganti.',
          confirmLabel: 'Ganti',
        );
        if (!ok) return;
      }
      busy.value = true;
      await _repo.uploadAttachment(lkh.value.id, f.path!, jenis: AppConstants.jenisLampiran);
      await loadFiles();
      showSnack('Lampiran terkirim.');
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
    }
  }  
}