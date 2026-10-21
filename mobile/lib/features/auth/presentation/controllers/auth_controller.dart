import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/core/storage/session_store.dart';
import 'package:slamed_app/core/utils/jwt_utils.dart';
import 'package:slamed_app/features/auth/data/auth_repository.dart';
import 'package:slamed_app/features/auth/data/models/app_user.dart';
import 'package:slamed_app/features/auth/data/models/captcha.dart';
import 'package:slamed_app/features/profile/data/profile_repository.dart';


/// Sesi login global (permanent). Dipakai halaman lain lewat Get.find / GetView.
class AuthController extends  GetxController {
  AuthController({
    required SessionStore session,
    required ApiClient api,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _session = session,
        _auth = authRepository,
        _profile = profileRepository {
    api.onUnauthorized = () {
      logout();
    };
  }

  final SessionStore _session;
  final AuthRepository _auth;
  final ProfileRepository _profile;

  final user = Rxn<AppUser>();
  final token = RxnString();

  bool get isLoggedIn => token.value != null && user.value != null;
  String? get role => user.value?.role;

  @override
  void onReady() {
    super.onReady();
    _start();
  }


Future<void> _start() async {
  debugPrint('[SPLASH] _start dimulai');

  try {
    await bootstrap();
    debugPrint('[SPLASH] bootstrap selesai');
    debugPrint('[SPLASH] isLoggedIn: $isLoggedIn');

    Get.offAllNamed(
      isLoggedIn ? AppRoutes.home : AppRoutes.login,
    );
    debugPrint('[SPLASH] Navigasi dijalankan');
  } catch (e, stackTrace) {
    debugPrint('[SPLASH] ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> bootstrap() async {
  debugPrint('[AUTH] Membaca token...');
  token.value = await _session.readToken();

  debugPrint('[AUTH] Membaca user...');
  final cached = await _session.readUser();

  debugPrint('[AUTH] Token tersedia: ${token.value != null}');
  debugPrint('[AUTH] User tersedia: ${cached != null}');

  if (token.value != null &&
      !jwtExpired(token.value!) &&
      cached != null) {
    try {
      user.value = AppUser.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(cached) as Map,
        ),
      );
    } catch (e) {
      debugPrint('[AUTH] Gagal membaca data user: $e');
    }
  }

  if (user.value == null) {
    await _session.clear();
    token.value = null;
  } else {
    refreshProfile();
  }
}


  /// Segarkan data user dari GET /profile/ (bentuknya sama dengan `user` di login).
  Future<void> refreshProfile() async {
    try {
      final data = await _profile.fetchProfile();
      if (data != null && data['id'] != null) {
        final u = AppUser.fromJson(data);
        user.value = u;
        await _session.writeUser(jsonEncode(u.toJson()));
      }
    } catch (_) {}
  }

  Future<Captcha> fetchCaptcha() => _auth.fetchCaptcha();

  Future<void> login(String username, String password, Captcha captcha, String answer) async {
    final result = await _auth.login(username, password, captcha, answer);
    await _session.writeToken(result.token);
    await _session.writeUser(jsonEncode(result.user.toJson()));
    token.value = result.token;
    user.value = result.user;
  }

  /// Backend belum punya endpoint logout: cukup hapus sesi di sisi app.
  Future<void> logout() async {
    await _session.clear();
    token.value = null;
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}