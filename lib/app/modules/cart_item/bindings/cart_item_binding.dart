import 'package:get/get.dart';

import '../controllers/cart_item_controller.dart';

class CartItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CartItemController>(
      () => CartItemController(),
    );
  }
}
