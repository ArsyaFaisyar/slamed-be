import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
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

/// Bahan untuk mencetak stempel waktu/lokasi di foto (dijalankan di isolate).
class _StampJob {
  const _StampJob(this.bytes, this.lines);
  final Uint8List bytes;
  final List<String> lines;
}

/// Mencetak [lines] pada bilah gelap di bawah foto, lalu mengembalikan JPEG.
Uint8List _stampPhoto(_StampJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) throw const FormatException('Foto tidak dapat dibaca');
  var image = img.bakeOrientation(decoded);
  if (image.width > 1600) image = img.copyResize(image, width: 1600);

  final font = img.arial24;
  const lineHeight = 30;
  const pad = 10;
  final boxHeight = job.lines.length * lineHeight + pad * 2;
  final top = image.height - boxHeight;

  img.fillRect(
    image,
    x1: 0,
    y1: top,
    x2: image.width,
    y2: image.height,
    color: img.ColorRgba8(0, 0, 0, 170),
  );
  for (var i = 0; i < job.lines.length; i++) {
    img.drawString(
      image,
      job.lines[i],
      font: font,
      x: pad,
      y: top + pad + i * lineHeight,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 80));
}

class LkhFormController extends GetxController {
  LkhFormController(this._repo);
  final LkhRepository _repo;

  late final Rkh rkh;
  late final String customerName;

  final hasil = TextEditingController();
  final tindak = TextEditingController();
  final namaPic = TextEditingController();
  final nomorPic = TextEditingController();
  final _picker = ImagePicker();

  final tanggal = DateTime.now().obs;
  final foto = Rxn<XFile>();
  final fotoPos = Rxn<Position>(); // lokasi saat foto diambil
  final lampiran = Rxn<PlatformFile>();
  final lampiranBytes = RxnInt(); // ukuran lampiran, ditampilkan di kartu lampiran
  final capturing = false.obs;
  final busy = false.obs;
  final error = RxnString();

  // Agar bisa mengulang unggah tanpa membuat LKH ganda.
  int? _lkhId;
  bool _fotoUploaded = false, _lampiranUploaded = false;

  static const _maxAkurasiMeter = 100.0;
  static const _maxUsiaFoto = Duration(minutes: 2);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as LkhFormArgs;
    rkh = args.rkh;
    customerName = args.customerName;
    final now = DateTime.now();
    tanggal.value = rkh.tanggalPelaksanaan.isAfter(now) ? now : rkh.tanggalPelaksanaan;
  }

  @override
  void onClose() {
    hasil.dispose();
    tindak.dispose();
    namaPic.dispose();
    nomorPic.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final last = DateTime.now();
    final first = rkh.tanggalRencana.isAfter(last) ? last : rkh.tanggalRencana;
    final d = await showDatePicker(context: context, initialDate: tanggal.value, firstDate: first, lastDate: last);
    if (d != null) tanggal.value = d;
  }

  /// Memastikan GPS aktif dan izin lokasi ada. Mengembalikan pesan error, atau null jika siap.
  Future<String?> _siapkanLokasi() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Aktifkan GPS untuk mengambil foto dokumentasi.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return 'Izin lokasi diperlukan untuk foto dokumentasi. Aktifkan di pengaturan aplikasi.';
    }
    return null;
  }

  /// Posisi segar; null bila gagal. Tidak pernah melempar error.
  Future<Position?> _ambilFix() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Foto wajib langsung dari kamera, dengan lokasi dan waktu pengambilan tercetak di gambar.
  Future<void> takePhoto() async {
    if (capturing.value) return;
    // Backend hanya menerima satu foto per LKH; yang sudah terkirim tidak bisa diganti.
    if (_fotoUploaded) {
      showSnack('Foto sudah terkirim dan tidak dapat diganti.');
      return;
    }
    capturing.value = true;
    try {
      final err = await _siapkanLokasi();
      if (err != null) {
        showSnack(err);
        return;
      }

      final fix = _ambilFix(); // berjalan bersamaan dengan kamera
      XFile? f;
      try {
        f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600);
      } on PlatformException catch (e) {
        showSnack(switch (e.code) {
          'camera_access_denied' => 'Izin kamera ditolak. Aktifkan di pengaturan aplikasi.',
          'no_available_camera' => 'Perangkat ini tidak memiliki kamera.',
          _ => 'Gagal membuka kamera.',
        });
        return;
      }
      if (f == null) return;

      // Pastikan benar-benar foto baru, bukan berkas lama.
      final umur = DateTime.now().difference(await File(f.path).lastModified());
      if (umur > _maxUsiaFoto) {
        showSnack('Foto harus diambil langsung dengan kamera.');
        return;
      }

      final p = await fix;
      if (p == null) {
        showSnack('Lokasi belum berhasil diambil. Pastikan GPS aktif, lalu ambil foto lagi (sebaiknya di tempat terbuka).');
        return;
      }
      if (p.isMocked && !kDebugMode) {
        showSnack('Lokasi palsu (mock location) terdeteksi. Matikan aplikasi lokasi palsu lalu coba lagi.');
        return;
      }
      if (p.accuracy > _maxAkurasiMeter) {
        showSnack('Akurasi GPS rendah (±${p.accuracy.round()} m). Tunggu sinyal lebih baik lalu ambil foto lagi.');
        return;
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final lines = [
        '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
        'Lat ${p.latitude.toStringAsFixed(6)}  Lng ${p.longitude.toStringAsFixed(6)}',
        'Akurasi +/- ${p.accuracy.round()} m',
        'RKH #${rkh.id}',
      ];
      final bytes = await compute(_stampPhoto, _StampJob(await f.readAsBytes(), lines));
      if (bytes.length > AppConstants.maxFotoBytes) {
        showSnack('Ukuran foto melebihi 2 MB. Ambil ulang.');
        return;
      }
      final out = File('${Directory.systemTemp.path}/lkh_${now.millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(bytes, flush: true);

      foto.value = XFile(out.path);
      fotoPos.value = p;
    } catch (_) {
      showSnack('Gagal memproses foto. Coba lagi.');
    } finally {
      capturing.value = false;
    }
  }

  Future<void> pickAttachment() async {
    if (_lampiranUploaded) {
      showSnack('Lampiran sudah terkirim dan tidak dapat diganti.');
      return;
    }
    try {
      // file_picker v11: pickFiles() static, hasilnya FilePickerResult? (null jika dibatalkan).
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
      lampiran.value = f;
      lampiranBytes.value = f.size;
    } catch (_) {
      showSnack('Gagal membuka pemilih file.');
    }
  }

  void clearAttachment() {
    if (_lampiranUploaded) return;
    lampiran.value = null;
    lampiranBytes.value = null;
  }

  /// 409 pada FOTO berarti foto sudah ada di server (mis. respons sebelumnya hilang).
  Future<void> _upload(String path, String jenis) async {
    try {
      await _repo.uploadAttachment(_lkhId!, path, jenis: jenis);
    } on ApiException catch (e) {
      if (jenis == AppConstants.jenisFoto && e.status == 409) return;
      rethrow;
    }
  }

  Future<void> submit() async {
    if (hasil.text.trim().isEmpty || namaPic.text.trim().isEmpty || nomorPic.text.trim().isEmpty) {
      error.value = 'Hasil kunjungan, nama PIC, dan nomor PIC wajib diisi.';
      return;
    }
    if (foto.value == null || fotoPos.value == null) {
      error.value = 'Foto dokumentasi wajib diambil langsung dengan kamera (lokasi tercatat otomatis).';
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
          namaPic: namaPic.text.trim(),
          nomorPic: nomorPic.text.trim(),
          tindakLanjut: tindak.text.trim().isEmpty ? null : tindak.text.trim(),
          // Lokasi LKH = lokasi saat foto diambil.
          latitude: fotoPos.value!.latitude,
          longitude: fotoPos.value!.longitude,
        ));
        _lkhId = lkh.id;
      }
      if (!_fotoUploaded) {
        await _upload(foto.value!.path, AppConstants.jenisFoto);
        _fotoUploaded = true;
      }
      final l = lampiran.value;
      if (l != null && !_lampiranUploaded) {
        await _upload(l.path!, AppConstants.jenisLampiran);
        _lampiranUploaded = true;
      }
      Get.back<bool>(result: true);
    } catch (e) {
      error.value = _lkhId == null
          ? errorMessage(e)
          : 'LKH sudah tersimpan, tetapi unggah file gagal: ${errorMessage(e)}\n'
              'Tekan "Kirim LKH" lagi untuk mengulang. Jika lampiran terus gagal, hapus lampiran lalu kirim lagi.';
    } finally {
      busy.value = false;
    }
  }
}