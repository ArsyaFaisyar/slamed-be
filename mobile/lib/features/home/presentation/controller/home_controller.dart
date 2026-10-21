import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:slamed_app/core/constants/roles.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_controller.dart';
import 'package:slamed_app/features/lkh/presentation/pages/lkh_page.dart';
import 'package:slamed_app/features/profile/presentation/pages/profile_page.dart';
import 'package:slamed_app/features/project/presentation/pages/prospect_page.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_controller.dart';
import 'package:slamed_app/features/rkh/presentation/pages/rkh_page.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.selectedIcon, this.page, {this.onShow});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  /// Dipanggil setiap tab dipilih (mis. muat ulang data agar tidak basi).
  final VoidCallback? onShow;
}

/// Shell navigasi: satu-satunya controller yang boleh mengenal controller tab lain.
class HomeController extends GetxController {
  HomeController(this._auth);
  final AuthController _auth;

  final index = 0.obs;
  late final List<NavItem> items = _itemsFor(_auth.role);

  void select(int i) {
    index.value = i;
    items[i].onShow?.call();
  }

  /// Menu per role. Menyembunyikan menu BUKAN otorisasi; backend tetap penentu
  /// dan 403 ditampilkan lewat pesan error di tiap layar.
  List<NavItem> _itemsFor(String? role) {
    const dashboard = NavItem('Beranda', Icons.home_outlined, Icons.home_rounded, DashboardPage());
    const profile = NavItem('Profil', Icons.person_outline, Icons.person_rounded, ProfilePage());
    if (Roles.isField(role)) {
      return [
        dashboard,
        NavItem('RKH', Icons.calendar_month_outlined, Icons.calendar_month_rounded, const RkhPage(),
            onShow: () => Get.find<RkhController>().load()),
        NavItem('LKH', Icons.fact_check_outlined, Icons.fact_check_rounded, const LkhPage(),
            onShow: () => Get.find<LkhController>().load()),
        const NavItem('Prospek', Icons.trending_up, Icons.trending_up_rounded, ProspectPage()),
        profile,
      ];
    }
    // SUPERADMIN, PPIC, ADMIN_*: menunggu endpoint di OpenAPI.
    return [dashboard, profile];
  }
}