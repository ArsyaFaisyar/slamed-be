import 'package:get/get.dart';
import 'package:slamed_app/app/app_routes.dart';
import 'package:slamed_app/app/auth_middleware.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:slamed_app/features/auth/presentation/pages/login_page.dart';
import 'package:slamed_app/features/auth/presentation/pages/splash_page.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/home/presentation/controller/home_controller.dart';
import 'package:slamed_app/features/home/presentation/page/home_shell.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_controller.dart';
import 'package:slamed_app/features/lkh/presentation/controller/lkh_form_controller.dart';
import 'package:slamed_app/features/lkh/presentation/pages/lkh_form_page.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_controller.dart';
import 'package:slamed_app/features/rkh/presentation/controllers/rkh_form_controller.dart';
import 'package:slamed_app/features/rkh/presentation/pages/rkh_form_page.dart';
import 'package:slamed_app/features/project/presentation/controllers/prospect_controller.dart';


abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => LoginController(Get.find<AuthController>()))),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeShell(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController(Get.find<AuthController>()));
        Get.lazyPut(
          () => RkhController(Get.find<AuthController>(), Get.find<RkhRepository>(), Get.find<LkhRepository>(), Get.find<CustomerRepository>()),
          fenix: true,
        );
        Get.lazyPut(
          () => LkhController(Get.find<AuthController>(), Get.find<RkhRepository>(), Get.find<LkhRepository>(), Get.find<CustomerRepository>()),
          fenix: true,
        );
        Get.lazyPut(
          () => ProspectController(Get.find<ProjectRepository>(), Get.find<CustomerRepository>()),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: AppRoutes.rkhForm,
      page: () => const RkhFormPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(
        () => Get.lazyPut(() => RkhFormController(Get.find<CustomerRepository>(), Get.find<ProjectRepository>(), Get.find<RkhRepository>())),
      ),
    ),
    GetPage(
      name: AppRoutes.lkhForm,
      page: () => const LkhFormPage(),
      middlewares: [AuthMiddleware()],
      binding: BindingsBuilder(() => Get.lazyPut(() => LkhFormController(Get.find<LkhRepository>()))),
    ),
  ];
}