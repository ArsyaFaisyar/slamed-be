import 'package:slamed_app/core/utils/date_format.dart';

class LkhCreate {
  LkhCreate({
    required this.rkhId,
    required this.tanggalKunjungan,
    required this.hasilKunjungan,
    this.statusProspek,
    this.tindakLanjut,
    this.latitude,
    this.longitude,
  });

  final int rkhId;
  final DateTime tanggalKunjungan;
  final String hasilKunjungan;
  final String? statusProspek, tindakLanjut;
  final double? latitude, longitude;

  Map<String, dynamic> toJson() => {
        'rkh_id': rkhId,
        'tanggal_kunjungan': toApiDate(tanggalKunjungan),
        'hasil_kunjungan': hasilKunjungan,
        if (statusProspek != null) 'status_prospek': statusProspek,
        if (tindakLanjut != null) 'tindak_lanjut': tindakLanjut,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}