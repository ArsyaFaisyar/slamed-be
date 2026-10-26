import 'dart:convert';
import 'dart:typed_data';

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
class AuthController extends GetxController {
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

  /// Foto profil pengguna yang login; satu sumber untuk Beranda dan Profil.
  final photo = Rxn<Uint8List>();
  final photoLoading = false.obs;

  /// Nomor pemuatan foto terakhir; hasil dari pemuatan yang lebih lama diabaikan.
  int _photoSeq = 0;
  bool _loggingOut = false;

  bool get isLoggedIn => token.value != null && user.value != null;
  String? get role => user.value?.role;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  /// Dari splash: pulihkan sesi, lalu arahkan ke home atau login.
  Future<void> _start() async {
    try {
      await bootstrap();
    } catch (_) {
      // Sesi tidak bisa dipulihkan: mulai dari login, jangan berhenti di splash.
      await _resetSession();
    }
    Get.offAllNamed(isLoggedIn ? AppRoutes.home : AppRoutes.login);
  }

  Future<void> _resetSession() async {
    try {
      await _session.clear();
    } catch (_) {}
    token.value = null;
    user.value = null;
    photo.value = null;
  }

  /// Pulihkan sesi dari token + data user tersimpan. Token kedaluwarsa dibuang
  /// tanpa memanggil server (/auth/me tidak ada di OpenAPI).
  Future<void> bootstrap() async {
    token.value = await _session.readToken();
    final cached = await _session.readUser();
    if (token.value != null && !jwtExpired(token.value!) && cached != null) {
      try {
        user.value = AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      } catch (_) {}
    }
    if (user.value == null) {
      await _session.clear();
      token.value = null;
    } else {
      refreshProfile();
    }
  }

  /// Segarkan data user dari GET /profile/ (bentuknya sama dengan `user` di login).
  /// Foto dimuat ulang bila [reloadPhoto] true atau `foto_profil` berubah.
  Future<void> refreshProfile({bool reloadPhoto = false}) async {
    try {
      final data = await _profile.fetchProfile();
      if (data != null && data['id'] != null) {
        final prevFoto = user.value?.fotoProfil;
        final u = AppUser.fromJson(data);
        user.value = u;
        await _session.writeUser(jsonEncode(u.toJson()));
        await loadPhoto(force: reloadPhoto || u.fotoProfil != prevFoto);
      }
    } catch (_) {}
  }

  /// Muat foto profil. Tanpa [force], tidak ada permintaan bila akun belum punya
  /// foto atau foto sudah dimuat. Gagal memuat: foto sebelumnya dipertahankan, atau
  /// avatar tampil sebagai inisial.
  Future<void> loadPhoto({bool force = false}) async {
    final u = user.value;
    if (u == null) {
      photo.value = null;
      return;
    }
    if (!force && (u.fotoProfil == null || photo.value != null)) return;

    final seq = ++_photoSeq;
    photoLoading.value = true;
    try {
      final bytes = await _profile.fetchPhoto();
      // Abaikan jika sudah ada pemuatan lebih baru atau akun sudah berganti.
      if (seq == _photoSeq && user.value?.id == u.id && bytes != null) photo.value = bytes;
    } catch (_) {
      // Abaikan: tampilan memakai inisial.
    } finally {
      if (seq == _photoSeq) photoLoading.value = false;
    }
  }

  Future<Captcha> fetchCaptcha() => _auth.fetchCaptcha();

  Future<void> login(String username, String password, Captcha captcha, String answer) async {
    final result = await _auth.login(username, password, captcha, answer);
    await _session.writeToken(result.token);
    await _session.writeUser(jsonEncode(result.user.toJson()));
    _photoSeq++; // batalkan pemuatan foto akun sebelumnya
    token.value = result.token;
    photo.value = null; // jangan mewarisi foto akun sebelumnya
    user.value = result.user;
    loadPhoto();
  }

  /// Backend belum punya endpoint logout: cukup hapus sesi di sisi app.
  Future<void> logout() async {
    // Beberapa request bisa kena 401 bersamaan; cukup satu yang diproses.
    if (_loggingOut || (token.value == null && user.value == null)) return;
    _loggingOut = true;
    try {
      _photoSeq++;
      photoLoading.value = false;
      await _resetSession();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      _loggingOut = false;
    }
  }
}