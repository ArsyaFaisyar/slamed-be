import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_create.dart';

class LkhRepository {
  LkhRepository(this._api);
  final ApiClient _api;

  Future<List<Lkh>> list({int? rkhId, int? salesId}) async => parseList(
        await _api.request('GET', '/lkh/', query: {
          if (rkhId != null) 'rkh_id': '$rkhId',
          if (salesId != null) 'sales_id': '$salesId',
        }),
        Lkh.fromJson,
      );

  Future<Lkh> create(LkhCreate body) async =>
      Lkh.fromJson(Map<String, dynamic>.from(await _api.request('POST', '/lkh/', body: body.toJson())));

  /// Field multipart `file` + field form `jenis` (`FOTO` atau `LAMPIRAN`).
  /// Mengunggah FOTO membuat backend menandai LKH sebagai DONE.
  Future<dynamic> uploadAttachment(int lkhId, String filePath, {required String jenis}) =>
      _api.upload('/lkh/$lkhId/attachments', filePath, fields: {'jenis': jenis});

  Future<dynamic> attachments(int lkhId) => _api.request('GET', '/lkh/$lkhId/attachments');
}