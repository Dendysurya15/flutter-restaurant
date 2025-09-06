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
  // Lazy service getters - prevent race conditions
  CartService get cartService => Get.find<CartService>();
  MenuService get menuService => Get.find<MenuService>();
  OrderService get orderService => Get.find<OrderService>();
  PaymentService get paymentService => Get.find<PaymentService>();

  // State management
  final isLoadingData = true.obs;
  final isProcessingOrder = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Data observables
  final selectedOrderType = 'dine_in'.obs;
  final Rx<StoreModel?> storeInfo = Rx<StoreModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxMap<String, MenuItemModel> menuItems = <String, MenuItemModel>{}.obs;
  final deliveryAddress = ''.obs;
  final isLoadingLocation = false.obs;
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
    print('🚀 CartItemController.onInit() - Setting up listeners');

    instructionsController.addListener(() {
      specialInstructions.value = instructionsController.text;
    });

    ever(selectedOrderType, (_) {
      print('📝 Order type changed to: ${selectedOrderType.value}');
      _updatePaymentMethods();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('🎯 CartItemController.onReady() - Starting data load');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCartData();
    });
  }

  Future<void> loadCartData() async {
    if (!mounted) return;

    print('🔄 Starting cart data load...');
    isLoadingData.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Check cart items first
      final cartItems = cartService.cartItems;
      print('📦 Cart items count: ${cartItems.length}');

      if (cartItems.isEmpty) {
        print('⚠️ Cart is empty, finishing load');
        return;
      }

      // Load user info
      await _loadUserInfo();

      // Load store and menu data in parallel
      final storeId = cartItems.first.storeId;
      print('🏪 Loading data for store: $storeId');

      await Future.wait([
        _loadStoreInfo(storeId),
        _loadMenuItems(storeId, cartItems),
      ]);

      // Update payment methods
      _updatePaymentMethods();

      print('✅ Cart data load completed successfully');
    } catch (e) {
      print('❌ Error loading cart data: $e');
      hasError.value = true;
      errorMessage.value = 'Failed to load cart data: $e';
    } finally {
      if (mounted) {
        isLoadingData.value = false;
      }
    }
  }

  Future<void> _loadUserInfo() async {
    print('👤 Loading user information...');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    if (!mounted) return;

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

    if (currentUser.value?.address != null) {
      deliveryAddress.value = currentUser.value!.address!;
    }

    print('✅ User info loaded: ${currentUser.value?.fullName}');
  }

  Future<void> _loadStoreInfo(String storeId) async {
    print('🏪 Loading store info for: $storeId');

    final response = await StoreService.supabase
        .from('stores')
        .select()
        .eq('id', storeId)
        .single()
        .timeout(const Duration(seconds: 10));

    if (!mounted) return;

    storeInfo.value = StoreModel.fromJson(response);
    print('✅ Store info loaded: ${storeInfo.value?.name}');
  }

  Future<void> _loadMenuItems(
    String storeId,
    List<CartItemModel> cartItems,
  ) async {
    print('📋 Loading menu items...');

    final menuItemIds = cartItems.map((item) => item.menuItemId).toList();
    print('🔍 Looking for menu items: $menuItemIds');

    if (menuItemIds.isEmpty) {
      print('⚠️ No menu item IDs to load');
      return;
    }

    final response = await StoreService.supabase
        .from('menu_items')
        .select()
        .filter('id', 'in', '(${menuItemIds.join(',')})')
        .timeout(const Duration(seconds: 10));

    print('📋 Retrieved ${response.length} menu items from database');

    if (!mounted) return;

    final Map<String, MenuItemModel> newMenuItems = {};

    for (final json in response) {
      try {
        final menuItem = MenuItemModel.fromJson(json);
        newMenuItems[menuItem.id] = menuItem;
        print('✅ Loaded menu item: ${menuItem.name} (${menuItem.id})');
      } catch (e) {
        print('❌ Error parsing menu item: $e');
      }
    }

    menuItems.value = newMenuItems;

    // Check for missing items
    final missingItems = menuItemIds
        .where((id) => !newMenuItems.containsKey(id))
        .toList();
    if (missingItems.isNotEmpty) {
      print('⚠️ Missing menu items: $missingItems');
    }

    print('✅ Menu items loading completed');
  }

  void _updatePaymentMethods() {
    if (!mounted) return;

    try {
      print('💳 Updating payment methods for: ${selectedOrderType.value}');

      final methods = paymentService.getAvailablePaymentMethods(
        selectedOrderType.value,
      );

      availablePaymentMethods.value = methods;
      print('✅ Found ${methods.length} payment methods');

      if (selectedPaymentMethod.value == null ||
          !methods.any((m) => m.id == selectedPaymentMethod.value!.id)) {
        if (methods.isNotEmpty) {
          selectedPaymentMethod.value = methods.first;
          print('💳 Set default payment method: ${methods.first.name}');
        }
      }
    } catch (e) {
      print('❌ Error updating payment methods: $e');
    }
  }

  Future<void> retryLoad() async {
    print('🔄 Retrying cart data load...');
    await loadCartData();
  }

  @override
  void onClose() {
    print('🔄 CartItemController.onClose()');
    instructionsController.dispose();
    super.onClose();
  }

  // Calculations
  double get subtotal {
    try {
      final cartItems = cartService.cartItems;
      return cartItems.fold(
        0,
        (sum, item) => sum + (item.quantity * item.price),
      );
    } catch (e) {
      print('❌ Error calculating subtotal: $e');
      return 0;
    }
  }

  double get deliveryFee {
    if (selectedOrderType.value == 'delivery') {
      return storeInfo.value?.deliveryFee ?? 5000;
    }
    return 0;
  }

  double get totalAmount => subtotal + deliveryFee;

  // User actions
  void selectOrderType(String type) {
    print('📝 Selecting order type: $type');
    selectedOrderType.value = type;
  }

  void selectPaymentMethod(PaymentMethodOption method) {
    print('💳 Selecting payment method: ${method.name}');
    selectedPaymentMethod.value = method;
  }

  void getCurrentLocation() async {
    print('📍 Getting current location...');
    isLoadingLocation.value = true;

    try {
      await Future.delayed(const Duration(seconds: 2));
      deliveryAddress.value = "Current Location: 123 Street, City, State";

      print('✅ Location found: ${deliveryAddress.value}');
      Get.snackbar(
        'Location Found',
        'Address updated successfully',
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      Get.snackbar('Error', 'Failed to get current location');
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void showAddressBottomSheet() {
    final TextEditingController addressController = TextEditingController();
    addressController.text = deliveryAddress.value;

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
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Address',
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
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your delivery address...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: getCurrentLocation,
                    icon: Obx(
                      () => isLoadingLocation.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                    label: Obx(
                      () => Text(
                        isLoadingLocation.value
                            ? 'Getting Location...'
                            : 'Use Current Location',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      deliveryAddress.value = addressController.text;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                    ),
                    child: const Text('Save Address'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void showInstructionsBottomSheet() {
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
                const Icon(Icons.note_add, color: Colors.blue),
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
                  backgroundColor: Colors.blue.shade700,
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
                const Icon(Icons.payment, color: Colors.blue),
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
                              ? Colors.blue.shade700
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
                                color: Colors.blue.shade700,
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
      Get.snackbar('Error', 'Please reload the cart data before placing order');
      return;
    }

    if (isLoadingData.value) {
      Get.snackbar('Please Wait', 'Cart is still loading...');
      return;
    }

    print('🎯 Showing order confirmation modal');
    ModalAlert.showConfirmation(
      title: 'Confirm Order',
      subtitle: 'Are you sure you want to place this order?',
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
    if (isProcessingOrder.value) return;
    if (!_validateOrder()) return;

    print('🚀 Starting order processing...');
    isProcessingOrder.value = true;

    try {
      final result = await orderService.createOrderWithPayment(
        customerId: currentUser.value!.id,
        storeId: storeInfo.value!.id,
        orderType: selectedOrderType.value,
        customerName: currentUser.value!.fullName ?? 'Customer',
        customerPhone: currentUser.value!.phone ?? '+628123456789',
        deliveryAddress: selectedOrderType.value == 'delivery'
            ? deliveryAddress.value
            : null,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        paymentMethod: selectedPaymentMethod.value!.id,
        specialInstructions: specialInstructions.value.isEmpty
            ? null
            : specialInstructions.value,
        cartItems: cartService.cartItems,
      );

      if (result['success']) {
        final payment = result['payment'] as PaymentModel;
        final order = result['order'] as OrderModel;

        print('✅ Order created successfully: ${order.id}');
        await cartService.clearCart();

        ToastHelper.showToast(
          context: Get.context!,
          title: 'Order Created',
          description: 'Please complete payment within 15 minutes',
          type: ToastificationType.success,
        );

        Get.offNamed(
          Routes.PAYMENT,
          arguments: {'order': order, 'payment': payment},
        );
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      print('❌ Order processing error: $e');
      ToastHelper.showToast(
        context: Get.context!,
        title: 'Order Error',
        description: 'Failed to create order: $e',
        type: ToastificationType.error,
      );
    } finally {
      isProcessingOrder.value = false;
    }
  }

  bool _validateOrder() {
    if (selectedOrderType.value == 'delivery' &&
        deliveryAddress.value.isEmpty) {
      Get.snackbar('Error', 'Please provide delivery address');
      return false;
    }

    if (selectedPaymentMethod.value == null) {
      Get.snackbar('Error', 'Please select a payment method');
      return false;
    }

    final cartItems = cartService.cartItems;
    if (cartItems.isEmpty) {
      Get.snackbar('Error', 'Cart is empty');
      return false;
    }

    if (currentUser.value == null || storeInfo.value == null) {
      Get.snackbar('Error', 'Required information not loaded');
      return false;
    }

    return true;
  }
}
