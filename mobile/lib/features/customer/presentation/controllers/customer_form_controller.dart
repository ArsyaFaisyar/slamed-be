import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/customer/data/models/customer_create.dart';
import 'package:slamed_app/features/customer/data/models/customer_update.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

/// Form pengajuan customer (Sales). Bila dibuka dengan argumen [Customer], formnya
/// memperbaiki pengajuan itu dan mengajukannya ulang.
class CustomerFormController extends GetxController {
  CustomerFormController(this._repo);
  final CustomerRepository _repo;

  Customer? existing;
  bool get isEdit => existing != null;

  final nama = TextEditingController();
  final kota = TextEditingController();
  final kategoriText = TextEditingController(); // dipakai bila daftar kategori tidak tersedia
  final namaPic = TextEditingController();
  final kontakPic = TextEditingController();

  final categories = <String>[].obs;
  final kategori = RxnString();
  final loadingCategories = true.obs;
  final busy = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final a = Get.arguments;
    existing = a is Customer ? a : null;
    final e = existing;
    if (e != null) {
      nama.text = e.namaInstansi;
      kota.text = e.kota ?? '';
      namaPic.text = e.namaPic ?? '';
      kontakPic.text = e.kontakPic ?? '';
      kategoriText.text = e.kategori ?? '';
      final k = e.kategori?.trim() ?? '';
      kategori.value = k.isEmpty ? null : k;
    }
    _loadCategories();
  }

  @override
  void onClose() {
    nama.dispose();
    kota.dispose();
    kategoriText.dispose();
    namaPic.dispose();
    kontakPic.dispose();
    super.onClose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _repo.categories();
      // Kategori lama yang tidak ada di daftar tetap dipilih (agar dropdown tidak error).
      final k = kategori.value;
      if (list.isNotEmpty && k != null && !list.contains(k)) list.insert(0, k);
      categories.assignAll(list);
    } catch (_) {
      // Tidak fatal: kolom kategori menjadi teks bebas.
    } finally {
      loadingCategories.value = false;
    }
  }

  String? _clean(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<void> submit() async {
    final n = nama.text.trim();
    if (n.isEmpty) {
      error.value = 'Nama instansi wajib diisi.';
      return;
    }
    final kat = categories.isNotEmpty ? _clean(kategori.value) : _clean(kategoriText.text);
    busy.value = true;
    error.value = null;
    try {
      final e = existing;
      if (e == null) {
        await _repo.create(CustomerCreate(
          namaInstansi: n,
          namaPic: _clean(namaPic.text),
          kontakPic: _clean(kontakPic.text),
          kota: _clean(kota.text),
          kategori: kat,
        ));
        showSnack('Pengajuan customer dikirim ke SPV.');
      } else {
        await _repo.update(
          e.id,
          CustomerUpdate(
            namaInstansi: n,
            namaPic: _clean(namaPic.text),
            kontakPic: _clean(kontakPic.text),
            kota: _clean(kota.text),
            kategori: kat,
          ),
        );
        showSnack('Pengajuan diperbarui dan dikirim ulang ke SPV.');
      }
      Get.back<bool>(result: true);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      busy.value = false;
    }
  }
}