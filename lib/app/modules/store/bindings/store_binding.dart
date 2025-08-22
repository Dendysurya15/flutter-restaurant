import 'package:get/get.dart';
import 'package:restaurant/app/services/menu_service.dart';
import '../controllers/store_controller.dart';
import '../controllers/store_detail_controller.dart';
import '../controllers/category_form_controller.dart';
import '../controllers/menu_item_form_controller.dart';

class StoreBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<MenuService>(() => MenuService());

    // Controllers
    Get.lazyPut<StoreController>(() => StoreController());
    Get.lazyPut<StoreDetailController>(() => StoreDetailController());
    Get.lazyPut<CategoryFormController>(() => CategoryFormController());
    Get.lazyPut<MenuItemFormController>(() => MenuItemFormController());
  }
}
