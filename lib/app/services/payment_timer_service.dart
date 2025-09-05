// app/services/payment_timer_service.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/order_service.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:toastification/toastification.dart';

class PaymentTimerService extends GetxService {
  final OrderService orderService = Get.find<OrderService>();
  static PaymentTimerService get to => Get.find();

  final PaymentService paymentService = Get.find<PaymentService>();

  // Active payment timers
  final Map<String, PaymentTimerData> _activeTimers = {};

  // Observable for UI updates
  final activePayments = <PaymentTimerData>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load any existing pending payments from local storage or API
    loadPendingPayments();
  }

  @override
  void onClose() {
    // Cancel all timers
    for (var timerData in _activeTimers.values) {
      timerData.timer?.cancel();
    }
    _activeTimers.clear();
    super.onClose();
  }

  void startPaymentTimer({
    required OrderModel order,
    required PaymentModel payment,
    int durationInSeconds = 900, // 15 minutes default
  }) {
    final timerId = payment.id;

    // Cancel existing timer if any
    stopPaymentTimer(timerId);

    final timerData = PaymentTimerData(
      orderId: order.id,
      paymentId: payment.id,
      order: order,
      payment: payment,
      remainingSeconds: durationInSeconds.obs,
      isExpired: false.obs,
    );

    // Start countdown
    timerData.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerData.remainingSeconds.value > 0) {
        timerData.remainingSeconds.value--;
      } else {
        timer.cancel();
        timerData.isExpired.value = true;
        _handlePaymentExpired(timerData);
      }
    });

    _activeTimers[timerId] = timerData;
    _updateActivePaymentsList();
  }

  void stopPaymentTimer(String paymentId) {
    final timerData = _activeTimers[paymentId];
    if (timerData != null) {
      timerData.timer?.cancel();
      _activeTimers.remove(paymentId);
      _updateActivePaymentsList();
    }
  }

  PaymentTimerData? getPaymentTimer(String paymentId) {
    return _activeTimers[paymentId];
  }

  bool hasActivePayment(String paymentId) {
    return _activeTimers.containsKey(paymentId);
  }

  int get totalPendingPayments => _activeTimers.length;

  void _handlePaymentExpired(PaymentTimerData timerData) async {
    // Update payment status to expired
    try {
      await orderService.updatePaymentStatus(
        paymentId: timerData.paymentId,
        status: 'expired',
      );

      // Update order status to cancelled
      await paymentService.updateOrderStatus(timerData.orderId, 'cancelled');

      ToastHelper.showToast(
        context: Get.context!,
        title: 'Payment Expired',
        description:
            'Order ${timerData.order.orderNumber} payment has expired.',
        type: ToastificationType.warning,
      );
    } catch (e) {
      print('Error updating expired payment: $e');
    }

    // Remove from active timers
    _activeTimers.remove(timerData.paymentId);
    _updateActivePaymentsList();
  }

  void _updateActivePaymentsList() {
    activePayments.value = _activeTimers.values.toList();
  }

  Future<void> loadPendingPayments() async {
    try {
      // Load pending payments from API
      final pendingPayments = await paymentService.getPendingPayments();

      for (var paymentData in pendingPayments) {
        final order = paymentData['order'] as OrderModel;
        final payment = paymentData['payment'] as PaymentModel;
        final remainingTime = paymentData['remaining_seconds'] as int;

        if (remainingTime > 0) {
          startPaymentTimer(
            order: order,
            payment: payment,
            durationInSeconds: remainingTime,
          );
        }
      }
    } catch (e) {
      print('Error loading pending payments: $e');
    }
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class PaymentTimerData {
  final String orderId;
  final String paymentId;
  final OrderModel order;
  final PaymentModel payment;
  final RxInt remainingSeconds;
  final RxBool isExpired;
  Timer? timer;

  PaymentTimerData({
    required this.orderId,
    required this.paymentId,
    required this.order,
    required this.payment,
    required this.remainingSeconds,
    required this.isExpired,
    this.timer,
  });

  String get formattedTime {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
