import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_create.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

/// Argumen navigasi ke form LKH.
class LkhFormArgs {
  const LkhFormArgs(this.rkh, this.customerName);
  final Rkh rkh;
  final String customerName;
}

class LkhFormController extends GetxController {
  LkhFormController(this._repo);
  final LkhRepository _repo;

  late final Rkh rkh;
  late final String customerName;

  final hasil = TextEditingController();
  final tindak = TextEditingController();
  final _picker = ImagePicker();

  final tanggal = DateTime.now().obs;
  final status = RxnString();
  final pos = Rxn<Position>();
  final foto = Rxn<XFile>();
  final lampiran = Rxn<XFile>();
  final locating = false.obs;
  final busy = false.obs;
  final error = RxnString();

  // Agar bisa mengulang unggah tanpa membuat LKH ganda.
  int? _lkhId;
  bool _fotoUploaded = false, _lampiranUploaded = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as LkhFormArgs;
    rkh = args.rkh;
    customerName = args.customerName;
    final now = DateTime.now();
    tanggal.value = rkh.tanggalPelaksanaan.isAfter(now) ? now : rkh.tanggalPelaksanaan;
    locate(silent: true); // laporan langsung di lokasi
  }

  @override
  void onClose() {
    hasil.dispose();
    tindak.dispose();
    super.onClose();
  }

  void setStatus(Set<String> s) => status.value = s.isEmpty ? null : s.first;

  Future<void> locate({bool silent = false}) async {
    locating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'GPS tidak aktif.';
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw 'Izin lokasi ditolak.';
      pos.value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
    } catch (e) {
      if (!silent) showSnack(e is String ? e : 'Gagal mengambil lokasi.');
    } finally {
      locating.value = false;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final last = DateTime.now();
    final first = rkh.tanggalRencana.isAfter(last) ? last : rkh.tanggalRencana;
    final d = await showDatePicker(context: context, initialDate: tanggal.value, firstDate: first, lastDate: last);
    if (d != null) tanggal.value = d;
  }

  Future<void> takePhoto() async {
    final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1920);
    if (f != null) {
      foto.value = f;
      _fotoUploaded = false;
    }
  }

  Future<void> pickAttachment() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1920);
    if (f != null) {
      lampiran.value = f;
      _lampiranUploaded = false;
    }
  }

  Future<void> submit() async {
    if (hasil.text.trim().isEmpty) {
      error.value = 'Hasil kunjungan wajib diisi.';
      return;
    }
    if (foto.value == null) {
      // Wajib menurut deck; backend tidak memaksanya, jadi dicek di app.
      error.value = 'Foto dokumentasi wajib dilampirkan.';
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      if (_lkhId == null) {
        final lkh = await _repo.create(LkhCreate(
          rkhId: rkh.id,
          tanggalKunjungan: tanggal.value,
          hasilKunjungan: hasil.text.trim(),
          statusProspek: status.value,
          tindakLanjut: tindak.text.trim().isEmpty ? null : tindak.text.trim(),
          latitude: pos.value?.latitude,
          longitude: pos.value?.longitude,
        ));
        _lkhId = lkh.id;
      }
      if (!_fotoUploaded) {
        await _repo.uploadAttachment(_lkhId!, foto.value!.path);
        _fotoUploaded = true;
      }
      if (lampiran.value != null && !_lampiranUploaded) {
        await _repo.uploadAttachment(_lkhId!, lampiran.value!.path);
        _lampiranUploaded = true;
      }
      Get.back<bool>(result: true);
    } catch (e) {
      error.value = _lkhId == null
          ? errorMessage(e)
          : 'LKH sudah tersimpan, tetapi unggah file gagal: ${errorMessage(e)}\nTekan "Kirim LKH" lagi untuk mengulang unggah.';
    } finally {
      busy.value = false;
    }
  }
}