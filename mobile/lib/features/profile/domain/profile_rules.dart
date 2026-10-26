import 'package:slamed_app/core/constants/app_constant.dart';

/// Format foto yang diterima backend, beserta tipe konten dan ekstensinya.
enum ImageKind {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  webp('image/webp', 'webp');

  const ImageKind(this.mime, this.ext);
  final String mime, ext;
}

/// Mendeteksi format dari isi file (byte awal), bukan dari ekstensi nama file.
ImageKind? sniffImage(List<int> b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return ImageKind.jpeg;
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return ImageKind.png;
  }
  // WEBP: "RIFF" ???? "WEBP"
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return ImageKind.webp;
  }
  return null;
}

/// HEIC/HEIF (umum pada kamera sebagian HP) tidak didukung backend.
bool isHeic(List<int> b) {
  if (b.length < 12) return false;
  if (String.fromCharCodes(b.sublist(4, 8)) != 'ftyp') return false;
  const brands = {'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'};
  return brands.contains(String.fromCharCodes(b.sublist(8, 12)).toLowerCase());
}

/// Validasi ubah password. Mengembalikan pesan error, atau null bila valid.
String? validatePasswordChange({required String lama, required String baru, required String konfirmasi}) {
  if (lama.isEmpty || baru.isEmpty || konfirmasi.isEmpty) return 'Lengkapi semua kolom.';
  if (baru.length < AppConstants.minPasswordLength) {
    return 'Password baru minimal ${AppConstants.minPasswordLength} karakter.';
  }
  if (baru != konfirmasi) return 'Konfirmasi password tidak sama.';
  if (baru == lama) return 'Password baru harus berbeda dari password lama.';
  return null;
}

/// Validasi foto profil dari isinya (format dan ukuran). Null bila valid.
String? validateProfilePhoto(List<int> bytes) {
  if (bytes.isEmpty) return 'File foto kosong.';
  if (sniffImage(bytes) == null) {
    return isHeic(bytes)
        ? 'Foto berformat HEIC tidak didukung. Ambil foto langsung dengan kamera, atau pilih foto JPG atau PNG.'
        : 'Format foto harus JPG, PNG, atau WEBP.';
  }
  if (bytes.length > AppConstants.maxFotoProfilBytes) return 'Ukuran foto melebihi 5 MB.';
  return null;
}