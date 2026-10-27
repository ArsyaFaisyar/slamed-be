import 'package:get/get.dart';
import 'package:slamed_app/core/storage/session_store.dart';
import 'package:slamed_app/core/network/api_client.dart';
import 'package:slamed_app/features/auth/data/auth_repository.dart';
import 'package:slamed_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:slamed_app/features/customer/data/customer_repository.dart';
import 'package:slamed_app/features/lkh/data/lkh_repository.dart';
import 'package:slamed_app/features/profile/data/profile_repository.dart';
import 'package:slamed_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:slamed_app/features/project/data/project_repository.dart';
import 'package:slamed_app/features/rkh/data/rkh_repository.dart';
import 'package:slamed_app/features/project/data/project_status_repository.dart';

/// Satu-satunya tempat dependency global dirakit. Controller menerima
/// repository lewat constructor, bukan membuat ApiClient sendiri.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final session = SessionStore();
    final api = ApiClient(session);
    final profileRepository = ProfileRepository(api);

    Get.put<CustomerRepository>(CustomerRepository(api), permanent: true);
    Get.put<ProjectRepository>(ProjectRepository(api), permanent: true);
    Get.put<RkhRepository>(RkhRepository(api), permanent: true);
    Get.put<LkhRepository>(LkhRepository(api), permanent: true);
    Get.put<ProfileRepository>(profileRepository, permanent: true);
    Get.put<ProjectStatusRepository>(ProjectStatusRepository(api), permanent: true);
    Get.put<AuthController>(
      AuthController(
        session: session,
        api: api,
        authRepository: AuthRepository(api),
        profileRepository: profileRepository,
      ),
      permanent: true,
    );
    // Dipakai halaman Profil, baik sebagai tab maupun sebagai rute /profile.
    Get.lazyPut<ProfileController>(
      () => ProfileController(Get.find<ProfileRepository>(), Get.find<AuthController>()),
      fenix: true,
    );
  }
}