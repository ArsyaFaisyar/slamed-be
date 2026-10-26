/// Nilai di bawah belum didefinisikan backend (field berupa teks bebas).
/// Ubah di sini jika bisnis/backend menetapkan daftar resmi.
abstract final class AppConstants {
  /// Aturan mockup: jadwal pelaksanaan RKH maksimal 7 hari ke depan.
  static const maxHariKeDepan = 7;

  /// Saran tipe aktivitas RKH. Backend menerima "Kunjungan"; lainnya belum diuji.
  static const tipeAktivitasSaran = ['Kunjungan', 'Follow-up', 'Presentasi', 'Demo Produk'];

  static const statusProspek = ['DONE', 'LOSE'];
  static const statusLkhDone = 'DONE';
  static const statusLkhNotYet = 'NOT_YET';

  /// Nilai field form `jenis` pada unggahan lampiran LKH (sesuai backend).
  static const jenisFoto = 'FOTO';
  static const jenisLampiran = 'LAMPIRAN';

  /// Batas ukuran berkas menurut backend: foto 2 MB, lampiran 5 MB.
  static const maxFotoBytes = 2 * 1024 * 1024;
  static const maxLampiranBytes = 5 * 1024 * 1024;

  /// Ekstensi lampiran yang diterima backend: PDF, Word, Excel.
  static const ekstensiLampiran = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];

  static const lkhEnabled = true;

    /// Foto profil menurut panduan API: JPG/PNG/WEBP, maks. 5 MB.
  static const maxFotoProfilBytes = 5 * 1024 * 1024;
  static const ekstensiFotoProfil = ['jpg', 'jpeg', 'png', 'webp'];

  /// ChangePasswordRequest.password_baru minimal 6 karakter.
  static const minPasswordLength = 6;
}