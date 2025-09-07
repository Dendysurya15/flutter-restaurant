import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.showExitDialog(),
        ),
      ),
      body: Column(
        children: [
          // Countdown Timer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Obx(() {
                  final isExpired = controller.countdownSeconds.value <= 0;
                  return Text(
                    isExpired ? 'Payment Time' : 'Complete Payment Within',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  );
                }),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.countdownSeconds.value <= 0
                        ? 'EXPIRED'
                        : controller.formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content - Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 20),

                  // Payment Methods Card
                  _buildPaymentMethodsCard(),
                  const SizedBox(height: 20),

                  // WebView Payment Section
                  Obx(() {
                    final showWebView = controller.showPaymentWebView.value;
                    final webViewUrl = controller.paymentWebViewUrl.value;
                    final isExpired = controller.countdownSeconds.value <= 0;

                    if (showWebView && webViewUrl.isNotEmpty && !isExpired) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate dynamic height based on screen size
                          final screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          final availableHeight =
                              screenHeight -
                              400; // Subtract space for timer, cards, etc.
                          final webViewHeight = (availableHeight * 0.7).clamp(
                            300.0,
                            500.0,
                          ); // 70% of available space, min 300px, max 500px

                          return Container(
                            height: MediaQuery.of(context).size.height * 0.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                children: [
                                  // WebView Header
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.payment,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Complete Your Payment',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Obx(
                                            () => Text(
                                              controller.formattedTime,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // WebView Content with proper scrolling
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          if (controller.webViewController !=
                                              null)
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    bottomLeft: Radius.circular(
                                                      10,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(10),
                                                  ),
                                              child: WebViewWidget(
                                                controller: controller
                                                    .webViewController!,
                                              ),
                                            ),

                                          // Loading indicator
                                          Obx(() {
                                            if (!controller
                                                .isWebViewLoading
                                                .value) {
                                              return const SizedBox.shrink();
                                            }

                                            return Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    10,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    10,
                                                  ),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      'Loading payment interface...',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'This may take a few seconds',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),

                  const SizedBox(height: 20),

                  // Retry Payment Button (only show when WebView is not active)
                  Obx(() {
                    final showWebView = controller.showPaymentWebView.value;
                    final isExpired = controller.countdownSeconds.value <= 0;
                    final isProcessing = controller.isProcessingPayment.value;
                    final isLaunched = controller.isPaymentUILaunched.value;

                    // Don't show button when WebView is active
                    if (showWebView) return const SizedBox.shrink();

                    return SizedBox(
                      width: double.infinity,
                      child: () {
                        if (isExpired) {
                          return ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Payment Expired',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        if (isProcessing) {
                          return ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading Payment...',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        return ElevatedButton(
                          onPressed: controller.retryPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isLaunched ? 'Retry Payment' : 'Continue Payment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }(),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Time Row
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.blue.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.orderTimeFormatted,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildInfoRow('Order #', controller.order.orderNumber),
            _buildInfoRow(
              'Type',
              controller.order.orderType == 'dine_in' ? 'Dine In' : 'Delivery',
            ),
            _buildInfoRow('Customer', controller.order.customerName),
            if (controller.order.deliveryAddress != null)
              _buildInfoRow('Address', controller.order.deliveryAddress!),

            const Divider(height: 24),

            // Payment Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        'Rp.${controller.order.subtotal.toInt()}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  if (controller.order.deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          'Rp.${controller.order.deliveryFee.toInt()}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rp.${controller.order.totalAmount.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Obx(() {
      final isExpired = controller.countdownSeconds.value <= 0;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired
                        ? Colors.grey.shade300
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.grey.withOpacity(0.1)
                            : _getPaymentMethodColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentMethodIcon(),
                        color: isExpired
                            ? Colors.grey
                            : _getPaymentMethodColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPaymentMethodName(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.grey : Colors.black,
                            ),
                          ),
                          Text(
                            isExpired
                                ? 'Payment method unavailable'
                                : 'Selected payment method',
                            style: TextStyle(
                              color: isExpired
                                  ? Colors.grey
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment time has expired. Please place a new order.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor() {
    switch (controller.payment.paymentMethod) {
      case 'gopay':
        return const Color(0xFF00AA5B);
      case 'ovo':
        return const Color(0xFF4C3494);
      case 'dana':
        return const Color(0xFF118EEA);
      case 'shopeepay':
        return const Color(0xFFEE4D2D);
      default:
        return Colors.blue;
    }
  }

  IconData _getPaymentMethodIcon() {
    switch (controller.payment.paymentMethod) {
      case 'gopay':
      case 'ovo':
      case 'dana':
      case 'shopeepay':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodName() {
    switch (controller.payment.paymentMethod) {
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'shopeepay':
        return 'ShopeePay';
      case 'credit_card':
        return 'Credit/Debit Card';
      default:
        return controller.payment.paymentMethod.toUpperCase();
    }
  }
}
