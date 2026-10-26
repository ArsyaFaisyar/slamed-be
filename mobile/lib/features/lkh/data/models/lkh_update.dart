/// Isi `PATCH /lkh/{id}` (JSON): hanya field yang diisi yang dikirim.
class LkhUpdate {
  LkhUpdate({this.hasilKunjungan, this.tindakLanjut, this.namaPic, this.nomorPic, this.latitude, this.longitude});

  final String? hasilKunjungan, tindakLanjut, namaPic, nomorPic;
  final double? latitude, longitude;

  Map<String, dynamic> toJson() => {
        if (hasilKunjungan != null) 'hasil_kunjungan': hasilKunjungan,
        if (tindakLanjut != null) 'tindak_lanjut': tindakLanjut,
        if (namaPic != null) 'nama_pic': namaPic,
        if (nomorPic != null) 'nomor_pic': nomorPic,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}