class Lkh {
  Lkh({
    required this.id,
    required this.rkhId,
    required this.salesId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    required this.namaPic,
    required this.nomorPic,
    required this.statusLkh,
    this.tindakLanjut,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final int id, rkhId, salesId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan, namaPic, nomorPic, statusLkh;
  final String? tindakLanjut;
  final double? latitude, longitude;
  final DateTime? createdAt;

  /// `DONE` otomatis diset backend saat foto kunjungan terunggah.
  bool get isDone => statusLkh.toUpperCase() == 'DONE';

  factory Lkh.fromJson(Map<String, dynamic> j) => Lkh(
        id: (j['id'] as num).toInt(),
        rkhId: (j['rkh_id'] as num).toInt(),
        salesId: (j['sales_id'] as num).toInt(),
        tanggalKunjungan: DateTime.parse(j['tanggal_kunjungan'] as String),
        hasilKunjungan: (j['hasil_kunjungan'] ?? '').toString(),
        namaPic: (j['nama_pic'] ?? '').toString(),
        nomorPic: (j['nomor_pic'] ?? '').toString(),
        statusLkh: (j['status_lkh'] ?? 'NOT_YET').toString(),
        tindakLanjut: j['tindak_lanjut'] as String?,
        // Backend bisa mengirim bilangan bulat (mis. 20), jadi lewat num.
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}