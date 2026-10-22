import 'package:slamed_app/core/utils/date_format.dart';

class LkhCreate {
  LkhCreate({
    required this.rkhId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    required this.namaPic,
    required this.nomorPic,
    this.statusLkh = 'NOT_YET',
    this.tindakLanjut,
    this.latitude,
    this.longitude,
  });

  final int rkhId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan, namaPic, nomorPic, statusLkh;
  final String? tindakLanjut;
  final double? latitude, longitude;

  Map<String, dynamic> toJson() => {
        'rkh_id': rkhId,
        'tanggal_kunjungan': toApiDate(tanggalKunjungan),
        'hasil_kunjungan': hasilKunjungan,
        'nama_pic': namaPic,
        'nomor_pic': nomorPic,
        'status_lkh': statusLkh,
        if (tindakLanjut != null) 'tindak_lanjut': tindakLanjut,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}