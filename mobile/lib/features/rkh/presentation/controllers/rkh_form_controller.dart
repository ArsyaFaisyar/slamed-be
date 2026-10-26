import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/network/api_exception.dart';
import 'package:slamed_app/core/utils/currency_format.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/customer/data/models/customer.dart';
import 'package:slamed_app/features/project/data/models/project.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/features/rkh/data/models/rkh_create.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';

class RkhFormController extends GetxController {
  RkhFormController(this._customerRepo, this._projectRepo, this._rkhRepo);
  final CustomerRepository _customerRepo;
  final ProjectRepository _projectRepo;
  final RkhRepository _rkhRepo;

  final judul = TextEditingController();
  final rencana = TextEditingController();
  final tipe = TextEditingController();
  final biaya = TextEditingController();

  final customers = <Customer>[].obs;
  final projects = <Project>[].obs;
  final customerId = RxnInt();
  final projectId = RxnInt();
  final loadingProjects = false.obs;
  final pelaksanaan = DateTime.now().obs;
  final busy = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadCustomers();
  }

  @override
  void onClose() {
    judul.dispose();
    rencana.dispose();
    tipe.dispose();
    biaya.dispose();
    super.onClose();
  }

  Future<void> _loadCustomers() async {
    try {
      customers.assignAll(await _customerRepo.list());
    } catch (e) {
      error.value = errorMessage(e);
    }
  }

  Future<void> pickCustomer(int? id) async {
    customerId.value = id;
    projectId.value = null;
    projects.clear();
    if (id == null) return;
    loadingProjects.value = true;
    try {
      final list = await _projectRepo.list(customerId: id);
      if (customerId.value != id) return; // customer sudah berganti saat menunggu
      projects.assignAll(list);
    } catch (e) {
      if (customerId.value == id) showSnack(errorMessage(e));
    } finally {
      if (customerId.value == id) loadingProjects.value = false;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final today = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: pelaksanaan.value,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: AppConstants.maxHariKeDepan)),
    );
    if (d != null) pelaksanaan.value = d;
  }

  Future<void> submit() async {
    if (customerId.value == null ||
        projectId.value == null ||
        judul.text.trim().isEmpty ||
        rencana.text.trim().isEmpty ||
        tipe.text.trim().isEmpty) {
      error.value = 'Lengkapi customer, project, judul, rencana, dan tipe aktivitas.';
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      await _rkhRepo.create(RkhCreate(
        customerId: customerId.value!,
        projectId: projectId.value!,
        tanggalRencana: DateTime.now(),
        tanggalPelaksanaan: pelaksanaan.value,
        judulKegiatan: judul.text.trim(),
        rencanaKegiatan: rencana.text.trim(),
        tipeAktivitas: tipe.text.trim(),
        // Kolom berisi "1.500.000"; server menerima digit polos.
        estimasiBiayaHarian: rupiahDigits(biaya.text),
      ));
      Get.back<bool>(result: true);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      busy.value = false;
    }
  }
}