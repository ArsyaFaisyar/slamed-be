/// Isi `POST /customers/`. `sales_id` dan `area_id` sengaja tidak dikirim: untuk
/// Sales, server menetapkannya dari akun yang login.
class CustomerCreate {
  CustomerCreate({
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
        if (namaPic != null) 'nama_pic': namaPic,
        if (kontakPic != null) 'kontak_pic': kontakPic,
        if (kota != null) 'kota': kota,
        if (kategori != null) 'kategori': kategori,
      };
}