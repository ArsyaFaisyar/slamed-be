import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';

class ProjectStatusRepository {
  ProjectStatusRepository(this._api);
  final ApiClient _api;

  /// Hanya status aktif (default backend), urut menurut `urutan`.
  /// Path sengaja tanpa garis miring di akhir, sesuai OpenAPI.
  Future<List<ProjectStatus>> listActive() async {
    final all = parseList(await _api.request('GET', '/project-statuses'), ProjectStatus.fromJson);
    final list = all.where((s) => s.isActive).toList()
      ..sort((a, b) {
        final c = a.urutan.compareTo(b.urutan);
        return c != 0 ? c : a.nama.compareTo(b.nama);
      });
    return list;
  }
}