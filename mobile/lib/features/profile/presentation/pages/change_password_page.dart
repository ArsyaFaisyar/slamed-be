import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/app_constant.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/profile/presentation/controllers/change_password_controller.dart';
import 'package:slamed_app/shared/widgets/app_card.dart';
import 'package:slamed_app/shared/widgets/app_scaffold.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';

class ChangePasswordPage extends GetView<ChangePasswordController> {
  const ChangePasswordPage({super.key});

  Widget _field({
    required TextEditingController controller,
    required RxBool hidden,
    required String label,
    String? helper,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmit,
  }) =>
      Obx(() => TextField(
            controller: controller,
            obscureText: hidden.value,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: action,
            onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: hidden.toggle,
                tooltip: hidden.value ? 'Tampilkan password' : 'Sembunyikan password',
                icon: Icon(hidden.value ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ));

  @override
  Widget build(BuildContext context) {
    final c = controller;
    const gap = SizedBox(height: 14);
    return AppScaffold(
      title: 'Ubah password',
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() => PrimaryButton(
                label: 'Simpan password',
                icon: Icons.check_rounded,
                loading: c.busy.value,
                onPressed: c.submit,
              )),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        AppCard(
          child: Column(children: [
            _field(controller: c.lama, hidden: c.hideLama, label: 'Password lama'),
            gap,
            _field(
              controller: c.baru,
              hidden: c.hideBaru,
              label: 'Password baru',
              helper: 'Minimal ${AppConstants.minPasswordLength} karakter',
            ),
            gap,
            _field(
              controller: c.konfirmasi,
              hidden: c.hideKonfirmasi,
              label: 'Ulangi password baru',
              action: TextInputAction.done,
              onSubmit: c.submit,
            ),
          ]),
        ),
        Obx(() {
          final e = c.error.value;
          if (e == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline, size: 18, color: AppColors.dangerFg),
              const SizedBox(width: 8),
              Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: AppColors.dangerFg))),
            ]),
          );
        }),
      ]),
    );
  }
}