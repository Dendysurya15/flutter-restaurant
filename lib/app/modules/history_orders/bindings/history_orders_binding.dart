import 'package:get/get.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:restaurant/app/services/order_service.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';

import '../controllers/history_orders_controller.dart';

class HistoryOrdersBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure required services are available before creating controller
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }

    if (!Get.isRegistered<PaymentTimerService>()) {
      Get.put(PaymentTimerService(), permanent: true);
    }

    if (!Get.isRegistered<OrderService>()) {
      Get.put(OrderService(), permanent: true);
    }

    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService(), permanent: true);
    }

    // Now create the controller
    Get.lazyPut<HistoryOrdersController>(() => HistoryOrdersController());
  }
}
