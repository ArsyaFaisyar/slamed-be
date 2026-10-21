import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';

class CustomerRepository {
  CustomerRepository(this._api);
  final ApiClient _api;

  Future<List<Customer>> list() async => parseList(await _api.request('GET', '/customers/'), Customer.fromJson);
}