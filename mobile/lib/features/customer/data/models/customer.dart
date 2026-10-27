class Customer {
  Customer({
    required this.id,
    required this.namaInstansi,
    this.namaPic,
    this.kontakPic,
    this.kota,
    this.kategori,
    this.areaId,
    this.areaNama,
    this.salesId,
    this.salesNama,
    this.approvalStatus = 'APPROVED',
    this.rejectionReason,
    this.verifiedAt,
    this.createdAt,
  });

  final int id;
  final String namaInstansi;
  final String? namaPic, kontakPic, kota, kategori, areaNama, salesNama, rejectionReason;
  final int? areaId, salesId;

  /// PENDING (diajukan Sales), APPROVED, atau REJECTED.
  final String approvalStatus;
  final DateTime? verifiedAt, createdAt;

  bool get isPending => approvalStatus.toUpperCase() == 'PENDING';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: (j['id'] as num).toInt(),
        namaInstansi: (j['nama_instansi'] ?? '-').toString(),
        namaPic: j['nama_pic']?.toString(),
        kontakPic: j['kontak_pic']?.toString(),
        kota: j['kota']?.toString(),
        kategori: j['kategori']?.toString(),
        areaId: (j['area_id'] as num?)?.toInt(),
        areaNama: j['area_nama']?.toString(),
        salesId: (j['sales_id'] as num?)?.toInt(),
        salesNama: j['sales_nama']?.toString(),
        approvalStatus: (j['approval_status'] ?? 'APPROVED').toString(),
        rejectionReason: j['rejection_reason']?.toString(),
        verifiedAt: _date(j['verified_at']),
        createdAt: _date(j['created_at']),
      );

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}