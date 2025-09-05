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

  // Timer observables
  final isProcessingPayment = false.obs;
  final countdownSeconds = 0.obs;
  final isExpired = false.obs;
  PaymentTimerData? timerData;

  @override
  void onInit() {
    super.onInit();

    // Wait until after the first frame to initialize timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimer();
    });
  }

  void _initializeTimer() {
    final args = Get.arguments as Map<String, dynamic>?;
    timerData = args?['timer_data'] ?? timerService.getPaymentTimer(payment.id);

    // Use payment.createdAt instead of order.createdAt
    final timeSincePaymentCreated = DateTime.now().difference(
      payment.createdAt,
    );
    final actualRemainingSeconds =
        900 - timeSincePaymentCreated.inSeconds; // 15 minutes

    print('🕐 Payment created at: ${payment.createdAt}');
    print('🕐 Current time: ${DateTime.now()}');
    print(
      '🕐 Time since payment created: ${timeSincePaymentCreated.inSeconds} seconds',
    );
    print('🕐 Remaining seconds: $actualRemainingSeconds');

    if (actualRemainingSeconds <= 0) {
      print('⚠️ Payment already expired');
      countdownSeconds.value = 0;
      isExpired.value = true;
    } else if (timerData == null) {
      print('▶️ Starting timer with $actualRemainingSeconds seconds');
      timerService.startPaymentTimer(
        order: order,
        payment: payment,
        durationInSeconds: actualRemainingSeconds,
      );
      timerData = timerService.getPaymentTimer(payment.id);

      // Link the timer data to local observables
      if (timerData != null) {
        countdownSeconds.value = timerData!.remainingSeconds.value;
        isExpired.value = timerData!.isExpired.value;

        // Listen to timer updates
        ever(timerData!.remainingSeconds, (seconds) {
          countdownSeconds.value = seconds;
        });

        ever(timerData!.isExpired, (expired) {
          isExpired.value = expired;
        });
      }
    } else {
      // Timer already exists, link to it
      countdownSeconds.value = timerData!.remainingSeconds.value;
      isExpired.value = timerData!.isExpired.value;

      // Listen to timer updates
      ever(timerData!.remainingSeconds, (seconds) {
        countdownSeconds.value = seconds;
      });

      ever(timerData!.isExpired, (expired) {
        isExpired.value = expired;
      });
    }
  }

  @override
  void onClose() {
    // Don't cancel timer here - let it continue globally
    super.onClose();
  }

  String get formattedTime {
    final minutes = countdownSeconds.value ~/ 60;
    final seconds = countdownSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Add getter for order time formatting
  String get orderTimeFormatted {
    return _formatDateTime(order.createdAt);
  }

  String get paymentTimeFormatted {
    return _formatDateTime(payment.createdAt);
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: "5 Sep 2025, 20:44"
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
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
