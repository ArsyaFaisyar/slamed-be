/// Respons `GET /projects/` (ProjectProspekResponse). Status project berasal dari
/// `status_rel` (tabel project-statuses), bukan lagi field teks `status`/`jenis`.
class Project {
  Project({
    required this.id,
    required this.customerId,
    required this.salesId,
    required this.namaProject,
    this.deskripsi,
    this.statusId,
    this.statusNama,
    this.statusWarna,
    this.statusUrutan,
    this.nilaiProyek,
    this.estimasiClosing,
    this.createdAt,
  });

  final int id, customerId, salesId;
  final String namaProject;
  final String? deskripsi, statusNama, statusWarna, nilaiProyek;
  final int? statusId, statusUrutan;
  final DateTime? estimasiClosing, createdAt;

  factory Project.fromJson(Map<String, dynamic> j) {
    final rel = j['status_rel'];
    final Map? r = rel is Map ? rel : null;
    return Project(
      id: (j['id'] as num).toInt(),
      customerId: (j['customer_id'] as num).toInt(),
      salesId: (j['sales_id'] as num?)?.toInt() ?? 0,
      namaProject: (j['nama_project'] ?? '-').toString(),
      deskripsi: j['deskripsi']?.toString(),
      statusId: (j['status_id'] as num?)?.toInt(),
      statusNama: r?['nama']?.toString(),
      statusWarna: r?['warna']?.toString(),
      statusUrutan: (r?['urutan'] as num?)?.toInt(),
      // Backend mengirim angka uang sebagai teks (mis. "1500000.00").
      nilaiProyek: j['nilai_proyek']?.toString(),
      estimasiClosing: _date(j['estimasi_closing']),
      createdAt: _date(j['created_at']),
    );
  }

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}