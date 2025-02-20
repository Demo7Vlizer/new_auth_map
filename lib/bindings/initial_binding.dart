import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/profile_controller.dart';
import '../core/services/session_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final sessionService = SessionService();
    Get.put(sessionService, permanent: true);
    Get.put(AuthController(sessionService: sessionService), permanent: true);
    Get.put(MapController(), permanent: true);
    Get.lazyPut(() => ProfileController());
  }
} 