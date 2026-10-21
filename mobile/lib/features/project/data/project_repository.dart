import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/project/data/models/project.dart';

class ProjectRepository {
  ProjectRepository(this._api);
  final ApiClient _api;

  Future<List<Project>> list({int? customerId}) async => parseList(
        await _api.request('GET', '/projects/', query: customerId == null ? null : {'customer_id': '$customerId'}),
        Project.fromJson,
      );
} 