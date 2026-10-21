import 'package:slamed_app/core/network/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  /// Mengembalikan null jika bentuk respons bukan objek.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final d = await _api.request('GET', '/profile/');
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  Future<void> changePassword(String lama, String baru) => _api.request(
        'PATCH',
        '/profile/password',
        body: {'password_lama': lama, 'password_baru': baru},
      );

  /// Field multipart: `file` (JPG/PNG/WEBP, maks. 5 MB menurut panduan).
  Future<dynamic> uploadPhoto(String filePath) => _api.upload('/profile/photo', filePath);
}