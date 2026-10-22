import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_create.dart';

class LkhRepository {
  LkhRepository(this._api);

  final ApiClient _api;

  Future<List<Lkh>> list({
    int? rkhId,
    int? salesId,
  }) async =>
      parseList(
        await _api.request(
          'GET',
          '/lkh/',
          query: {
            if (rkhId != null) 'rkh_id': '$rkhId',
            if (salesId != null) 'sales_id': '$salesId',
          },
        ),
        Lkh.fromJson,
      );

  /// Membuat LKH beserta foto dokumentasi dalam satu request.
  Future<Lkh> create(
    LkhCreate body, {
    required String fotoPath,
  }) async {
    final fields = body.toJson().map(
          (key, value) => MapEntry(key, value.toString()),
        );

    final response = await _api.uploadForm(
      '/lkh/',
      fields: fields,
      files: {
        'foto': fotoPath,
      },
    );

    return Lkh.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  /// Upload foto atau lampiran tambahan ke LKH yang sudah dibuat.
  Future<dynamic> uploadAttachment(
    int lkhId,
    String filePath, {
    required String jenis,
  }) =>
      _api.upload(
        '/lkh/$lkhId/attachments',
        filePath,
        fields: {'jenis': jenis},
      );

  Future<dynamic> attachments(int lkhId) =>
      _api.request('GET', '/lkh/$lkhId/attachments');
}