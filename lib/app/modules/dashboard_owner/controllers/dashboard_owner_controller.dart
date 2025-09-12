import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';

class DashboardOwnerController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable lists for different order statuses
  var allOrders = <OrderModel>[].obs;
  var preparingOrders = <OrderModel>[].obs;
  var readyOrders = <OrderModel>[].obs;
  var completedOrders = <OrderModel>[].obs;
  var rejectedOrders = <OrderModel>[].obs;

  // Track new orders for UI highlighting
  var newOrderIds = <String>[].obs;

  // Loading state
  var isLoading = false.obs;

  // Track previous order IDs to detect new orders
  List<String> _previousOrderIds = [];

  // Store ID for the current owner
  String? _currentStoreId;

  // Timer for periodic refresh
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _getCurrentStoreId().then((_) {
      fetchOrders();
      _startPeriodicRefresh();
    });
  }

  /// Start periodic refresh every 10 seconds when app is active
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchOrders();
    });
  }

  /// Get current store ID for the logged-in owner
  Future<void> _getCurrentStoreId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final storeResponse = await _supabase
          .from('stores')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1)
          .single();

      _currentStoreId = storeResponse['id'];
      print('🏪 Store ID found: $_currentStoreId');
    } catch (e) {
      print('❌ Error getting store ID: $e');
      _showErrorToast('Failed to get store information');
    }
  }

  /// Fetch all orders from database
  Future<void> fetchOrders() async {
    if (_currentStoreId == null) {
      print('❌ Cannot fetch orders: No store ID');
      return;
    }

    try {
      // Only show loading on manual refresh, not on periodic refresh
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('store_id', _currentStoreId!)
          .order('created_at', ascending: false);

      // Convert to OrderModel objects
      final orders = ordersResponse.map((orderData) {
        return OrderModel.fromJson(orderData);
      }).toList();

      // Check for new orders (only on subsequent loads)
      final currentOrderIds = orders.map((order) => order.id).toList();

      if (_previousOrderIds.isNotEmpty) {
        final newIds = currentOrderIds
            .where((id) => !_previousOrderIds.contains(id))
            .where(
              (id) => orders.firstWhere((o) => o.id == id).status == 'pending',
            )
            .toList();

        // Process new orders
        for (final newId in newIds) {
          final newOrder = orders.firstWhere((order) => order.id == newId);
          _processNewOrder(newOrder);
        }
      }

      // Update previous order IDs for next comparison
      _previousOrderIds = currentOrderIds;

      // Update observable lists based on status
      allOrders.value = orders;
      preparingOrders.value = orders
          .where((o) => o.status == 'preparing')
          .toList();
      readyOrders.value = orders.where((o) => o.status == 'ready').toList();
      completedOrders.value = orders
          .where((o) => o.status == 'completed')
          .toList();
      rejectedOrders.value = orders
          .where((o) => o.status == 'rejected')
          .toList();
    } catch (e) {
      print('❌ Error fetching orders: $e');
      _showErrorToast('Failed to fetch orders: ${e.toString()}');
    }
  }

  /// Process a new order (simpler approach)
  void _processNewOrder(OrderModel order) {
    print('🎉 New order detected: ${order.id}');

    // Add to new orders list for UI highlighting
    if (!newOrderIds.contains(order.id)) {
      newOrderIds.add(order.id);

      // Show toast notification
      _showNewOrderToast(order);

      // Remove highlighting after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        newOrderIds.remove(order.id);
      });
    }
  }

  /// Accept an order and start preparation
  Future<void> acceptOrder(String orderId, int estimatedMinutes) async {
    try {
      final estimatedCookingTime = DateTime.now().add(
        Duration(minutes: estimatedMinutes),
      );

      await _supabase
          .from('orders')
          .update({
            'status': 'preparing',
            'accepted_at': DateTime.now().toIso8601String(),
            'estimated_cooking_time': estimatedCookingTime.toIso8601String(),
          })
          .eq('id', orderId);

      // Remove from new orders list
      newOrderIds.remove(orderId);

      _showSuccessToast(
        'Order accepted! Estimated ready time: $estimatedMinutes minutes',
      );

      await fetchOrders();
    } catch (e) {
      print('❌ Error accepting order: $e');
      _showErrorToast('Failed to accept order: ${e.toString()}');
    }
  }

  /// Reject an order
  Future<void> rejectOrder(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Remove from new orders list
      newOrderIds.remove(orderId);

      _showSuccessToast('Order rejected successfully');
      await fetchOrders();
    } catch (e) {
      print('❌ Error rejecting order: $e');
      _showErrorToast('Failed to reject order: ${e.toString()}');
    }
  }

  /// Mark order as ready for pickup
  Future<void> markOrderAsReady(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'ready',
            'ready_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order marked as ready for pickup!');
      await fetchOrders();
    } catch (e) {
      print('❌ Error marking order as ready: $e');
      _showErrorToast('Failed to mark order as ready: ${e.toString()}');
    }
  }

  /// Mark order as completed
  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order completed successfully!');
      await fetchOrders();
    } catch (e) {
      print('❌ Error completing order: $e');
      _showErrorToast('Failed to complete order: ${e.toString()}');
    }
  }

  /// Show toast notification for new orders
  void _showNewOrderToast(OrderModel order) {
    if (Get.context == null) return;

    ToastHelper.showToast(
      context: Get.context!,
      title: "🔔 New Order Received!",
      description:
          "Order #${order.orderNumber} from ${order.customerName}\nTotal: Rp ${_formatPrice(order.totalAmount)}",
      type: ToastificationType.info,
    );
  }

  /// Format price with thousand separators
  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Show success toast
  void _showSuccessToast(String message) {
    if (Get.context != null) {
      ToastHelper.showToast(
        context: Get.context!,
        title: "✅ Success",
        description: message,
        type: ToastificationType.success,
      );
    }
  }

  /// Show error toast
  void _showErrorToast(String message) {
    if (Get.context != null) {
      ToastHelper.showToast(
        context: Get.context!,
        title: "❌ Error",
        description: message,
        type: ToastificationType.error,
      );
    }
  }

  /// Manual refresh (called by pull-to-refresh)
  Future<void> manualRefresh() async {
    isLoading.value = true;
    try {
      await fetchOrders();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
