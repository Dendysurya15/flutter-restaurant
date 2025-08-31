import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';

// payment_controller.dart
class PaymentController extends GetxController {
  final OrderModel order;
  final PaymentModel payment;
  final PaymentService paymentService = Get.find<PaymentService>();

  PaymentController({required this.order, required this.payment});

  // Countdown timer (15 minutes = 900 seconds)
  final countdownSeconds = 900.obs;
  final isExpired = false.obs;
  final isProcessingPayment = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds.value > 0) {
        countdownSeconds.value--;
      } else {
        timer.cancel();
        isExpired.value = true;
        handlePaymentExpired();
      }
    });
  }

  void handlePaymentExpired() {
    ToastHelper.showToast(
      context: Get.context!,
      title: 'Payment Expired',
      description: 'Your payment time has expired. Please try again.',
      type: ToastificationType.error,
    );

    // Navigate back to cart or home
    Get.offAllNamed(Routes.HOME);
  }

  void showExitDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Your order will be cancelled if you leave this page.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Stay')),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offAllNamed('/home'); // Go to home
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
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
        _timer?.cancel();

        ToastHelper.showToast(
          context: Get.context!,
          title: 'Payment Success',
          description: result['message'],
          type: ToastificationType.success,
        );

        Get.offAllNamed('/orders');
      } else {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Payment Failed',
          description: result['message'],
          type: ToastificationType.error,
        );
      }
    } finally {
      isProcessingPayment.value = false;
    }
  }

  String get formattedTime {
    final minutes = countdownSeconds.value ~/ 60;
    final seconds = countdownSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
