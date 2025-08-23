import 'package:get/get.dart';
import 'package:restaurant/app/modules/store/controllers/store_controller.dart';
import 'package:restaurant/app/modules/admin_manage_store/controllers/admin_manage_store_controller.dart';
import 'package:restaurant/app/modules/dashboard_customer/controllers/dashboard_customer_controller.dart'; // Add this import

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreController>(() => StoreController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<AdminManageStoreController>(() => AdminManageStoreController());
    Get.lazyPut<DashboardCustomerController>(
      () => DashboardCustomerController(),
    ); // Add this line
  }
}
