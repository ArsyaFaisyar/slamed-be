import 'dart:typed_data';

import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/utils/mime.dart';

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  /// Mengembalikan null jika bentuk respons bukan objek.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final d = await _api.request('GET', '/profile/');
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  /// `GET /profile/photo`: isi gambar. Null jika responsnya bukan gambar (mis. JSON).
  Future<Uint8List?> fetchPhoto() async {
    final d = await _api.request('GET', '/profile/photo');
    return (d is Uint8List && d.isNotEmpty) ? d : null;
  }

  /// Kata sandi lama yang salah tidak boleh dianggap sesi habis, jadi 401 di sini
  /// tidak memicu logout.
  Future<void> changePassword(String lama, String baru) => _api.request(
        'PATCH',
        '/profile/password',
        body: {'password_lama': lama, 'password_baru': baru},
        logoutOn401: false,
      );

  /// Field multipart: `file` (JPG/PNG/WEBP, maks. 5 MB menurut panduan).
  Future<dynamic> uploadPhoto(String filePath) =>
      _api.upload('/profile/photo', filePath, mimeType: mimeForPath(filePath));
}