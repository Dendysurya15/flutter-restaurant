import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/services/notification_service.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';

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
  var isRealtimeConnected = false.obs;

  // Store ID and name for the current owner
  String? _currentStoreId;
  String? _currentStoreName;

  // Realtime subscription
  RealtimeChannel? _ordersSubscription;

  @override
  void onInit() {
    super.onInit();

    _getCurrentStoreInfo().then((_) {
      fetchOrders(); // Initial load
      _setupRealtimeSubscription(); // Start real-time listening
    });
  }

  /// Get current store info (ID and name) for the logged-in owner
  Future<void> _getCurrentStoreInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final storeResponse = await _supabase
          .from('stores')
          .select('id, name')
          .eq('owner_id', user.id)
          .limit(1)
          .single();

      _currentStoreId = storeResponse['id'];
      _currentStoreName = storeResponse['name'];

      // Set store name in notification service
      NotificationService.to.setStoreName(_currentStoreName!);

      print('🏪 Store ID: $_currentStoreId, Name: $_currentStoreName');
    } catch (e) {
      print('❌ Error getting store info: $e');
      _showErrorToast('Failed to get store information');
    }
  }

  /// Setup real-time subscription for orders table
  void _setupRealtimeSubscription() {
    if (_currentStoreId == null) {
      print('❌ Cannot setup realtime: No store ID');
      return;
    }

    print('🔴 Setting up real-time subscription for store: $_currentStoreId');

    _ordersSubscription = _supabase
        .channel('orders-$_currentStoreId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Listen to INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: _currentStoreId!,
          ),
          callback: _handleRealtimeChange,
        )
        .subscribe((status, [error]) {
          print('📡 Realtime status: $status');
          if (error != null) {
            print('❌ Realtime error: $error');
          }

          isRealtimeConnected.value =
              status == RealtimeSubscribeStatus.subscribed;

          if (status == RealtimeSubscribeStatus.subscribed) {
            _showSuccessToast('🔴 Real-time connection established!');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            _showErrorToast(
              '❌ Real-time connection failed: ${error ?? 'Unknown error'}',
            );
          }
        });
  }

  /// Handle real-time database changes
  void _handleRealtimeChange(PostgresChangePayload payload) {
    print('🔴 Real-time change detected: ${payload.eventType}');
    print('📝 Data: ${payload.newRecord}');

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleNewOrder(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _handleOrderUpdate(payload.newRecord, payload.oldRecord);
        break;
      case PostgresChangeEvent.delete:
        _handleOrderDelete(payload.oldRecord);
        break;
      default:
        print('Unknown event type: ${payload.eventType}');
        break;
    }
  }

  /// Handle new order insertion (INSTANT!)
  /// Handle new order insertion (INSTANT!)
  void _handleNewOrder(Map<String, dynamic> orderData) async {
    print('🎉 NEW ORDER received via real-time!');

    try {
      final newOrder = OrderModel.fromJson(orderData);

      // Only show notification for pending orders
      if (newOrder.status == 'pending') {
        // Add to new orders list for UI highlighting
        newOrderIds.add(newOrder.id);

        // Get order items count for notification
        final itemsCount = await _getOrderItemsCount(newOrder.id);

        // DEBUG: Check user role

        print('🔍 DEBUG: Is owner: ${NotificationService.to.isOwner}');
        print('🔍 DEBUG: Items count: $itemsCount');

        // Show push notification (works in background/foreground/closed app)
        try {
          await NotificationService.to.showNewOrderNotification(
            newOrder,
            itemsCount,
          );
          print('✅ Notification service called successfully');
        } catch (notificationError) {
          print('❌ Notification error: $notificationError');
        }

        // Show toast notification (only if app is in foreground)
        // _showNewOrderToast(newOrder);

        // Remove highlighting after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          newOrderIds.remove(newOrder.id);
        });
      }

      // Refresh the orders list to show new order
      fetchOrders();
    } catch (e) {
      print('❌ Error processing new order: $e');
    }
  }

  /// Handle order updates (status changes, etc.)
  void _handleOrderUpdate(
    Map<String, dynamic> newRecord,
    Map<String, dynamic>? oldRecord,
  ) async {
    print('📝 ORDER UPDATED via real-time!');

    try {
      final updatedOrder = OrderModel.fromJson(newRecord);
      final previousStatus = oldRecord?['status'] as String?;

      // Remove from new orders if it was there
      newOrderIds.remove(updatedOrder.id);

      // Show status update notification if status changed
      if (previousStatus != null && previousStatus != updatedOrder.status) {
        if (NotificationService.to.isOwner) {
          // Show owner status update
          await NotificationService.to.showOrderStatusNotification(
            updatedOrder,
            previousStatus,
          );
        } else if (NotificationService.to.isCustomer) {
          // Show customer order update - REMOVE THE EXTRA PARAMETER
          await NotificationService.to.showCustomerOrderUpdate(updatedOrder);
        }
      }

      // Refresh orders to show updated status
      fetchOrders();
    } catch (e) {
      print('❌ Error processing order update: $e');
    }
  }

  /// Handle order deletion
  void _handleOrderDelete(Map<String, dynamic>? oldRecord) {
    print('🗑️ ORDER DELETED via real-time!');

    if (oldRecord != null) {
      final deletedOrderId = oldRecord['id'] as String;
      newOrderIds.remove(deletedOrderId);

      // Cancel notification for deleted order
      NotificationService.to.cancelOrderNotification(deletedOrderId);

      fetchOrders();
    }
  }

  /// Get order items count
  Future<int> _getOrderItemsCount(String orderId) async {
    try {
      final itemsResponse = await _supabase
          .from('order_items')
          .select('quantity')
          .eq('order_id', orderId);

      int totalItems = 0;
      for (final item in itemsResponse) {
        totalItems += (item['quantity'] as int? ?? 0);
      }

      return totalItems;
    } catch (e) {
      print('❌ Error getting order items count: $e');
      return 0;
    }
  }

  /// Fetch all orders from database (for initial load and manual refresh)
  Future<void> fetchOrders() async {
    if (_currentStoreId == null) {
      print('❌ Cannot fetch orders: No store ID');
      return;
    }

    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('store_id', _currentStoreId!)
          .order('created_at', ascending: false);

      // Convert to OrderModel objects
      final orders = ordersResponse.map((orderData) {
        return OrderModel.fromJson(orderData);
      }).toList();

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

      // No need to manually refresh - real-time will handle it!
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

      // No need to manually refresh - real-time will handle it!
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

      // No need to manually refresh - real-time will handle it!
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

      // No need to manually refresh - real-time will handle it!
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
    // Clean up real-time subscription
    _ordersSubscription?.unsubscribe();
    super.onClose();
  }
}
