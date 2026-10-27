/// Isi `PATCH /customers/{id}`. Semua kolom dikirim; kolom opsional yang dikosongkan
/// dikirim null agar terhapus. `sales_id` dan `area_id` tidak dikirim.
class CustomerUpdate {
  CustomerUpdate({
    required this.namaInstansi,
    this.namaPic,
    this.kontakPic,
    this.kota,
    this.kategori,
  });

  final String namaInstansi;
  final String? namaPic, kontakPic, kota, kategori;

  Map<String, dynamic> toJson() => {
        'nama_instansi': namaInstansi,
        'nama_pic': namaPic,
        'kontak_pic': kontakPic,
        'kota': kota,
        'kategori': kategori,
      };
}