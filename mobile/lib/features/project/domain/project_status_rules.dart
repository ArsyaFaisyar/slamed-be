import 'package:slamed_app/features/project/data/models/project_status.dart';

/// Pilihan awal dropdown: status saat ini, hanya bila masih aktif (ada di daftar).
int? initialStatusId({required ProjectStatus? current, required List<ProjectStatus> active}) =>
    current != null && active.any((s) => s.id == current.id) ? current.id : null;

/// PATCH hanya dikirim bila pilihan ada dan berbeda dari status saat ini.
bool statusNeedsUpdate({required int? selected, required int? current}) => selected != null && selected != current;

/// Status yang boleh dipilih dari status [currentId]: status itu sendiri dan yang
/// urutannya sama atau lebih maju. Status tidak boleh dimundurkan, mis. project yang
/// sudah di tahap penawaran tidak bisa kembali ke Canvas. Urutan memakai `urutan`
/// dari `GET /project-statuses`. Tanpa status saat ini, semua status boleh dipilih.
List<ProjectStatus> allowedStatusTargets({required List<ProjectStatus> all, required int? currentId}) {
  if (currentId == null) return List.of(all);
  ProjectStatus? cur;
  for (final s in all) {
    if (s.id == currentId) cur = s;
  }
  if (cur == null) return List.of(all);
  final base = cur.urutan;
  return all.where((s) => s.id == currentId || s.urutan >= base).toList();
}