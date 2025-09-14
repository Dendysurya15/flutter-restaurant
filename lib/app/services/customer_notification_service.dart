// lib/app/services/customer_notification_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerNotificationService extends GetxService {
  static CustomerNotificationService get to => Get.find();

  final SupabaseClient _supabase = Supabase.instance.client;
  final unreadNotificationsCount = 0.obs;

  RealtimeChannel? _orderUpdatesSubscription;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _setupCustomerOrderTracking();
  }

  void _setupCustomerOrderTracking() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _currentUserId = user.id;

    // Listen to order updates for this customer
    _orderUpdatesSubscription = _supabase
        .channel('customer-orders-$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _currentUserId!,
          ),
          callback: (payload) {
            final oldStatus = payload.oldRecord?['status'];
            final newStatus = payload.newRecord?['status'];

            // Only increment for meaningful status changes
            if (oldStatus != newStatus &&
                [
                  'preparing',
                  'ready',
                  'completed',
                  'rejected',
                ].contains(newStatus)) {
              unreadNotificationsCount.value++;
              print(
                '🔔 Customer notification count: ${unreadNotificationsCount.value}',
              );
            }
          },
        )
        .subscribe();
  }

  void markNotificationsAsRead() {
    unreadNotificationsCount.value = 0;
  }

  @override
  void onClose() {
    _orderUpdatesSubscription?.unsubscribe();
    super.onClose();
  }
}
