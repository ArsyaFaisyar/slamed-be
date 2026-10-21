class Lkh {
  Lkh({
    required this.id,
    required this.rkhId,
    required this.salesId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    this.statusProspek,
    this.tindakLanjut,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final int id, rkhId, salesId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan;
  final String? statusProspek, tindakLanjut;
  final double? latitude, longitude;
  final DateTime? createdAt;

  factory Lkh.fromJson(Map<String, dynamic> j) => Lkh(
        id: j['id'] as int,
        rkhId: j['rkh_id'] as int,
        salesId: j['sales_id'] as int,
        tanggalKunjungan: DateTime.parse(j['tanggal_kunjungan'] as String),
        hasilKunjungan: j['hasil_kunjungan'] as String,
        statusProspek: j['status_prospek'] as String?,
        tindakLanjut: j['tindak_lanjut'] as String?,
        // Backend bisa mengirim bilangan bulat (mis. 20), jadi lewat num.
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}