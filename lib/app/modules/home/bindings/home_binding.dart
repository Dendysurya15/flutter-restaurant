import 'package:get/get.dart';
import 'package:restaurant/app/modules/store/controllers/store_controller.dart';
import 'package:restaurant/app/modules/admin_manage_store/controllers/admin_manage_store_controller.dart';
import 'package:restaurant/app/modules/dashboard_customer/controllers/dashboard_customer_controller.dart';
import 'package:restaurant/app/modules/dashboard_owner/controllers/dashboard_owner_controller.dart'; // Add this import
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/services/menu_service.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreController>(() => StoreController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<AdminManageStoreController>(() => AdminManageStoreController());
    Get.lazyPut<DashboardCustomerController>(
      () => DashboardCustomerController(),
    );
    Get.lazyPut<DashboardOwnerController>(
      // Add this line
      () => DashboardOwnerController(),
    );
    Get.lazyPut<CartService>(() => CartService());
    Get.lazyPut<MenuService>(() => MenuService());
  }
}
