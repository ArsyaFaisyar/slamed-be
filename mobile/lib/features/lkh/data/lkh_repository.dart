import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/json_list.dart';
import 'package:slamed_app/core/utils/mime.dart';
import 'package:slamed_app/features/lkh/data/models/lkh.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_attachment.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_create.dart';
import 'package:slamed_app/features/lkh/data/models/lkh_update.dart';

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

  Future<Lkh> get(int id) async =>
      Lkh.fromJson(Map<String, dynamic>.from(await _api.request('GET', '/lkh/$id')));

  /// `POST /lkh/` menerima form-urlencoded (bukan JSON) dan tidak menerima file.
  /// Foto dan lampiran diunggah terpisah lewat [uploadAttachment].
  Future<Lkh> create(LkhCreate body) async => Lkh.fromJson(
        Map<String, dynamic>.from(await _api.request('POST', '/lkh/', form: body.toForm())),
      );

  /// `PATCH /lkh/{id}` menerima JSON.
  Future<Lkh> update(int id, LkhUpdate body) async =>
      Lkh.fromJson(Map<String, dynamic>.from(await _api.request('PATCH', '/lkh/$id', body: body.toJson())));

  Future<void> delete(int id) async {
    await _api.request('DELETE', '/lkh/$id');
  }

  /// Field multipart `file` + field form `jenis` (`FOTO` atau `LAMPIRAN`).
  /// Mengunggah FOTO membuat backend menandai LKH sebagai DONE; unggahan baru
  /// dengan jenis yang sama menggantikan yang lama.
  Future<dynamic> uploadAttachment(int lkhId, String filePath, {required String jenis}) {
    final mime = mimeForPath(filePath);
    debugPrint('[LKH] upload lkh=$lkhId jenis=$jenis mime=$mime path=$filePath');
    return _api.upload(
      '/lkh/$lkhId/attachments',
      filePath,
      fields: {'jenis': jenis},
      mimeType: mime,
    );
  }

  Future<List<LkhAttachment>> attachments(int lkhId) async =>
      parseList(await _api.request('GET', '/lkh/$lkhId/attachments'), LkhAttachment.fromJson);

  /// Isi berkas (mis. untuk menampilkan foto). Respons non-JSON dikembalikan apa adanya.
  Future<Uint8List> attachmentBytes(int attachmentId) async {
    final d = await _api.request('GET', '/lkh/attachments/$attachmentId/file');
    return d is Uint8List ? d : Uint8List(0);
  }
}