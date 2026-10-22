class Customer {
  Customer({
    required this.id,
    required this.namaInstansi,
    this.namaPic,
    this.kontakPic,
    this.kota,
    this.kategori,
    this.area,
    this.salesId,
  });

  final int id;
  final String namaInstansi;
  final String? namaPic, kontakPic, kota, kategori, area;
  final int? salesId;

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as int,
        namaInstansi: j['nama_instansi'] as String,
        namaPic: j['nama_pic'] as String?,
        kontakPic: j['kontak_pic'] as String?,
        kota: j['kota'] as String?,
        kategori: j['kategori'] as String?,
        area: j['area'] as String?,
        salesId: j['sales_id'] as int?,
      );
}