import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan aman untuk token dan data user (agar sesi bisa dipulihkan).
class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _userKey = 'user_json';

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readUser() => _storage.read(key: _userKey);
  Future<void> writeUser(String json) => _storage.write(key: _userKey, value: json);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}