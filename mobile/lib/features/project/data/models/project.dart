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

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as int,
        customerId: j['customer_id'] as int,
        namaProject: j['nama_project'] as String,
        jenis: j['jenis'] as String,
        status: j['status'] as String,
        deskripsi: j['deskripsi'] as String?,
      );
}