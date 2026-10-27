import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/models/project_status.dart';

class ProjectRepository {
  ProjectRepository(this._api);
  final ApiClient _api;

  Future<List<Project>> list({int? customerId}) async => parseList(
        await _api.request('GET', '/projects/', query: customerId == null ? null : {'customer_id': '$customerId'}),
        Project.fromJson,
      );

  Project _one(dynamic d) => Project.fromJson(Map<String, dynamic>.from(d as Map));

  Future<Project> get(int id) async => _one(await _api.request('GET', '/projects/$id'));

  /// Ubah status project (`PATCH /projects/{id}`); backend menulis riwayat statusnya.
  Future<Project> updateStatus(int id, int statusId) async =>
      _one(await _api.request('PATCH', '/projects/$id', body: {'status_id': statusId}));

  /// Status yang aktif dari `GET /project-statuses`.
  Future<List<ProjectStatus>> statuses() async =>
      parseList(await _api.request('GET', '/project-statuses'), ProjectStatus.fromJson).where((s) => s.isActive).toList();
}