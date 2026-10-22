import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/theme/app_colors.dart';
import 'package:slamed_app/features/home/presentation/controller/home_controller.dart';

class HomeShell extends GetView<HomeController> {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final i = c.index.value;
      return Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey<int>(i), child: c.items[i].page),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
          child: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: c.select,
            destinations: [
              for (final t in c.items)
                NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
            ],
          ),
        ),
      );
    });
  }
}