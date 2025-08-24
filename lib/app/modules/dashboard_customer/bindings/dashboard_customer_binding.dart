import 'package:get/get.dart';
import 'package:restaurant/app/modules/cart_item/controllers/cart_item_controller.dart';
import 'package:restaurant/app/modules/dashboard_customer/controllers/search_store_controller.dart';

import '../controllers/dashboard_customer_controller.dart';

class DashboardCustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardCustomerController>(
      () => DashboardCustomerController(),
    );
    Get.lazyPut<SearchStoreController>(() => SearchStoreController());
    Get.lazyPut<CartItemController>(() => CartItemController());
  }
}
