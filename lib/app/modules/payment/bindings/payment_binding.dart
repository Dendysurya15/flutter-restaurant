import 'package:get/get.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    // Get the arguments passed from navigation
    final arguments = Get.arguments as Map<String, dynamic>;
    final order = arguments['order'];
    final payment = arguments['payment'];

    Get.lazyPut<PaymentController>(
      () => PaymentController(order: order, payment: payment),
    );
  }
}
