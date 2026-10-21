class Project {
  Project({
    required this.id,
    required this.customerId,
    required this.namaProject,
    required this.jenis,
    required this.status,
    this.deskripsi,
  });

  final int id, customerId;
  final String namaProject, jenis, status;
  final String? deskripsi;

  /// Toleran terhadap field null/tipe angka berbeda dari backend.
  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: (j['id'] as num).toInt(),
        customerId: (j['customer_id'] as num?)?.toInt() ?? 0,
        namaProject: (j['nama_project'] ?? '-').toString(),
        jenis: (j['jenis'] ?? '-').toString(),
        status: (j['status'] ?? '').toString(),
        deskripsi: j['deskripsi']?.toString(),
      );
}