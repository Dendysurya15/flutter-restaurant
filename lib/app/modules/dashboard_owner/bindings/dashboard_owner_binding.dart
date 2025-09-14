import 'package:get/get.dart';
import 'package:restaurant/app/services/notification_service.dart';
import '../controllers/dashboard_owner_controller.dart';

class DashboardOwnerBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize NotificationService first
    Get.put<NotificationService>(NotificationService());

    // Then initialize the controller
    Get.lazyPut<DashboardOwnerController>(() => DashboardOwnerController());
  }
}
