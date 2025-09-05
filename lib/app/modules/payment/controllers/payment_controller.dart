// app/modules/payment/controllers/payment_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:toastification/toastification.dart';

class PaymentController extends GetxController {
  final OrderModel order;
  final PaymentModel payment;
  final PaymentService paymentService = Get.find<PaymentService>();
  final PaymentTimerService timerService = Get.find<PaymentTimerService>();

  PaymentController({required this.order, required this.payment});

  // Timer observables - now linked to global service
  final isProcessingPayment = false.obs;
  PaymentTimerData? timerData;

  @override
  void onInit() {
    super.onInit();

    // Get timer data from arguments or global service
    final args = Get.arguments as Map<String, dynamic>?;
    timerData = args?['timer_data'] ?? timerService.getPaymentTimer(payment.id);

    // Check if payment is already expired when opening the page
    final timeSinceOrderCreated = DateTime.now().difference(order.createdAt);
    final actualRemainingSeconds = 900 - timeSinceOrderCreated.inSeconds;

    if (actualRemainingSeconds <= 0) {
      // Payment is expired - don't start timer
      timerData = null;
    } else if (timerData == null) {
      // Start timer with actual remaining time
      timerService.startPaymentTimer(
        order: order,
        payment: payment,
        durationInSeconds: actualRemainingSeconds,
      );
      timerData = timerService.getPaymentTimer(payment.id);
    }
  }

  @override
  void onClose() {
    // Don't cancel timer here - let it continue globally
    super.onClose();
  }

  // Getters that reference the global timer
  RxInt get countdownSeconds => timerData?.remainingSeconds ?? 0.obs;
  RxBool get isExpired => timerData?.isExpired ?? false.obs;

  String get formattedTime {
    if (timerData == null) return '00:00';
    return timerService.formatTime(timerData!.remainingSeconds.value);
  }

  void showExitDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Leave Payment?'),
        content: const Text(
          'Your payment timer will continue running. You can return to complete payment from your order history.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Stay')),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous page
            },
            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void processPayment() async {
    if (isProcessingPayment.value) return;

    isProcessingPayment.value = true;

    try {
      final result = await paymentService.processPayment(
        payment: payment,
        orderData: {'order': order},
      );

      if (result['success']) {
        // Stop the timer since payment is successful
        timerService.stopPaymentTimer(payment.id);

        ToastHelper.showToast(
          context: Get.context!,
          title: 'Payment Success',
          description: result['message'],
          type: ToastificationType.success,
        );

        // Navigate to order history or success page
        Get.offAllNamed(Routes.HOME);
      } else {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Payment Failed',
          description: result['message'],
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      ToastHelper.showToast(
        context: Get.context!,
        title: 'Payment Error',
        description:
            'An error occurred while processing payment. Please try again.',
        type: ToastificationType.error,
      );
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void cancelPayment() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'This will cancel your order and you will need to place a new order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog

              try {
                // Update order status to cancelled
                await paymentService.updateOrderStatus(order.id, 'cancelled');

                // Stop timer
                timerService.stopPaymentTimer(payment.id);

                ToastHelper.showToast(
                  context: Get.context!,
                  title: 'Order Cancelled',
                  description: 'Your order has been cancelled.',
                  type: ToastificationType.info,
                );

                Get.offAllNamed(Routes.HOME);
              } catch (e) {
                ToastHelper.showToast(
                  context: Get.context!,
                  title: 'Error',
                  description: 'Failed to cancel order. Please try again.',
                  type: ToastificationType.error,
                );
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
