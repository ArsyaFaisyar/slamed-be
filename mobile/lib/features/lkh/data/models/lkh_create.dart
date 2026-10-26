import 'package:slamed_app/core/utils/date_format.dart';

/// Isi form `POST /lkh/`. Backend menurunkan `sales_id` dari user yang login dan
/// mengisi `status_lkh` sendiri (NOT_YET, lalu DONE saat foto terunggah).
class LkhCreate {
  LkhCreate({
    required this.rkhId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    required this.namaPic,
    required this.nomorPic,
    this.tindakLanjut,
    this.latitude,
    this.longitude,
  });

  final int rkhId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan, namaPic, nomorPic;
  final String? tindakLanjut;
  final double? latitude, longitude;

  /// Endpoint ini memakai form-urlencoded, jadi semua nilai berupa teks.
  Map<String, String> toForm() => {
        'rkh_id': '$rkhId',
        'tanggal_kunjungan': toApiDate(tanggalKunjungan),
        'hasil_kunjungan': hasilKunjungan,
        'nama_pic': namaPic,
        'nomor_pic': nomorPic,
        if (tindakLanjut != null) 'tindak_lanjut': tindakLanjut!,
        if (latitude != null) 'latitude': '$latitude',
        if (longitude != null) 'longitude': '$longitude',
      };
}