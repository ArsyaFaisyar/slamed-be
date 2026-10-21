import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/rkh/data/models/rkh.dart';
import 'package:slamed_app/features/rkh/data/models/rkh_create.dart';

class RkhRepository {
  RkhRepository(this._api);
  final ApiClient _api;

  Future<List<Rkh>> list({int? salesId, int? customerId}) async => parseList(
        await _api.request('GET', '/rkh/', query: {
          if (salesId != null) 'sales_id': '$salesId',
          if (customerId != null) 'customer_id': '$customerId',
        }),
        Rkh.fromJson,
      );

  Future<Rkh> create(RkhCreate body) async =>
      Rkh.fromJson(Map<String, dynamic>.from(await _api.request('POST', '/rkh/', body: body.toJson())));
}