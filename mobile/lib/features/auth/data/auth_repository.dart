import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/data/models/app_user.dart';
import 'package:slamed_app/features/auth/data/models/captcha.dart';


class LoginResult {
  LoginResult(this.token, this.user);
  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// CAPTCHA berlaku singkat dan sekali pakai.
  Future<Captcha> fetchCaptcha() async {
    final d = await _api.request('GET', '/auth/captcha', auth: false);
    return Captcha(d['captcha_id'].toString(), d['question'].toString());
  }

  Future<LoginResult> login(String username, String password, Captcha captcha, String answer) async {
    final n = int.tryParse(answer.trim());
    if (n == null) throw ApiException(400, 'Jawaban CAPTCHA harus berupa angka.');
    final d = await _api.request('POST', '/auth/login', auth: false, body: {
      'username': username,
      'password': password,
      'captcha_id': captcha.id,
      'captcha_answer': n,
    });
    return LoginResult(
      d['access_token'] as String,
      AppUser.fromJson(Map<String, dynamic>.from(d['user'] as Map)),
    );
  }
}