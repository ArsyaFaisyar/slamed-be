/// Nilai di bawah belum didefinisikan backend (field berupa teks bebas).
/// Ubah di sini jika bisnis/backend menetapkan daftar resmi.
abstract final class AppConstants {
  /// Aturan mockup: jadwal pelaksanaan RKH maksimal 7 hari ke depan.
  static const maxHariKeDepan = 7;

  /// Saran tipe aktivitas RKH. Backend menerima "Kunjungan"; lainnya belum diuji.
  static const tipeAktivitasSaran = ['Kunjungan', 'Follow-up', 'Presentasi', 'Demo Produk'];

  /// Status prospek di LKH (skema Done/Lose dari deck). "DONE" teruji; "LOSE" belum.
  static const statusProspek = ['DONE', 'LOSE'];
}