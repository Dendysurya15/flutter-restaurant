// lib/app/services/customer_order_counter_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';

class CustomerOrderCounterService extends GetxService {
  static CustomerOrderCounterService get to => Get.find();

  final SupabaseClient _supabase = Supabase.instance.client;
  final activeOrdersCount = 0.obs; // pending, preparing, ready

  // New: Track if there are new updates since last visit
  final hasNewUpdates = false.obs;

  // Track last seen timestamp
  DateTime? _lastSeenTimestamp;

  RealtimeChannel? _orderUpdatesSubscription;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _setupOrderTracking();
    _loadInitialActiveOrders();
    // Initialize last seen timestamp
    _lastSeenTimestamp = DateTime.now();
  }

  void _setupOrderTracking() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _currentUserId = user.id;

    // Listen to ALL order changes for this customer
    _orderUpdatesSubscription = _supabase
        .channel('customer-orders-$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // INSERT, UPDATE, DELETE
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _currentUserId!,
          ),
          callback: (payload) {
            print('🔔 Order update received: ${payload.eventType}');
            print('🔔 Order data: ${payload.newRecord}');

            // Set hasNewUpdates to true when there's any change
            hasNewUpdates.value = true;

            // Refresh count whenever any order changes
            _loadInitialActiveOrders();

            _showUpdateNotification(payload);
          },
        )
        .subscribe();
  }

  void _showUpdateNotification(PostgresChangePayload payload) {
    String message = '';

    switch (payload.eventType) {
      case PostgresChangeEvent.insert: // lowercase 'insert'
        message = 'New order confirmed!';
        break;
      case PostgresChangeEvent.update: // lowercase 'update'
        final newRecord = payload.newRecord;
        final status = newRecord?['status'];

        switch (status) {
          case 'preparing':
            message = 'Your order is being prepared!';
            break;
          case 'ready':
            message = 'Your order is ready for pickup!';
            break;
          case 'completed':
            message = 'Order completed. Thank you!';
            break;
          case 'rejected':
            message = 'Order was rejected. Check details.';
            break;
          default:
            message = 'Order status updated';
        }
        break;
      case PostgresChangeEvent.delete: // lowercase 'delete'
        message = 'Order removed';
        break;
      default:
        print('Unknown event type: ${payload.eventType}');
        break;
    }
  }

  /// Load current count of active orders (not completed)
  Future<void> _loadInitialActiveOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Only count orders that are BOTH pending payment AND have active status
      final response = await _supabase
          .from('orders')
          .select('id')
          .eq('customer_id', user.id)
          .eq('payment_status', 'pending') // Add this line - only unpaid orders
          .inFilter('status', [
            'pending',
            'preparing',
            'ready',
          ]); // Remove 'rejected' and 'completed'

      activeOrdersCount.value = response.length;
      print('🔔 Active orders count updated: ${activeOrdersCount.value}');
    } catch (e) {
      print('❌ Error loading active orders count: $e');
    }
  }

  /// Get total count (unpaid + active orders)
  int get totalNotificationCount {
    final unpaidCount = PaymentTimerService.to.totalPendingPayments;
    final activeCount = activeOrdersCount.value;
    return unpaidCount + activeCount;
  }

  /// Mark notifications as read (called when user visits history page)
  void markNotificationsAsRead() {
    // Reset the new updates flag
    hasNewUpdates.value = false;
    // Update last seen timestamp
    _lastSeenTimestamp = DateTime.now();

    print('🔔 Notifications marked as read');
  }

  /// Reset new updates flag (for manual reset)
  void clearNewUpdates() {
    hasNewUpdates.value = false;
  }

  @override
  void onClose() {
    try {
      _orderUpdatesSubscription?.unsubscribe();
    } catch (e) {
      print('❌ Error unsubscribing from realtime: $e');
    }
    super.onClose();
  }
}
