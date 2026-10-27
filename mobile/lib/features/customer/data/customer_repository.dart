import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/customer/data/models/customer_create.dart';
import 'package:slamed_app/features/customer/data/models/customer_update.dart';

class CustomerRepository {
  CustomerRepository(this._api);
  final ApiClient _api;

  /// Sales hanya menerima customer miliknya (semua status); role lain menerima semuanya.
  Future<List<Customer>> list() async => parseList(await _api.request('GET', '/customers/'), Customer.fromJson);

  Customer _one(dynamic d) => Customer.fromJson(Map<String, dynamic>.from(d as Map));

  /// `POST /customers/`. Dari Sales, hasilnya berstatus PENDING dan menunggu persetujuan.
  Future<Customer> create(CustomerCreate body) async =>
      _one(await _api.request('POST', '/customers/', body: body.toJson()));

  /// `PATCH /customers/{id}`. Perubahan oleh Sales mengembalikan status ke PENDING.
  Future<Customer> update(int id, CustomerUpdate body) async =>
      _one(await _api.request('PATCH', '/customers/$id', body: body.toJson()));

  /// SPV / SUPERADMIN.
  Future<Customer> approve(int id) async => _one(await _api.request('PATCH', '/customers/$id/approve'));

  /// SPV / SUPERADMIN. [alasan] wajib.
  Future<Customer> reject(int id, String alasan) async =>
      _one(await _api.request('PATCH', '/customers/$id/reject', body: {'alasan': alasan}));

  /// Nama kategori dari `GET /customer-categories/` (bukan objek lengkap).
  Future<List<String>> categories() async {
    final names = parseList(
      await _api.request('GET', '/customer-categories/'),
      (j) => (j['nama'] ?? '').toString().trim(),
    );
    return names.where((n) => n.isNotEmpty).toList();
  }
}