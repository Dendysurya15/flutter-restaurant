import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/services/store_service.dart';
import 'package:restaurant/app/services/menu_service.dart';
import 'package:restaurant/app/services/order_service.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/data/models/user_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/widgets/modal_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

class CartItemController extends GetxController {
  static int _instanceCount = 0;
  final int _instanceId = ++_instanceCount;

  // Direct service access - since they're permanent too
  CartService get cartService {
    print('🔧 [$_instanceId] Getting CartService...');
    try {
      final service = Get.find<CartService>();
      print('✅ [$_instanceId] CartService found: ${service.hashCode}');
      return service;
    } catch (e) {
      print('❌ [$_instanceId] CartService not found: $e');
      rethrow;
    }
  }

  MenuService get menuService {
    print('🔧 [$_instanceId] Getting MenuService...');
    try {
      final service = Get.find<MenuService>();
      print('✅ [$_instanceId] MenuService found: ${service.hashCode}');
      return service;
    } catch (e) {
      print('❌ [$_instanceId] MenuService not found: $e');
      rethrow;
    }
  }

  OrderService get orderService {
    print('🔧 [$_instanceId] Getting OrderService...');
    try {
      final service = Get.find<OrderService>();
      print('✅ [$_instanceId] OrderService found: ${service.hashCode}');
      return service;
    } catch (e) {
      print('❌ [$_instanceId] OrderService not found: $e');
      rethrow;
    }
  }

  PaymentService get paymentService {
    print('🔧 [$_instanceId] Getting PaymentService...');
    try {
      final service = Get.find<PaymentService>();
      print('✅ [$_instanceId] PaymentService found: ${service.hashCode}');
      return service;
    } catch (e) {
      print('❌ [$_instanceId] PaymentService not found: $e');
      rethrow;
    }
  }

  // State management
  final isLoadingData = true.obs;
  final isProcessingOrder = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Data observables (removed delivery-related fields)
  final Rx<StoreModel?> storeInfo = Rx<StoreModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxMap<String, MenuItemModel> menuItems = <String, MenuItemModel>{}.obs;
  final specialInstructions = ''.obs;
  final TextEditingController instructionsController = TextEditingController();
  final Rx<PaymentMethodOption?> selectedPaymentMethod =
      Rx<PaymentMethodOption?>(null);
  final RxList<PaymentMethodOption> availablePaymentMethods =
      <PaymentMethodOption>[].obs;

  bool get mounted => !isClosed;

  @override
  void onInit() {
    super.onInit();
    print(
      '🚀 [$_instanceId] CartItemController.onInit() - PERMANENT CONTROLLER CREATED',
    );
    print('📊 [$_instanceId] Current controller instances: $_instanceCount');

    // Log initial state
    _logControllerState('onInit');

    // Setup listeners
    instructionsController.addListener(() {
      print(
        '📝 [$_instanceId] Instructions changed: ${instructionsController.text}',
      );
      specialInstructions.value = instructionsController.text;
    });

    // Setup payment methods listener (removed order type dependency)
    _updatePaymentMethods();

    // Listen to cart changes from CartService
    _setupCartListener();
  }

  void _setupCartListener() {
    print('👂 [$_instanceId] Setting up cart listener...');
    try {
      // This will trigger whenever cart items change
      ever(cartService.cartItems, (items) {
        print('🛒 [$_instanceId] Cart items changed: ${items.length} items');
        for (final item in items) {
          print('   - ${item.menuItemId}: ${item.quantity}x at ${item.price}');
        }

        // If we're currently on the cart page and cart becomes empty, we might want to go back
        if (items.isEmpty && Get.currentRoute == Routes.CART_ITEM) {
          print('⚠️ [$_instanceId] Cart became empty while on cart page');
        }
      });
    } catch (e) {
      print('❌ [$_instanceId] Error setting up cart listener: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    print('🎯 [$_instanceId] CartItemController.onReady() - Controller ready');
    _logControllerState('onReady');
  }

  // This method should be called when navigating to cart page
  Future<void> initializeForCartPage() async {
    print(
      '🔄 [$_instanceId] initializeForCartPage() - Starting cart page initialization',
    );
    _logControllerState('initializeForCartPage - START');

    // Reset state for fresh load
    _resetState();

    // Load cart data
    await loadCartData();

    _logControllerState('initializeForCartPage - END');
  }

  void _resetState() {
    print('🔄 [$_instanceId] Resetting controller state...');
    isLoadingData.value = true;
    isProcessingOrder.value = false;
    hasError.value = false;
    errorMessage.value = '';
    storeInfo.value = null;
    currentUser.value = null;
    menuItems.clear();
    selectedPaymentMethod.value = null;
    availablePaymentMethods.clear();
    // Note: Don't reset specialInstructions as user might want to keep them
    print('✅ [$_instanceId] State reset completed');
  }

  Future<void> loadCartData() async {
    if (!mounted) {
      print('⚠️ [$_instanceId] Controller not mounted, skipping loadCartData');
      return;
    }

    print('🔄 [$_instanceId] Starting cart data load...');
    _logControllerState('loadCartData - START');

    isLoadingData.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Check cart items first
      final cartItems = cartService.cartItems;
      print('📦 [$_instanceId] Cart items count: ${cartItems.length}');

      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        print(
          '   [$i] Item: ${item.menuItemId} | Qty: ${item.quantity} | Price: ${item.price} | Store: ${item.storeId}',
        );
      }

      if (cartItems.isEmpty) {
        print('⚠️ [$_instanceId] Cart is empty, finishing load');
        isLoadingData.value = false;
        return;
      }

      // Load user info
      print('👤 [$_instanceId] Loading user info...');
      await _loadUserInfo();

      // Load store and menu data in parallel
      final storeId = cartItems.first.storeId;
      print('🏪 [$_instanceId] Loading data for store: $storeId');

      await Future.wait([
        _loadStoreInfo(storeId),
        _loadMenuItems(storeId, cartItems),
      ]);

      // Update payment methods
      print('💳 [$_instanceId] Updating payment methods...');
      _updatePaymentMethods();

      // Retry payment methods if they failed to load
      if (availablePaymentMethods.isEmpty) {
        print('🔄 [$_instanceId] Payment methods empty, retrying in 500ms...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _updatePaymentMethods();
          }
        });
      }

      print('✅ [$_instanceId] Cart data load completed successfully');
      _logControllerState('loadCartData - SUCCESS');
    } catch (e) {
      print('❌ [$_instanceId] Error loading cart data: $e');
      print('📍 [$_instanceId] Stack trace: ${StackTrace.current}');
      hasError.value = true;
      errorMessage.value = 'Failed to load cart data: $e';
      _logControllerState('loadCartData - ERROR');
    } finally {
      if (mounted) {
        isLoadingData.value = false;
        print('🏁 [$_instanceId] Cart data loading finished');
      } else {
        print('⚠️ [$_instanceId] Controller was disposed during loading');
      }
    }
  }

  Future<void> _loadUserInfo() async {
    print('👤 [$_instanceId] Loading user information...');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    if (!mounted) {
      print('⚠️ [$_instanceId] Controller disposed during user info load');
      return;
    }

    currentUser.value = UserModel(
      id: user.id,
      email: user.email ?? '',
      role: 'customer',
      fullName: user.userMetadata?['full_name'] ?? 'Customer',
      phone: user.userMetadata?['phone'] ?? '+628123456789',
      address: user.userMetadata?['address'],
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: DateTime.now(),
    );

    print('✅ [$_instanceId] User info loaded:');
    print('   - ID: ${currentUser.value?.id}');
    print('   - Name: ${currentUser.value?.fullName}');
    print('   - Phone: ${currentUser.value?.phone}');
  }

  Future<void> _loadStoreInfo(String storeId) async {
    print('🏪 [$_instanceId] Loading store info for: $storeId');

    try {
      final response = await StoreService.supabase
          .from('stores')
          .select()
          .eq('id', storeId)
          .single()
          .timeout(const Duration(seconds: 10));

      if (!mounted) {
        print('⚠️ [$_instanceId] Controller disposed during store info load');
        return;
      }

      storeInfo.value = StoreModel.fromJson(response);
      print('✅ [$_instanceId] Store info loaded:');
      print('   - Name: ${storeInfo.value?.name}');
      print('   - Category: ${storeInfo.value?.category}');
      print('   - Address: ${storeInfo.value?.address}');
      print('   - Phone: ${storeInfo.value?.phone}');
      print('   - Minimum Order: ${storeInfo.value?.minimumOrder}');
    } catch (e) {
      print('❌ [$_instanceId] Error loading store info: $e');
      rethrow;
    }
  }

  Future<void> _loadMenuItems(
    String storeId,
    List<CartItemModel> cartItems,
  ) async {
    print('📋 [$_instanceId] Loading menu items...');

    final menuItemIds = cartItems.map((item) => item.menuItemId).toList();
    print('🔍 [$_instanceId] Looking for menu items: $menuItemIds');

    if (menuItemIds.isEmpty) {
      print('⚠️ [$_instanceId] No menu item IDs to load');
      return;
    }

    try {
      final response = await StoreService.supabase
          .from('menu_items')
          .select()
          .filter('id', 'in', '(${menuItemIds.join(',')})')
          .timeout(const Duration(seconds: 10));

      print(
        '📋 [$_instanceId] Retrieved ${response.length} menu items from database',
      );

      if (!mounted) {
        print('⚠️ [$_instanceId] Controller disposed during menu items load');
        return;
      }

      final Map<String, MenuItemModel> newMenuItems = {};

      for (final json in response) {
        try {
          final menuItem = MenuItemModel.fromJson(json);
          newMenuItems[menuItem.id] = menuItem;
          print(
            '✅ [$_instanceId] Loaded menu item: ${menuItem.name} (${menuItem.id}) - Price: ${menuItem.price}',
          );
        } catch (e) {
          print('❌ [$_instanceId] Error parsing menu item: $e');
        }
      }

      menuItems.value = newMenuItems;

      // Check for missing items
      final missingItems = menuItemIds
          .where((id) => !newMenuItems.containsKey(id))
          .toList();
      if (missingItems.isNotEmpty) {
        print('⚠️ [$_instanceId] Missing menu items: $missingItems');
      }

      print('✅ [$_instanceId] Menu items loading completed');
    } catch (e) {
      print('❌ [$_instanceId] Error loading menu items: $e');
      rethrow;
    }
  }

  void _updatePaymentMethods() {
    if (!mounted) {
      print(
        '⚠️ [$_instanceId] Controller not mounted, skipping payment methods update',
      );
      return;
    }

    try {
      print('💳 [$_instanceId] Updating payment methods for pickup orders');

      // Check if PaymentService is available
      final bool serviceExists = Get.isRegistered<PaymentService>();
      print('🔧 [$_instanceId] PaymentService registered: $serviceExists');

      if (!serviceExists) {
        print(
          '❌ [$_instanceId] PaymentService not registered yet, skipping payment methods update',
        );
        availablePaymentMethods.clear();
        selectedPaymentMethod.value = null;
        return;
      }

      PaymentService? service;
      try {
        service = Get.find<PaymentService>();
      } catch (e) {
        print('❌ [$_instanceId] Failed to get PaymentService: $e');
        availablePaymentMethods.clear();
        selectedPaymentMethod.value = null;
        return;
      }

      // Always get payment methods for pickup orders
      final methods = service.getAvailablePaymentMethods('pickup');
      availablePaymentMethods.value = methods;

      print('✅ [$_instanceId] Found ${methods.length} payment methods:');
      for (int i = 0; i < methods.length; i++) {
        print(
          '   [$i] ${methods[i].name} (${methods[i].id}) - Online: ${methods[i].isOnline}',
        );
      }

      // Set default payment method
      if (selectedPaymentMethod.value == null ||
          !methods.any((m) => m.id == selectedPaymentMethod.value!.id)) {
        if (methods.isNotEmpty) {
          selectedPaymentMethod.value = methods.first;
          print(
            '💳 [$_instanceId] Set default payment method: ${methods.first.name}',
          );
        } else {
          selectedPaymentMethod.value = null;
          print('⚠️ [$_instanceId] No payment methods available');
        }
      } else {
        print(
          '💳 [$_instanceId] Keeping current payment method: ${selectedPaymentMethod.value?.name}',
        );
      }
    } catch (e) {
      print('❌ [$_instanceId] Error updating payment methods: $e');
      availablePaymentMethods.clear();
      selectedPaymentMethod.value = null;
    }
  }

  Future<void> retryLoad() async {
    print('🔄 [$_instanceId] Retrying cart data load...');
    await loadCartData();
  }

  @override
  void onClose() {
    print(
      '🔄 [$_instanceId] CartItemController.onClose() - PERMANENT CONTROLLER BEING DISPOSED',
    );
    print(
      '⚠️ [$_instanceId] This should NOT happen with permanent controllers!',
    );
    _logControllerState('onClose');
    instructionsController.dispose();
    super.onClose();
  }

  void _logControllerState(String location) {
    print('📊 [$_instanceId] === CONTROLLER STATE AT $location ===');
    print('   - Mounted: $mounted');
    print('   - Loading: ${isLoadingData.value}');
    print('   - Has Error: ${hasError.value}');
    print('   - Error Message: ${errorMessage.value}');
    print('   - Store Info: ${storeInfo.value?.name ?? 'null'}');
    print('   - Current User: ${currentUser.value?.fullName ?? 'null'}');
    print('   - Menu Items Count: ${menuItems.length}');
    print(
      '   - Selected Payment Method: ${selectedPaymentMethod.value?.name ?? 'null'}',
    );
    print('   - Available Payment Methods: ${availablePaymentMethods.length}');
    print('   - Cart Items (from service): ${cartService.cartItems.length}');
    print('   - Special Instructions: ${specialInstructions.value}');
    print('📊 [$_instanceId] === END STATE LOG ===');
  }

  // Calculations (simplified for pickup only)
  double get subtotal {
    try {
      final cartItems = cartService.cartItems;
      final result = cartItems.fold(
        0.0,
        (sum, item) => sum + (item.quantity * item.price),
      );
      print('💰 [$_instanceId] Calculated subtotal: $result');
      return result;
    } catch (e) {
      print('❌ [$_instanceId] Error calculating subtotal: $e');
      return 0;
    }
  }

  double get totalAmount {
    // For pickup orders, total is same as subtotal (no delivery fees)
    final total = subtotal;
    print(
      '💰 [$_instanceId] Total amount: $total (pickup only - no delivery fees)',
    );
    return total;
  }

  // User actions (removed delivery-related methods)
  void selectPaymentMethod(PaymentMethodOption method) {
    print(
      '💳 [$_instanceId] Selecting payment method: ${method.name} (${method.id})',
    );
    selectedPaymentMethod.value = method;
  }

  void showInstructionsBottomSheet() {
    print('📝 [$_instanceId] Showing instructions bottom sheet');
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Special Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instructionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Any special requests or notes for your order...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                child: const Text('Save Instructions'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showPaymentMethodBottomSheet() {
    print('💳 [$_instanceId] Showing payment method bottom sheet');
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: Get.height * 0.5,
              child: Obx(() {
                return ListView.builder(
                  itemCount: availablePaymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = availablePaymentMethods[index];
                    final isSelected =
                        selectedPaymentMethod.value?.id == method.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.orange.shade700
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: method.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(method.icon, color: method.color),
                        ),
                        title: Text(
                          method.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(method.description),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.orange.shade700,
                              )
                            : null,
                        onTap: () {
                          selectPaymentMethod(method);
                          Get.back();
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showConfirmationModal() {
    if (hasError.value) {
      print('⚠️ [$_instanceId] Cannot show confirmation - has error');
      Get.snackbar('Error', 'Please reload the cart data before placing order');
      return;
    }

    if (isLoadingData.value) {
      print('⚠️ [$_instanceId] Cannot show confirmation - still loading');
      Get.snackbar('Please Wait', 'Cart is still loading...');
      return;
    }

    print('🎯 [$_instanceId] Showing order confirmation modal');
    _logControllerState('showConfirmationModal');

    ModalAlert.showConfirmation(
      title: 'Confirm Pickup Order',
      subtitle: 'Are you sure you want to place this pickup order?',
      primaryButtonText: 'Yes, Place Order',
      secondaryButtonText: 'Cancel',
      onConfirm: () {
        Get.back();
        processOrder();
      },
      isProcessing: isProcessingOrder.value,
    );
  }

  void processOrder() async {
    if (isProcessingOrder.value) {
      print('⚠️ [$_instanceId] Order already being processed');
      return;
    }

    if (!_validateOrder()) {
      print('❌ [$_instanceId] Order validation failed');
      return;
    }

    print('🚀 [$_instanceId] Starting order processing...');
    _logControllerState('processOrder - START');
    isProcessingOrder.value = true;

    try {
      // Updated for pickup-only orders
      final result = await orderService.createOrderWithPayment(
        customerId: currentUser.value!.id,
        storeId: storeInfo.value!.id,
        customerName: currentUser.value!.fullName ?? 'Customer',
        customerPhone: currentUser.value!.phone ?? '+628123456789',
        subtotal: subtotal,
        totalAmount: totalAmount, // Same as subtotal for pickup
        paymentMethod: selectedPaymentMethod.value!.id,
        specialInstructions: specialInstructions.value.isEmpty
            ? null
            : specialInstructions.value,
        cartItems: cartService.cartItems,
      );

      if (result['success']) {
        final payment = result['payment'] as PaymentModel;
        final order = result['order'] as OrderModel;

        print('✅ [$_instanceId] Order created successfully:');
        print('   - Order ID: ${order.id}');
        print('   - Order Number: ${order.orderNumber}');
        print('   - Payment ID: ${payment.id}');
        print('   - Total Amount: ${payment.amount}');

        await cartService.clearCart();
        print(
          '🗑️ [$_instanceId] Cart cleared after successful order creation',
        );

        ToastHelper.showToast(
          context: Get.context!,
          title: 'Order Created',
          description: 'Please complete payment within 15 minutes',
          type: ToastificationType.success,
        );

        print('🧭 [$_instanceId] Navigating to payment page');
        Get.offNamed(
          Routes.PAYMENT,
          arguments: {'order': order, 'payment': payment},
        );
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      print('❌ [$_instanceId] Order processing error: $e');
      print('📍 [$_instanceId] Stack trace: ${StackTrace.current}');
      ToastHelper.showToast(
        context: Get.context!,
        title: 'Order Error',
        description: 'Failed to create order: $e',
        type: ToastificationType.error,
      );
    } finally {
      isProcessingOrder.value = false;
      print('🏁 [$_instanceId] Order processing finished');
    }
  }

  bool _validateOrder() {
    print('✅ [$_instanceId] Validating pickup order...');

    if (selectedPaymentMethod.value == null) {
      print('❌ [$_instanceId] Validation failed: No payment method selected');
      Get.snackbar('Error', 'Please select a payment method');
      return false;
    }

    final cartItems = cartService.cartItems;
    if (cartItems.isEmpty) {
      print('❌ [$_instanceId] Validation failed: Cart is empty');
      Get.snackbar('Error', 'Cart is empty');
      return false;
    }

    if (currentUser.value == null || storeInfo.value == null) {
      print(
        '❌ [$_instanceId] Validation failed: Required information not loaded',
      );
      print('   - Current User: ${currentUser.value != null}');
      print('   - Store Info: ${storeInfo.value != null}');
      Get.snackbar('Error', 'Required information not loaded');
      return false;
    }

    // Check minimum order amount if applicable
    if (storeInfo.value!.minimumOrder > 0 &&
        totalAmount < storeInfo.value!.minimumOrder) {
      print('❌ [$_instanceId] Validation failed: Below minimum order amount');
      Get.snackbar(
        'Error',
        'Minimum order amount is Rp ${storeInfo.value!.minimumOrder.toInt()}',
      );
      return false;
    }

    print('✅ [$_instanceId] Order validation passed');
    return true;
  }
}
