import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/constants/app_constant.dart';

/// Hasil [PhotoCapture.take]: berhasil (file + lokasi), dibatalkan, atau gagal (pesan untuk pengguna).
class PhotoCaptureResult {
  const PhotoCaptureResult.ok(this.file, this.position) : error = null;
  const PhotoCaptureResult.failed(this.error)
      : file = null,
        position = null;
  const PhotoCaptureResult.cancelled()
      : file = null,
        position = null,
        error = null;

  final XFile? file;
  final Position? position;
  final String? error;

  bool get isOk => file != null && position != null;
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

/// Foto langsung dari kamera + lokasi saat itu, dengan waktu dan koordinat tercetak di gambar.
abstract final class PhotoCapture {
  static final _picker = ImagePicker();
  static const _maxAkurasiMeter = 100.0;
  static const _maxUsiaFoto = Duration(minutes: 2);

  /// Memastikan GPS aktif dan izin lokasi ada. Mengembalikan pesan error, atau null jika siap.
  static Future<String?> _siapkanLokasi() async {
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
  static Future<Position?> _ambilFix() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
      );
    } catch (_) {
      return null;
    }
  }

  /// [label] ikut dicetak di foto (mis. "RKH #12").
  static Future<PhotoCaptureResult> take({required String label}) async {
    try {
      final err = await _siapkanLokasi();
      if (err != null) return PhotoCaptureResult.failed(err);

      final fix = _ambilFix(); // berjalan bersamaan dengan kamera
      XFile? f;
      try {
        f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600);
      } on PlatformException catch (e) {
        return PhotoCaptureResult.failed(switch (e.code) {
          'camera_access_denied' => 'Izin kamera ditolak. Aktifkan di pengaturan aplikasi.',
          'no_available_camera' => 'Perangkat ini tidak memiliki kamera.',
          _ => 'Gagal membuka kamera.',
        });
      }
      if (f == null) return const PhotoCaptureResult.cancelled();

      // Pastikan benar-benar foto baru, bukan berkas lama.
      final umur = DateTime.now().difference(await File(f.path).lastModified());
      if (umur > _maxUsiaFoto) {
        return const PhotoCaptureResult.failed('Foto harus diambil langsung dengan kamera.');
      }

      final p = await fix;
      if (p == null) {
        return const PhotoCaptureResult.failed(
            'Lokasi belum berhasil diambil. Pastikan GPS aktif, lalu ambil foto lagi (sebaiknya di tempat terbuka).');
      }
      if (p.isMocked && !kDebugMode) {
        return const PhotoCaptureResult.failed('Lokasi palsu (mock location) terdeteksi. Matikan aplikasi lokasi palsu lalu coba lagi.');
      }
      if (p.accuracy > _maxAkurasiMeter) {
        return PhotoCaptureResult.failed('Akurasi GPS rendah (±${p.accuracy.round()} m). Tunggu sinyal lebih baik lalu ambil foto lagi.');
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final lines = [
        '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
        'Lat ${p.latitude.toStringAsFixed(6)}  Lng ${p.longitude.toStringAsFixed(6)}',
        'Akurasi +/- ${p.accuracy.round()} m',
        label,
      ];
      final bytes = await compute(_stampPhoto, _StampJob(await f.readAsBytes(), lines));
      if (bytes.length > AppConstants.maxFotoBytes) {
        return const PhotoCaptureResult.failed('Ukuran foto melebihi 2 MB. Ambil ulang.');
      }
      final out = File('${Directory.systemTemp.path}/lkh_${now.millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(bytes, flush: true);
      return PhotoCaptureResult.ok(XFile(out.path), p);
    } catch (_) {
      return const PhotoCaptureResult.failed('Gagal memproses foto. Coba lagi.');
    }
  }
}