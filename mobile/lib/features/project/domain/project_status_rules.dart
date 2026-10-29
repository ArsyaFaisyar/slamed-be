import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';

int? initialStatusId({required ProjectStatus? current, required List<ProjectStatus> active}) =>
    current != null && active.any((s) => s.id == current.id) ? current.id : null;

bool statusNeedsUpdate({required int? selected, required int? current}) => selected != null && selected != current;

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


List<ProjectStatus> statusesWithCurrent({required List<ProjectStatus> active, required Project project}) {
  final list = List.of(active);
  final cur = project.statusId;
  if (cur != null && !list.any((s) => s.id == cur)) {
    list.add(ProjectStatus(
      id: cur,
      nama: project.statusNama ?? 'Status #$cur',
      warna: project.statusWarna,
      urutan: project.statusUrutan ?? (1 << 30),
      isActive: false,
    ));
  }
  list.sort((a, b) => a.urutan.compareTo(b.urutan));
  return list;
}