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
  final CartService cartService = Get.find<CartService>();
  final MenuService menuService = Get.find<MenuService>();

  // Initialize services
  late OrderService orderService;
  late PaymentService paymentService;

  @override
  void onInit() {
    super.onInit();
    // Initialize services
    if (!Get.isRegistered<OrderService>()) {
      Get.put(OrderService());
    }
    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService());
    }

    orderService = Get.find<OrderService>();
    paymentService = Get.find<PaymentService>();

    loadCartData();
    loadUserInfo();

    instructionsController.addListener(() {
      specialInstructions.value = instructionsController.text;
    });

    // Listen to order type changes to update payment methods
    ever(selectedOrderType, (_) => _updateAvailablePaymentMethods());
  }

  // Order type selection
  final selectedOrderType = 'dine_in'.obs;

  // Store information
  final Rx<StoreModel?> storeInfo = Rx<StoreModel?>(null);

  // User information
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Menu items lookup
  final RxMap<String, MenuItemModel> menuItems = <String, MenuItemModel>{}.obs;

  // Delivery address
  final deliveryAddress = ''.obs;
  final isLoadingLocation = false.obs;

  // Special instructions
  final specialInstructions = ''.obs;
  final TextEditingController instructionsController = TextEditingController();

  // Payment method selection
  final Rx<PaymentMethodOption?> selectedPaymentMethod =
      Rx<PaymentMethodOption?>(null);
  final RxList<PaymentMethodOption> availablePaymentMethods =
      <PaymentMethodOption>[].obs;

  // Loading states
  final isProcessingOrder = false.obs;
  final isLoadingData = true.obs;

  void _updateAvailablePaymentMethods() {
    print(
      '🔍 Updating payment methods for order type: ${selectedOrderType.value}',
    );

    availablePaymentMethods.value = paymentService.getAvailablePaymentMethods(
      selectedOrderType.value,
    );

    print('📋 Available methods count: ${availablePaymentMethods.length}');
    availablePaymentMethods.forEach((method) {
      print('   - ${method.name} (${method.id})');
    });

    // Set default payment method (first available)
    if (availablePaymentMethods.isNotEmpty) {
      selectedPaymentMethod.value = availablePaymentMethods.first;
      print('✅ Selected default method: ${selectedPaymentMethod.value?.name}');
    } else {
      print('❌ No payment methods available!');
    }
  }

  @override
  void onClose() {
    instructionsController.dispose();
    super.onClose();
  }

  void loadCartData() async {
    try {
      isLoadingData.value = true;
      final cartItems = cartService.cartItems;

      if (cartItems.isNotEmpty) {
        final storeId = cartItems.first.storeId;

        print('🔄 Starting to load cart data...');

        // Load store info and menu items in parallel and WAIT for both
        await Future.wait([
          loadStoreInfo(storeId),
          loadMenuItems(storeId, cartItems),
        ]);

        print('✅ All data loaded, updating payment methods...');

        // Update payment methods after loading store info
        _updateAvailablePaymentMethods();

        print('✅ Cart data loading complete!');
      }
    } catch (e) {
      print('❌ Error loading cart data: $e');
      Get.snackbar('Error', 'Failed to load cart data: $e');
    } finally {
      // Only set loading to false after EVERYTHING is complete
      isLoadingData.value = false;
    }
  }

  Future<void> loadStoreInfo(String storeId) async {
    try {
      final response = await StoreService.supabase
          .from('stores')
          .select()
          .eq('id', storeId)
          .single();

      storeInfo.value = StoreModel.fromJson(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load store information: $e');
    }
  }

  Future<void> loadMenuItems(
    String storeId,
    List<CartItemModel> cartItems,
  ) async {
    try {
      final menuItemIds = cartItems.map((item) => item.menuItemId).toList();
      print('Loading menu items for IDs: $menuItemIds'); // Debug log

      final response = await StoreService.supabase
          .from('menu_items')
          .select()
          .filter('id', 'in', '(${menuItemIds.join(',')})');

      print('Menu items response: ${response.length} items'); // Debug log

      for (final json in response) {
        final menuItem = MenuItemModel.fromJson(json);
        menuItems[menuItem.id] = menuItem;
        print(
          'Loaded menu item: ${menuItem.name} (${menuItem.id})',
        ); // Debug log
      }

      // Check for missing items
      for (final cartItem in cartItems) {
        if (!menuItems.containsKey(cartItem.menuItemId)) {
          print('WARNING: Menu item not found: ${cartItem.menuItemId}');
        }
      }
    } catch (e) {
      print('Error loading menu items: $e');
    }
  }

  void loadUserInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
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
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user information');
    }
  }

  void selectOrderType(String type) {
    selectedOrderType.value = type;
  }

  void selectPaymentMethod(PaymentMethodOption method) {
    selectedPaymentMethod.value = method;
  }

  void getCurrentLocation() async {
    isLoadingLocation.value = true;

    try {
      // TODO: Implement actual location service
      await Future.delayed(const Duration(seconds: 2));
      deliveryAddress.value = "Current Location: 123 Street, City, State";

      Get.snackbar(
        'Location Found',
        'Address updated successfully',
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
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
                    icon: isLoadingLocation.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      isLoadingLocation.value
                          ? 'Getting Location...'
                          : 'Use Current Location',
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

  double get subtotal {
    final cartItems = cartService.cartItems;
    return cartItems.fold(0, (sum, item) => sum + (item.quantity * item.price));
  }

  double get deliveryFee {
    if (selectedOrderType.value == 'delivery') {
      return storeInfo.value?.deliveryFee ?? 5000;
    }
    return 0;
  }

  double get totalAmount {
    return subtotal + deliveryFee;
  }

  void showConfirmationModal() {
    ModalAlert.showConfirmation(
      title: 'Confirm Order',
      subtitle: 'Are you sure you want to place this order?',
      primaryButtonText: 'Yes, Place Order',
      secondaryButtonText: 'Cancel',
      onConfirm: () {
        Get.back(); // Close modal
        processOrder(); // Process the order
      },
      isProcessing: isProcessingOrder.value,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
    );
  }

  void processOrder() async {
    if (isProcessingOrder.value) return;

    if (!_validateOrder()) return;

    isProcessingOrder.value = true;

    try {
      // Create order with payment in Supabase
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

        // Clear cart since order is created in database
        await cartService.clearCart();

        ToastHelper.showToast(
          context: Get.context!,
          title: 'Order Created',
          description: 'Please complete payment within 15 minutes',
          type: ToastificationType.success,
        );

        // Navigate to payment countdown view
        Get.offNamed(
          Routes.PAYMENT,
          arguments: {'order': order, 'payment': payment},
        );
      } else {
        print(result['message'] ?? 'Unknown error');
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Order Failed',
          description: result['message'],
          type: ToastificationType.error,
        );
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

    if (subtotal < (storeInfo.value?.minimumOrder ?? 0)) {
      Get.snackbar(
        'Error',
        'Minimum order amount is Rp.${storeInfo.value?.minimumOrder ?? 0}',
      );
      return false;
    }

    if (currentUser.value == null) {
      Get.snackbar('Error', 'User information not available');
      return false;
    }

    if (storeInfo.value == null) {
      Get.snackbar('Error', 'Store information not available');
      return false;
    }

    return true;
  }
}
