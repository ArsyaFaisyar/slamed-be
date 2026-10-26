class Lkh {
  Lkh({
    required this.id,
    required this.rkhId,
    required this.salesId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    this.namaPic = '',
    this.nomorPic = '',
    this.statusLkh = 'NOT_YET',
    this.tindakLanjut,
    this.tanggalFollowUp,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final int id, rkhId, salesId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan, namaPic, nomorPic, statusLkh;
  final String? tindakLanjut;
  final DateTime? tanggalFollowUp;
  final double? latitude, longitude;
  final DateTime? createdAt;

  bool get isDone => statusLkh.toUpperCase() == 'DONE';

  factory Lkh.fromJson(Map<String, dynamic> j) => Lkh(
        id: j['id'] as int,
        rkhId: j['rkh_id'] as int,
        salesId: j['sales_id'] as int,
        tanggalKunjungan: DateTime.parse(j['tanggal_kunjungan'] as String),
        hasilKunjungan: (j['hasil_kunjungan'] ?? '').toString(),
        namaPic: (j['nama_pic'] ?? '').toString(),
        nomorPic: (j['nomor_pic'] ?? '').toString(),
        statusLkh: (j['status_lkh'] ?? 'NOT_YET').toString(),
        tindakLanjut: j['tindak_lanjut'] as String?,
        tanggalFollowUp: j['tanggal_follow_up'] == null ? null : DateTime.parse(j['tanggal_follow_up'] as String),
        // Backend bisa mengirim bilangan bulat (mis. 20), jadi lewat num.
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}