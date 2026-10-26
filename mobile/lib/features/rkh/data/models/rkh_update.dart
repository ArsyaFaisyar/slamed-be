import 'package:slamed_app/core/utils/date_format.dart';

/// Isi `PATCH /rkh/{id}`: hanya field yang diisi yang dikirim.
class RkhUpdate {
  RkhUpdate({
    this.tanggalPelaksanaan,
    this.judulKegiatan,
    this.rencanaKegiatan,
    this.tipeAktivitas,
    this.estimasiBiayaHarian,
  });

  final DateTime? tanggalPelaksanaan;
  final String? judulKegiatan, rencanaKegiatan, tipeAktivitas, estimasiBiayaHarian;

  Map<String, dynamic> toJson() => {
        if (tanggalPelaksanaan != null) 'tanggal_pelaksanaan': toApiDate(tanggalPelaksanaan!),
        if (judulKegiatan != null) 'judul_kegiatan': judulKegiatan,
        if (rencanaKegiatan != null) 'rencana_kegiatan': rencanaKegiatan,
        if (tipeAktivitas != null) 'tipe_aktivitas': tipeAktivitas,
        if (estimasiBiayaHarian != null) 'estimasi_biaya_harian': estimasiBiayaHarian,
      };
}