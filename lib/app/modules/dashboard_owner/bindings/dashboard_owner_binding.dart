import 'package:get/get.dart';

import '../controllers/dashboard_owner_controller.dart';

class DashboardOwnerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardOwnerController>(
      () => DashboardOwnerController(),
    );
  }
}
