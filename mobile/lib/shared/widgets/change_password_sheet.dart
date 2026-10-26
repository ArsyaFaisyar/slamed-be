import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:slamed_app/shared/helpers/snackbar.dart';
import 'package:slamed_app/shared/widgets/error_box.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';

/// Bottom sheet ubah kata sandi. Panjang minimal 6 sesuai skema backend.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _hide = true, _busy = false;
  String? _error;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lama = _lama.text, baru = _baru.text;
    String? err;
    if (lama.isEmpty || baru.isEmpty || _ulang.text.isEmpty) {
      err = 'Semua kolom wajib diisi.';
    } else if (baru.length < 6) {
      err = 'Kata sandi baru minimal 6 karakter.';
    } else if (baru != _ulang.text) {
      err = 'Konfirmasi kata sandi tidak sama.';
    } else if (baru == lama) {
      err = 'Kata sandi baru harus berbeda dari yang lama.';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await Get.find<ProfileController>().changePassword(lama, baru);
    if (!mounted) return;
    if (result == null) {
      Get.back();
      showSnack('Kata sandi berhasil diubah.');
    } else {
      setState(() {
        _busy = false;
        _error = result;
      });
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _hide = !_hide),
          tooltip: _hide ? 'Tampilkan' : 'Sembunyikan',
          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Padding(
      // Naikkan sheet saat keyboard muncul.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Ubah kata sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _lama, obscureText: _hide, decoration: _decoration('Kata sandi lama')),
            gap,
            TextField(controller: _baru, obscureText: _hide, decoration: _decoration('Kata sandi baru')),
            gap,
            TextField(controller: _ulang, obscureText: _hide, decoration: _decoration('Ulangi kata sandi baru')),
            if (_error != null) ErrorBox(_error!),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Simpan', icon: Icons.check_rounded, loading: _busy, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}