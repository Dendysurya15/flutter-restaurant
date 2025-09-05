// app/modules/history_orders/controllers/history_orders_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryOrdersController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthService authService = Get.find<AuthService>();
  final PaymentTimerService timerService = Get.find<PaymentTimerService>();

  // Tab controller
  late TabController tabController;
  final selectedTabIndex = 0.obs;

  // Loading state
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  // Orders data
  final allOrders = <OrderModel>[].obs;
  final needPayOrders = <OrderModel>[].obs;
  final ongoingOrders = <OrderModel>[].obs;
  final completeOrders = <OrderModel>[].obs;
  final failedOrders = <OrderModel>[].obs;

  // Counts for badges
  final allOrdersCount = 0.obs;
  final needPayCount = 0.obs;
  final ongoingCount = 0.obs;
  final completeCount = 0.obs;
  final failedCount = 0.obs;

  @override
  void onInit() {
    try {
      super.onInit();
      print('Step 1: super.onInit() completed');

      // Initialize tab controller
      tabController = TabController(length: 5, vsync: this);
      print('Step 2: TabController created');

      tabController.addListener(() {
        selectedTabIndex.value = tabController.index;
      });
      print('Step 3: TabController listener added');

      // Load orders
      loadOrders();
      print('Step 4: loadOrders() called');

      // Listen to timer service updates
      ever(timerService.activePayments, (_) {
        _updateCounts();
      });
      print('Step 5: timer service listener added');
    } catch (e, stackTrace) {
      print('Error in HistoryOrdersController.onInit(): $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;

      // TODO: Replace with actual API call
      final orders = await _fetchOrdersFromAPI();

      allOrders.value = orders;
      _categorizeOrders();
      _updateCounts();
    } catch (e) {
      print('Error loading orders: $e');
      // TODO: Show error toast
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    try {
      isRefreshing.value = true;
      await loadOrders();
    } finally {
      isRefreshing.value = false;
    }
  }

  void _categorizeOrders() {
    needPayOrders.clear();
    ongoingOrders.clear();
    completeOrders.clear();
    failedOrders.clear();

    for (final order in allOrders) {
      if (_isNeedPayment(order)) {
        needPayOrders.add(order);
      } else if (_isOngoing(order)) {
        ongoingOrders.add(order);
      } else if (_isCompleted(order)) {
        completeOrders.add(order);
      } else if (_isFailed(order)) {
        failedOrders.add(order);
      }
    }
  }

  bool _isNeedPayment(OrderModel order) {
    return order.paymentStatus == 'pending' &&
        (order.status == 'pending' || order.status == 'confirmed');
  }

  bool _isOngoing(OrderModel order) {
    final ongoingStatuses = ['confirmed', 'accepted', 'preparing', 'ready'];
    return ongoingStatuses.contains(order.status.toLowerCase()) &&
        order.paymentStatus == 'paid';
  }

  bool _isCompleted(OrderModel order) {
    return order.status.toLowerCase() == 'completed';
  }

  bool _isFailed(OrderModel order) {
    final failedStatuses = ['cancelled', 'declined', 'failed'];
    return failedStatuses.contains(order.status.toLowerCase()) ||
        order.paymentStatus == 'expired';
  }

  void _updateCounts() {
    allOrdersCount.value = allOrders.length;
    needPayCount.value = needPayOrders.length;
    ongoingCount.value = ongoingOrders.length;
    completeCount.value = completeOrders.length;
    failedCount.value = failedOrders.length;
  }

  Future<List<OrderModel>> _fetchOrdersFromAPI() async {
    try {
      final currentUserId = authService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('customer_id', currentUserId)
          .order('created_at', ascending: false);

      return response
          .map<OrderModel>((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching orders from Supabase: $e');
      return []; // Return empty list instead of mock data
    }
  }

  void navigateToPayment(OrderModel order) async {
    try {
      // Check if timer already exists
      final existingTimer = timerService.getPaymentTimer(order.id);

      if (existingTimer != null) {
        // Timer exists, navigate to payment with existing timer
        Get.toNamed(
          Routes.PAYMENT,
          arguments: {
            'order': order,
            'payment': existingTimer.payment,
            'timer_data': existingTimer,
          },
        );
      } else {
        // Calculate REAL remaining time from order creation
        final timeSinceOrderCreated = DateTime.now().difference(
          order.createdAt,
        );
        final remainingSeconds = 900 - timeSinceOrderCreated.inSeconds;

        // Get existing payment or create new one
        PaymentModel? payment = await _getPaymentForOrder(order.id);

        if (payment == null) {
          payment = PaymentModel(
            id: 'payment_${order.id}',
            orderId: order.id,
            amount: order.totalAmount,
            paymentMethod: order.paymentMethod,
            status: 'pending',
            createdAt: order.createdAt,
            updatedAt: DateTime.now(),
          );
        }

        // Start timer with remaining time (even if expired)
        if (remainingSeconds > 0) {
          timerService.startPaymentTimer(
            order: order,
            payment: payment,
            durationInSeconds: remainingSeconds,
          );
        }

        // Always navigate - let PaymentView handle expired state
        Get.toNamed(
          Routes.PAYMENT,
          arguments: {
            'order': order,
            'payment': payment,
            'is_expired': remainingSeconds <= 0, // Pass expiration status
          },
        );
      }
    } catch (e) {
      print('Error navigating to payment: $e');
    }
  }

  void showOrderDetails(OrderModel order) {
    Get.bottomSheet(
      _buildOrderDetailsBottomSheet(order),
      backgroundColor: Colors.white,
      isScrollControlled: true,
    );
  }

  Future<PaymentModel?> _getPaymentForOrder(String orderId) async {
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select('*')
          .eq('order_id', orderId)
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      print('Error fetching payment: $e');
      return null;
    }
  }

  Widget _buildOrderDetailsBottomSheet(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Order Info
          _buildDetailRow('Customer', order.customerName),
          _buildDetailRow('Phone', order.customerPhone),
          _buildDetailRow(
            'Order Type',
            order.orderType == 'delivery' ? 'Delivery' : 'Dine In',
          ),
          if (order.deliveryAddress != null)
            _buildDetailRow('Address', order.deliveryAddress!),
          _buildDetailRow('Status', order.status.toUpperCase()),
          _buildDetailRow('Payment Status', order.paymentStatus.toUpperCase()),
          _buildDetailRow('Payment Method', order.paymentMethod.toUpperCase()),

          const Divider(height: 32),

          // Order Summary
          _buildDetailRow('Subtotal', 'Rp.${order.subtotal.toInt()}'),
          if (order.deliveryFee > 0)
            _buildDetailRow('Delivery Fee', 'Rp.${order.deliveryFee.toInt()}'),
          _buildDetailRow(
            'Total',
            'Rp.${order.totalAmount.toInt()}',
            isTotal: true,
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (_isNeedPayment(order))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  navigateToPayment(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Complete Payment'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ),

          SizedBox(height: MediaQuery.of(Get.context!).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Method to load pending payments on app start
  Future<void> loadPendingPaymentsOnStart() async {
    try {
      final currentUserId = authService.currentUser?.id;
      if (currentUserId == null) return;

      final response = await Supabase.instance.client
          .from('orders')
          .select('*, payments(*)')
          .eq('customer_id', currentUserId)
          .eq('payment_status', 'pending')
          .inFilter('status', ['pending', 'confirmed']);

      for (final orderData in response) {
        final order = OrderModel.fromJson(orderData);
        final paymentData = orderData['payments'];

        if (paymentData != null && paymentData.isNotEmpty) {
          final payment = PaymentModel.fromJson(paymentData[0]);

          // Use ORDER creation time, not payment creation time
          final timeSinceCreated = DateTime.now().difference(order.createdAt);
          final remainingSeconds = 900 - timeSinceCreated.inSeconds;

          if (remainingSeconds > 0) {
            timerService.startPaymentTimer(
              order: order,
              payment: payment,
              durationInSeconds: remainingSeconds,
            );
          }
        }
      }
    } catch (e) {
      print('Error loading pending payments: $e');
    }
  }
}
