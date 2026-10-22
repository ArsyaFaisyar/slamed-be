import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:slamed_app/core/config/app_config.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/storage/session_store.dart';

/// Klien HTTP tunggal: menyisipkan Bearer token, menerjemahkan error backend
/// menjadi [ApiException], dan memanggil [onUnauthorized] saat sesi tidak valid.
class ApiClient {
  ApiClient(this._session);
  final SessionStore _session;

  /// Diisi AuthProvider agar 401 pada request terproteksi mengeluarkan user.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final q = (query == null || query.isEmpty) ? null : query;
    return Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: q);
  }

  Future<void> _prepare(Map<String, String> headers, bool auth) async {
    headers['Accept'] = 'application/json';
    final token = auth ? await _session.readToken() : null;
    if (token != null) headers['Authorization'] = 'Bearer $token';
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final req = http.Request(method, _uri(path, query));
    await _prepare(req.headers, auth);
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    return _send(req, auth);
  }

  /// Upload multipart. Jangan set Content-Type manual (boundary diatur otomatis).
  Future<dynamic> upload(String path, String filePath, {String field = 'file'}) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..files.add(await http.MultipartFile.fromPath(field, filePath));
    await _prepare(req.headers, true);
    return _send(req, true);
  }

  Future<dynamic> _send(http.BaseRequest req, bool auth) async {
    http.Response res;
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(0, 'Server tidak merespons. Coba lagi.${kDebugMode ? '\n(${req.url})' : ''}');
    } on SocketException {
      throw ApiException(0, 'Tidak dapat terhubung ke server.${kDebugMode ? '\n(${req.url})' : ''}');
    }
    final isJson = (res.headers['content-type'] ?? '').contains('json');
    final data = isJson
        ? (res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes)))
        : res.bodyBytes;
    if (res.statusCode >= 400) {
      if (res.statusCode == 401 && auth && await _session.readToken() != null) {
        onUnauthorized?.call();
      }
      throw ApiException(res.statusCode, detailFrom(data, res.statusCode));
    }
    return data;
  }
}