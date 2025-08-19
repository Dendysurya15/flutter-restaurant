import 'package:get/get.dart';
import 'package:restaurant/app/modules/store/controllers/store_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreController>(() => StoreController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
