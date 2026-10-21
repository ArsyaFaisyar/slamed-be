import 'package:slamed_app/core/utils/date_format.dart';

/// `sales_id` sengaja tidak ada: backend menurunkannya dari user yang login.
class RkhCreate {
  RkhCreate({
    required this.customerId,
    required this.projectId,
    required this.tanggalRencana,
    required this.tanggalPelaksanaan,
    required this.judulKegiatan,
    required this.rencanaKegiatan,
    required this.tipeAktivitas,
    this.estimasiBiayaHarian = '0',
  });

  final int customerId, projectId;
  final DateTime tanggalRencana, tanggalPelaksanaan;
  final String judulKegiatan, rencanaKegiatan, tipeAktivitas, estimasiBiayaHarian;

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'project_id': projectId,
        'tanggal_rencana': toApiDate(tanggalRencana),
        'tanggal_pelaksanaan': toApiDate(tanggalPelaksanaan),
        'judul_kegiatan': judulKegiatan,
        'rencana_kegiatan': rencanaKegiatan,
        'tipe_aktivitas': tipeAktivitas,
        'estimasi_biaya_harian': estimasiBiayaHarian,
      };
}