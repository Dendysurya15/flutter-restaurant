import 'package:get/get.dart';
import 'package:restaurant/app/modules/cart_item/controllers/cart_item_controller.dart';

import '../controllers/purchased_store_detail_controller.dart';

class PurchasedStoreDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchasedStoreDetailController>(
      () => PurchasedStoreDetailController(),
    );
    Get.put<CartItemController>(CartItemController(), permanent: true);
  }
}
