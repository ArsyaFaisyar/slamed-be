import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:slamed_app/core/config/app_config.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/storage/session_store.dart';

/// Klien HTTP tunggal: menyisipkan Bearer token, menerjemahkan error backend
/// menjadi [ApiException], dan memanggil [onUnauthorized] saat sesi tidak valid.
class ApiClient {
  ApiClient(this._session);
  final SessionStore _session;

  /// Diisi AuthController agar 401 pada request terproteksi mengeluarkan user.
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

  /// [body] dikirim sebagai JSON. [form] dikirim sebagai
  /// `application/x-www-form-urlencoded` (untuk endpoint FastAPI berparameter Form,
  /// mis. `POST /lkh/`). Isi salah satu saja.
  ///
  /// [logoutOn401] false untuk endpoint yang memakai 401 bukan karena sesi habis
  /// (mis. kata sandi lama salah).
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? form,
    Map<String, String>? query,
    bool auth = true,
    bool logoutOn401 = true,
  }) async {
    final req = http.Request(method, _uri(path, query));
    await _prepare(req.headers, auth);
    if (form != null) {
      req.bodyFields = form; // otomatis mengatur Content-Type form-urlencoded
    } else if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    return _send(req, auth, logoutOn401: logoutOn401);
  }

  /// Upload multipart. Jangan set Content-Type manual (boundary diatur otomatis).
  /// [fields] adalah field form tambahan (mis. `jenis` untuk lampiran LKH).
  /// [mimeType] mengganti tebakan otomatis Content-Type file.
  Future<dynamic> upload(
    String path,
    String filePath, {
    String field = 'file',
    Map<String, String>? fields,
    String? mimeType,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..files.add(await http.MultipartFile.fromPath(
        field,
        filePath,
        contentType: mimeType == null ? null : MediaType.parse(mimeType),
      ));
    if (fields != null) req.fields.addAll(fields);
    await _prepare(req.headers, true);
    return _send(req, true, timeout: const Duration(seconds: 60));
  }

  Future<dynamic> _send(
    http.BaseRequest req,
    bool auth, {
    Duration timeout = const Duration(seconds: 20),
    bool logoutOn401 = true,
  }) async {
    http.Response res;
    try {
      final streamed = await req.send().timeout(timeout);
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
      if (res.statusCode == 401 && auth && logoutOn401 && await _session.readToken() != null) {
        onUnauthorized?.call();
      }
      throw ApiException(res.statusCode, detailFrom(data, res.statusCode));
    }
    return data;
  }
}