import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:restaurant/app/services/order_service.dart';

class PaymentController extends GetxController {
  final OrderModel order;
  final PaymentModel payment;
  final PaymentService paymentService = Get.find<PaymentService>();
  final PaymentTimerService timerService = Get.find<PaymentTimerService>();
  final OrderService orderService = Get.find<OrderService>();

  PaymentController({required this.order, required this.payment});

  // Timer observables
  final isProcessingPayment = false.obs;
  final countdownSeconds = 0.obs;
  final isExpired = false.obs;
  final isPaymentUILaunched = false.obs;
  PaymentTimerData? timerData;

  // WebView observables
  final showPaymentWebView = false.obs;
  final paymentWebViewUrl = ''.obs;
  final isWebViewLoading = true.obs;
  WebViewController? webViewController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimer();
      _autoLaunchPaymentUI();
    });
  }

  void _initializeTimer() {
    final args = Get.arguments as Map<String, dynamic>?;
    timerData = args?['timer_data'] ?? timerService.getPaymentTimer(payment.id);

    final timeSincePaymentCreated = DateTime.now().difference(
      payment.createdAt,
    );
    final actualRemainingSeconds = 900 - timeSincePaymentCreated.inSeconds;

    print('Payment created at: ${payment.createdAt}');
    print(
      'Time since payment created: ${timeSincePaymentCreated.inSeconds} seconds',
    );
    print('Remaining seconds: $actualRemainingSeconds');

    if (actualRemainingSeconds <= 0) {
      countdownSeconds.value = 0;
      isExpired.value = true;
    } else if (timerData == null) {
      timerService.startPaymentTimer(
        order: order,
        payment: payment,
        durationInSeconds: actualRemainingSeconds,
      );
      timerData = timerService.getPaymentTimer(payment.id);

      if (timerData != null) {
        countdownSeconds.value = timerData!.remainingSeconds.value;
        isExpired.value = timerData!.isExpired.value;

        ever(timerData!.remainingSeconds, (seconds) {
          countdownSeconds.value = seconds;
        });

        ever(timerData!.isExpired, (expired) {
          isExpired.value = expired;
          if (expired) {
            _handlePaymentExpired();
          }
        });
      }
    } else {
      countdownSeconds.value = timerData!.remainingSeconds.value;
      isExpired.value = timerData!.isExpired.value;

      ever(timerData!.remainingSeconds, (seconds) {
        countdownSeconds.value = seconds;
      });

      ever(timerData!.isExpired, (expired) {
        isExpired.value = expired;
        if (expired) {
          _handlePaymentExpired();
        }
      });
    }
  }

  void _autoLaunchPaymentUI() async {
    if (isExpired.value || isPaymentUILaunched.value) return;

    print('Auto launching payment UI...');
    isPaymentUILaunched.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    processPayment();
  }

  void _handlePaymentExpired() {
    print('Payment expired - closing WebView');
    closePaymentWebView();

    Get.dialog(
      AlertDialog(
        title: const Text('Payment Expired'),
        content: const Text(
          'Your payment time has expired. Please place a new order.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _initializeWebView(String url) {
    paymentWebViewUrl.value = url;
    isWebViewLoading.value = true;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('WebView page started: $url');
            isWebViewLoading.value = true;
          },
          onPageFinished: (String url) {
            print('WebView page finished: $url');
            isWebViewLoading.value = false;
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            isWebViewLoading.value = false;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    showPaymentWebView.value = true;
  }

  void _checkPaymentStatus(String url) {
    print('Checking payment status from URL: $url');

    // Success patterns
    if (url.contains('status_code=200') ||
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture') ||
        url.contains('simulator.sandbox.midtrans.com/v2/deeplink/payment') ||
        url.contains('deeplink/payment') ||
        url.contains('payment_success') ||
        url.contains('success')) {
      _handlePaymentResult({
        'success': true,
        'status': 'completed',
        'message': 'Payment completed successfully',
      });
    }
    // Pending patterns
    else if (url.contains('status_code=201') ||
        url.contains('transaction_status=pending')) {
      _handlePaymentResult({
        'success': true,
        'status': 'pending',
        'message': 'Payment is being processed',
      });
    }
    // Failure/cancellation patterns
    else if (url.contains('status_code=202') ||
        url.contains('transaction_status=cancel') ||
        url.contains('transaction_status=deny') ||
        url.contains('cancel') ||
        url.contains('failed') ||
        url.contains('error')) {
      _handlePaymentResult({
        'success': false,
        'status': 'cancelled',
        'message': 'Payment was cancelled or failed',
      });
    }
  }

  void _handlePaymentResult(Map<String, dynamic> result) async {
    print('Handling payment result: $result');
    closePaymentWebView();

    if (result['success'] == true) {
      final status = result['status'];

      if (status == 'completed') {
        await orderService.updatePaymentStatus(
          paymentId: payment.id,
          status: 'completed',
          transactionId: 'midtrans_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Update order status to 'pending' (waiting for restaurant to accept)
        await orderService.updateOrderAndPaymentStatus(
          orderId: payment.orderId,
          orderStatus: 'pending', // Restaurant needs to accept first
          paymentStatus: 'paid',
        );

        timerService.stopPaymentTimer(payment.id);

        Get.snackbar(
          'Payment Success',
          'Payment completed! Your order is now waiting for restaurant confirmation.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        Get.offAllNamed(Routes.HOME);
      } else if (status == 'pending') {
        await orderService.updatePaymentStatus(
          paymentId: payment.id,
          status: 'pending',
          transactionId: 'midtrans_${DateTime.now().millisecondsSinceEpoch}',
        );

        Get.snackbar(
          'Payment Pending',
          result['message'],
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } else {
      await orderService.updatePaymentStatus(
        paymentId: payment.id,
        status: 'failed',
      );

      if (result['status'] == 'cancelled') {
        isPaymentUILaunched.value = false;
        Get.snackbar(
          'Payment Cancelled',
          'You can try payment again',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Payment Failed',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

    isProcessingPayment.value = false;
  }

  void closePaymentWebView() {
    showPaymentWebView.value = false;
    paymentWebViewUrl.value = '';
    webViewController = null;
    isWebViewLoading.value = false;
  }

  void processPayment() async {
    if (isProcessingPayment.value || isExpired.value) return;

    isProcessingPayment.value = true;

    try {
      print('Starting payment process for method: ${payment.paymentMethod}');

      final result = await paymentService.processPayment(
        payment: payment,
        orderData: {'order': order},
      );

      if (result['success'] == true && result['status'] == 'token_ready') {
        final paymentUrl = result['payment_url'];
        print('Opening payment WebView: $paymentUrl');
        _initializeWebView(paymentUrl);
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      print('Payment error: $e');
      isProcessingPayment.value = false;

      Get.snackbar(
        'Payment Error',
        'Failed to load payment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void retryPayment() {
    if (isExpired.value) return;
    closePaymentWebView();
    isPaymentUILaunched.value = false;
    processPayment();
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
              closePaymentWebView();
              Get.back();
              Get.back();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
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
              Get.back();

              try {
                await paymentService.updateOrderStatus(order.id, 'cancelled');
                timerService.stopPaymentTimer(payment.id);
                closePaymentWebView();

                Get.snackbar(
                  'Order Cancelled',
                  'Your order has been cancelled',
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );

                Get.offAllNamed(Routes.HOME);
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to cancel order',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
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

  String get formattedTime {
    final minutes = countdownSeconds.value ~/ 60;
    final seconds = countdownSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get orderTimeFormatted {
    return _formatDateTime(order.createdAt);
  }

  String get paymentTimeFormatted {
    return _formatDateTime(payment.createdAt);
  }

  String _formatDateTime(DateTime dateTime) {
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

  @override
  void onClose() {
    closePaymentWebView();
    super.onClose();
  }
}
