class Rkh {
  Rkh({
    required this.id,
    required this.salesId,
    required this.customerId,
    required this.projectId,
    required this.tanggalRencana,
    required this.tanggalPelaksanaan,
    required this.judulKegiatan,
    required this.rencanaKegiatan,
    required this.tipeAktivitas,
    required this.estimasiBiayaHarian,
    required this.status,
  });

  final int id, salesId, customerId, projectId;
  final DateTime tanggalRencana, tanggalPelaksanaan;
  final String judulKegiatan, rencanaKegiatan, tipeAktivitas, estimasiBiayaHarian, status;

  factory Rkh.fromJson(Map<String, dynamic> j) => Rkh(
        id: j['id'] as int,
        salesId: j['sales_id'] as int,
        customerId: j['customer_id'] as int,
        projectId: j['project_id'] as int,
        tanggalRencana: DateTime.parse(j['tanggal_rencana'] as String),
        tanggalPelaksanaan: DateTime.parse(j['tanggal_pelaksanaan'] as String),
        judulKegiatan: j['judul_kegiatan'] as String,
        rencanaKegiatan: j['rencana_kegiatan'] as String,
        tipeAktivitas: j['tipe_aktivitas'] as String,
        estimasiBiayaHarian: j['estimasi_biaya_harian'].toString(),
        status: j['status'] as String,
      );
}