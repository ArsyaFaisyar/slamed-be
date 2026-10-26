import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_attachment.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_update.dart';
import 'package:slamed_app/features/lkh/data/photo_capture.dart';
import 'package:slamed_app/shared/helpers/confirm.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

/// Argumen navigasi ke detail LKH.
class LkhDetailArgs {
  const LkhDetailArgs(this.lkh, this.judulRkh, this.customerName);
  final Lkh lkh;
  final String judulRkh, customerName;
}

class LkhDetailController extends GetxController {
  LkhDetailController(this._repo);
  final LkhRepository _repo;

  late final Rx<Lkh> lkh;
  late final String judulRkh, customerName;

  final hasil = TextEditingController();
  final tindak = TextEditingController();
  final namaPic = TextEditingController();
  final nomorPic = TextEditingController();

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
    loadFiles();
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

  void startEdit() {
    final l = lkh.value;
    hasil.text = l.hasilKunjungan;
    tindak.text = l.tindakLanjut ?? '';
    namaPic.text = l.namaPic;
    nomorPic.text = l.nomorPic;
    error.value = null;
    editing.value = true;
  }

  void cancelEdit() {
    error.value = null;
    editing.value = false;
  }

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
        LkhUpdate(hasilKunjungan: h, tindakLanjut: tindak.text.trim(), namaPic: n, nomorPic: p),
      );
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

  /// Hapus LKH (hanya yang masih BELUM); RKH-nya kembali ke daftar "Perlu LKH".
  Future<void> remove() async {
    final ok = await confirmDialog(
      title: 'Hapus LKH?',
      message: 'LKH ini akan dihapus permanen dan RKH-nya kembali menunggu LKH.',
    );
    if (!ok) return;
    busy.value = true;
    try {
      await _repo.delete(lkh.value.id);
      showSnack('LKH dihapus.');
      Get.back();
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      busy.value = false;
    }
  }
}