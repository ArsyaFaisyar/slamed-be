/// Satu status project dari `GET /project-statuses`.
class ProjectStatus {
  const ProjectStatus({
    required this.id,
    required this.nama,
    this.warna,
    this.urutan = 0,
    this.isActive = true,
  });

  final int id, urutan;
  final String nama;
  final String? warna;
  final bool isActive;

  factory ProjectStatus.fromJson(Map<String, dynamic> j) => ProjectStatus(
        id: (j['id'] as num).toInt(),
        nama: (j['nama'] ?? '-').toString(),
        warna: j['warna']?.toString(),
        urutan: (j['urutan'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] != false,
      );
}