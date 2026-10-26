import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/auth/data/models/app_user.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/profile/data/profile_repository.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

class ProfileController extends GetxController {
  ProfileController(this._repo, this._auth);
  final ProfileRepository _repo;
  final AuthController _auth;
  final _picker = ImagePicker();

  static const _maxFotoBytes = 5 * 1024 * 1024;

  final uploading = false.obs;

  Rxn<AppUser> get user => _auth.user;

  /// Ambil foto dari kamera atau galeri lalu unggah sebagai foto profil.
  Future<void> pickPhoto(ImageSource source) async {
    if (uploading.value) return;
    try {
      final f = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (f == null) return; // dibatalkan
      if (await f.length() > _maxFotoBytes) {
        showSnack('Ukuran foto melebihi 5 MB.');
        return;
      }
      uploading.value = true;
      await _repo.uploadPhoto(f.path);
      // Perbarui data user dan muat ulang fotonya (Beranda dan Profil ikut berubah).
      await _auth.refreshProfile(reloadPhoto: true);
      showSnack('Foto profil diperbarui.');
    } on PlatformException catch (e) {
      showSnack(switch (e.code) {
        'camera_access_denied' => 'Izin kamera ditolak. Aktifkan di pengaturan aplikasi.',
        'photo_access_denied' => 'Izin galeri ditolak. Aktifkan di pengaturan aplikasi.',
        'no_available_camera' => 'Perangkat ini tidak memiliki kamera.',
        _ => 'Gagal membuka pemilih foto.',
      });
    } catch (e) {
      showSnack(errorMessage(e));
    } finally {
      uploading.value = false;
    }
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> changePassword(String lama, String baru) async {
    try {
      await _repo.changePassword(lama, baru);
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }

  Future<void> logout() => _auth.logout();
}