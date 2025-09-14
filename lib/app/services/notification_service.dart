import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/order_model.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Store name cache (only this is needed)
  String? _storeName;

  @override
  Future<void> onInit() async {
    super.onInit();

    // Always initialize notifications for all user types
    await _initializeNotifications();
    await _initializeTimezone();

    print('✅ Notification service initialized');
  }

  /// Initialize timezone data
  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    // Set local timezone (Indonesian timezone)
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  }

  /// Initialize notifications for all user types
  Future<void> _initializeNotifications() async {
    // Android initialization settings
    const androidInitialization = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestIOSPermissions();
    }

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidPermissions();
    }
  }

  /// Request iOS permissions
  Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Request Android permissions (for Android 13+)
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  /// Check and request notification permissions
  Future<bool> checkAndRequestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? enabled = await androidPlugin?.areNotificationsEnabled();
      print('🔔 Android notifications enabled: $enabled');

      if (enabled != true) {
        print('🔔 Requesting Android notification permissions...');
        await androidPlugin?.requestNotificationsPermission();
      }

      return enabled == true;
    }
    return true; // iOS handles differently
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    final payload = response.payload;

    if (payload?.startsWith('order:') == true) {
      // Just navigate to home - the correct dashboard will be shown based on user role
      Get.offAllNamed(Routes.HOME);
    }
  }

  /// Set store name (for owners)
  void setStoreName(String storeName) {
    _storeName = storeName;
  }

  /// Get user role from AuthService
  String _getUserRole() {
    try {
      final authService = Get.find<AuthService>();
      return authService.userRole.value.toLowerCase();
    } catch (e) {
      print('❌ Error getting role from AuthService: $e');
      return 'customer';
    }
  }

  /// Check if user is owner
  bool get isOwner => _getUserRole() == 'owner';

  /// Check if user is customer
  bool get isCustomer => _getUserRole() == 'customer';

  /// Check if user is admin
  bool get isAdmin => _getUserRole() == 'admin';

  // ==============================================================
  // OWNER NOTIFICATIONS
  // ==============================================================

  /// Show new order notification (for restaurant owners)
  Future<void> showNewOrderNotification(
    OrderModel order,
    int totalItems,
  ) async {
    print('🔍 showNewOrderNotification called');

    final userRole = _getUserRole();
    print('🔍 Current user role: $userRole');

    if (userRole != 'owner') {
      print('❌ Not showing notification - user is not owner');
      return;
    }

    print('🔍 Proceeding with owner notification...');

    final androidDetails = AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'Notifications for new incoming orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: false,
      ongoing: false,
      category: AndroidNotificationCategory.message,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'NEW_ORDER',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Better notification format
    final title = 'Order Confirmed';
    final itemText = totalItems == 1 ? 'item' : 'items';
    final body =
        '${_storeName ?? 'Your Restaurant'}\n'
        '$totalItems $itemText • Rp ${_formatPrice(order.totalAmount)}\n'
        '${order.customerName}';

    print('🔍 Showing notification with title: $title');
    print('🔍 Body: $body');

    await _notifications.show(
      order.id.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'order:${order.id}',
    );

    print('✅ Owner notification shown for order: ${order.orderNumber}');
  }

  /// Show order status update notification (for owners)
  Future<void> showOrderStatusNotification(
    OrderModel order,
    String previousStatus,
  ) async {
    if (_getUserRole() != 'owner') return;

    String title;
    String body;

    switch (order.status) {
      case 'preparing':
        title = '👨‍🍳 Order Accepted';
        body = 'Order #${order.orderNumber} is now being prepared';
        break;
      case 'ready':
        title = '✅ Order Ready';
        body = 'Order #${order.orderNumber} is ready for pickup';
        break;
      case 'completed':
        title = '🎉 Order Completed';
        body = 'Order #${order.orderNumber} has been completed';
        break;
      case 'rejected':
        title = '❌ Order Rejected';
        body = 'Order #${order.orderNumber} has been rejected';
        break;
      default:
        return;
    }

    final androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      order.id.hashCode + 1000,
      title,
      body,
      notificationDetails,
      payload: 'order:${order.id}',
    );
  }

  // ==============================================================
  // CUSTOMER NOTIFICATIONS
  // ==============================================================

  /// Show order confirmation notification (for customers)
  Future<void> showCustomerOrderConfirmation(
    OrderModel order,
    int totalItems,
  ) async {
    if (_getUserRole() != 'customer') return;

    final androidDetails = AndroidNotificationDetails(
      'order_confirmations',
      'Order Confirmations',
      channelDescription: 'Notifications for order confirmations',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = '✅ Order Confirmed';
    final itemText = totalItems == 1 ? 'item' : 'items';
    final body =
        'Your order #${order.orderNumber} has been confirmed!\n'
        '📦 $totalItems $itemText\n'
        '💰 Rp ${_formatPrice(order.totalAmount)}';

    await _notifications.show(
      order.id.hashCode + 2000,
      title,
      body,
      notificationDetails,
      payload: 'order:${order.id}',
    );

    debugPrint(
      '✅ Customer confirmation notification shown for order: ${order.orderNumber}',
    );
  }

  /// Show order status update notification (for customers)
  Future<void> showCustomerOrderUpdate(OrderModel order) async {
    if (_getUserRole() != 'customer') return;

    String title;
    String body;

    switch (order.status) {
      case 'preparing':
        title = '👨‍🍳 Order Being Prepared';
        body =
            'Good news! Your order #${order.orderNumber} is now being prepared';
        break;
      case 'ready':
        title = '🎉 Order Ready for Pickup!';
        body =
            'Your order #${order.orderNumber} is ready! Please come to pick it up';
        break;
      case 'completed':
        title = '✅ Order Completed';
        body = 'Thank you! Your order #${order.orderNumber} has been completed';
        break;
      case 'rejected':
        title = '❌ Order Rejected';
        body =
            'Sorry, your order #${order.orderNumber} has been rejected. You will be refunded shortly.';
        break;
      default:
        return;
    }

    final androidDetails = AndroidNotificationDetails(
      'customer_order_updates',
      'Your Order Updates',
      channelDescription: 'Updates about your orders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      order.id.hashCode + 3000,
      title,
      body,
      notificationDetails,
      payload: 'order:${order.id}',
    );
  }

  // ==============================================================
  // ADMIN NOTIFICATIONS (for future use)
  // ==============================================================

  /// Show admin notification (for system admins)
  Future<void> showAdminNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    if (_getUserRole() != 'admin') return;

    final androidDetails = AndroidNotificationDetails(
      'admin_notifications',
      'Admin Notifications',
      channelDescription: 'System notifications for administrators',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ==============================================================
  // UTILITY METHODS
  // ==============================================================

  /// Cancel notification for specific order
  Future<void> cancelOrderNotification(String orderId) async {
    await _notifications.cancel(orderId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Format price with Indonesian Rupiah format
  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }
}
