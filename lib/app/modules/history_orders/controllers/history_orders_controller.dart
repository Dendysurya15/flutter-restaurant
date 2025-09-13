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
  final SupabaseClient _supabase = Supabase.instance.client;

  // Tab controller
  late TabController tabController;
  final selectedTabIndex = 0.obs;

  // Loading state
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  // Orders data
  final allOrders = <OrderModel>[].obs;

  // Real-time functionality
  final newOrderIds = <String>[].obs;
  final updatedOrderIds = <String>[].obs;
  RealtimeChannel? _ordersSubscription;
  String? _currentUserId;

  // Counts for badges
  final historyCount = 0.obs;
  final ongoingCount = 0.obs;

  @override
  void onInit() {
    try {
      super.onInit();
      print('Step 1: super.onInit() completed');

      // Initialize tab controller
      tabController = TabController(length: 2, vsync: this);
      print('Step 2: TabController created');

      tabController.addListener(() {
        selectedTabIndex.value = tabController.index;
      });
      print('Step 3: TabController listener added');

      // Get current user ID and setup real-time
      _getCurrentUserId().then((_) {
        loadOrders();
        _setupRealtimeSubscription();
      });
      print('Step 4: User ID and real-time setup initiated');

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

  // Get current user ID
  Future<void> _getCurrentUserId() async {
    _currentUserId = authService.currentUser?.id;
    print('🏪 User ID found: $_currentUserId');
  }

  // Setup real-time subscription for user's orders
  void _setupRealtimeSubscription() {
    if (_currentUserId == null) {
      print('❌ Cannot setup realtime: No user ID');
      return;
    }

    print('🔴 Setting up real-time subscription for user: $_currentUserId');

    _ordersSubscription = _supabase
        .channel('user-orders-$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _currentUserId!,
          ),
          callback: _handleRealtimeChange,
        )
        .subscribe((status, [error]) {
          print('📡 Realtime status: $status');
          if (error != null) {
            print('❌ Realtime error: $error');
          }
        });
  }

  // Handle real-time database changes
  void _handleRealtimeChange(PostgresChangePayload payload) {
    print('🔴 Real-time change detected: ${payload.eventType}');

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleNewOrder(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _handleOrderUpdate(payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _handleOrderDelete(payload.oldRecord);
        break;
      default:
        print('Unknown event type: ${payload.eventType}');
        break;
    }
  }

  // Handle new order insertion
  void _handleNewOrder(Map<String, dynamic> orderData) {
    print('🎉 NEW ORDER received via real-time!');

    try {
      final newOrder = OrderModel.fromJson(orderData);

      // Add to new orders list for UI highlighting (green border)
      if (!newOrderIds.contains(newOrder.id)) {
        newOrderIds.add(newOrder.id);

        // Remove highlighting after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          newOrderIds.remove(newOrder.id);
        });
      }

      // Refresh the orders list
      loadOrders();
    } catch (e) {
      print('❌ Error processing new order: $e');
    }
  }

  // Handle order updates (status changes)
  void _handleOrderUpdate(Map<String, dynamic> orderData) {
    print('📝 ORDER UPDATED via real-time!');

    try {
      final updatedOrder = OrderModel.fromJson(orderData);

      // Add to updated orders list for UI highlighting (blue border)
      if (!updatedOrderIds.contains(updatedOrder.id)) {
        updatedOrderIds.add(updatedOrder.id);

        // Remove highlighting after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          updatedOrderIds.remove(updatedOrder.id);
        });
      }

      // Remove from new orders if it was there
      newOrderIds.remove(updatedOrder.id);

      // Refresh orders
      loadOrders();
    } catch (e) {
      print('❌ Error processing order update: $e');
    }
  }

  // Handle order deletion
  void _handleOrderDelete(Map<String, dynamic>? oldRecord) {
    print('🗑️ ORDER DELETED via real-time!');

    if (oldRecord != null) {
      final deletedOrderId = oldRecord['id'] as String;
      newOrderIds.remove(deletedOrderId);
      updatedOrderIds.remove(deletedOrderId);
      loadOrders();
    }
  }

  @override
  void onClose() {
    _ordersSubscription?.unsubscribe();
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;

      final orders = await _fetchOrdersFromAPI();
      allOrders.value = orders;
      _updateCounts();
    } catch (e) {
      print('Error loading orders: $e');
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

  void _updateCounts() {
    // History: completed + rejected
    historyCount.value = allOrders
        .where(
          (order) => order.status == 'completed' || order.status == 'rejected',
        )
        .length;

    // Ongoing: pending + preparing + ready
    ongoingCount.value = allOrders
        .where(
          (order) =>
              order.status == 'pending' ||
              order.status == 'preparing' ||
              order.status == 'ready',
        )
        .length;
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
      return [];
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
            'is_expired': remainingSeconds <= 0,
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
          _buildDetailRow('Order Type', 'Pickup'),
          _buildDetailRow('Status', order.status.toUpperCase()),
          _buildDetailRow('Payment Status', order.paymentStatus.toUpperCase()),
          _buildDetailRow('Payment Method', order.paymentMethod.toUpperCase()),

          // Estimated cooking time if available
          if (order.estimatedCookingTime != null)
            _buildDetailRow(
              'Est. Ready Time',
              _formatDateTime(order.estimatedCookingTime!),
            ),

          // Special instructions if any
          if (order.specialInstructions?.isNotEmpty == true)
            _buildDetailRow('Special Instructions', order.specialInstructions!),

          const Divider(height: 32),

          // Order Summary
          _buildDetailRow('Subtotal', 'Rp ${_formatPrice(order.subtotal)}'),
          _buildDetailRow(
            'Total',
            'Rp ${_formatPrice(order.totalAmount)}',
            isTotal: true,
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (order.paymentStatus == 'pending')
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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
