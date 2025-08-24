import 'package:get/get.dart';

import '../controllers/purchased_store_detail_controller.dart';

class PurchasedStoreDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchasedStoreDetailController>(
      () => PurchasedStoreDetailController(),
    );
  }
}
