import 'package:get/get.dart';

import '../controllers/admin_manage_store_controller.dart';

class AdminManageStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminManageStoreController>(
      () => AdminManageStoreController(),
    );
  }
}
