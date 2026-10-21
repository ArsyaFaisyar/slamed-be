import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/app/app_pages.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/core/theme/app_theme.dart';
import 'package:slamed_app/app/initial_binding.dart';

class SlamedApp extends StatelessWidget {
  const SlamedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Slamed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}