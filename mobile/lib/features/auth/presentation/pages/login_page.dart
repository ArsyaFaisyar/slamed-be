import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:slamed_app/shared/widgets/fade_slide_in.dart';
import 'package:slamed_app/shared/widgets/primary_button.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Stack(children: [
          // Glow dekoratif di pojok kanan atas.
          Positioned(
            top: -120,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.glow, Color(0x005DA9FF)]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeSlideIn(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ShaderMask(
                        shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
                        child: const Text(
                          'SLAMED',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Sales Management System', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 10))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Text('Masuk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          const Text('Gunakan akun Slamed Anda', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: c.username,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                          ),
                          const SizedBox(height: 14),
                          Obx(() => TextField(
                                controller: c.password,
                                obscureText: c.obscure.value,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: c.toggleObscure,
                                    tooltip: c.obscure.value ? 'Tampilkan password' : 'Sembunyikan password',
                                    icon: Icon(c.obscure.value ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              const Icon(Icons.shield_outlined, size: 20, color: AppColors.muted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => Text(
                                      c.captcha.value?.question ?? 'Memuat CAPTCHA...',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    )),
                              ),
                              IconButton(onPressed: c.loadCaptcha, icon: const Icon(Icons.refresh_rounded), tooltip: 'Ganti CAPTCHA'),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: c.answer,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => c.submit(),
                            decoration: const InputDecoration(labelText: 'Jawaban CAPTCHA', prefixIcon: Icon(Icons.calculate_outlined)),
                          ),
                          Obx(() {
                            final e = c.error.value;
                            if (e == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Icon(Icons.error_outline, size: 18, color: AppColors.dangerFg),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: AppColors.dangerFg))),
                              ]),
                            );
                          }),
                          const SizedBox(height: 20),
                          Obx(() => PrimaryButton(
                                label: 'Masuk',
                                icon: Icons.login_rounded,
                                loading: c.busy.value,
                                onPressed: c.submit,
                              )),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      const Text('Amazink People Group',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}