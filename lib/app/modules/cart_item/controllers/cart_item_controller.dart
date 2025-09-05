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

  bool get mounted => !isClosed;

  // Initialize services
  late OrderService orderService;
  late PaymentService paymentService;

  // Add initialization tracking
  final isInitialized = false.obs;
  bool _isInitializing = false;

  @override
  void onInit() {
    super.onInit();

    instructionsController.addListener(() {
      specialInstructions.value = instructionsController.text;
    });

    // Only listen to order type changes AFTER initialization
    ever(selectedOrderType, (_) {
      if (isInitialized.value) {
        _updateAvailablePaymentMethods();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Use WidgetsBinding to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEverything();
    });
  }

  Future<void> _initializeEverything() async {
    if (!mounted || _isInitializing) return;

    _isInitializing = true;
    isLoadingData.value = true;
    isInitialized.value = false;

    try {
      // Force service initialization first
      orderService = Get.find<OrderService>();
      paymentService = Get.find<PaymentService>();

      // Load user info first
      await loadUserInfo();

      // Then load cart-related data
      final cartItems = cartService.cartItems;
      if (cartItems.isNotEmpty) {
        final storeId = cartItems.first.storeId;

        // Load store and menu items in parallel
        await Future.wait([
          loadStoreInfo(storeId),
          loadMenuItems(storeId, cartItems),
        ]);

        // Update payment methods after everything is loaded
        _updateAvailablePaymentMethods();
      }

      // Mark as initialized
      isInitialized.value = true;
    } catch (e) {
      print('Error in initialization: $e');
      Get.snackbar('Error', 'Failed to initialize cart: $e');
    } finally {
      if (mounted) {
        isLoadingData.value = false;
        _isInitializing = false;
      }
    }
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
    if (!mounted || paymentService == null) return;

    try {
      final methods = paymentService.getAvailablePaymentMethods(
        selectedOrderType.value,
      );

      availablePaymentMethods.value = methods;

      // Only set selected method if none is selected or if current selection is not available
      if (selectedPaymentMethod.value == null ||
          !methods.any((m) => m.id == selectedPaymentMethod.value!.id)) {
        if (methods.isNotEmpty) {
          selectedPaymentMethod.value = methods.first;
        }
      }
    } catch (e) {
      print('Error updating payment methods: $e');
    }
  }

  @override
  void onClose() {
    instructionsController.dispose();
    super.onClose();
  }

  Future<void> loadStoreInfo(String storeId) async {
    try {
      final response = await StoreService.supabase
          .from('stores')
          .select()
          .eq('id', storeId)
          .single();

      if (mounted) {
        storeInfo.value = StoreModel.fromJson(response);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to load store information: $e');
      }
    }
  }

  Future<void> loadMenuItems(
    String storeId,
    List<CartItemModel> cartItems,
  ) async {
    try {
      final menuItemIds = cartItems.map((item) => item.menuItemId).toList();
      print('Loading menu items for IDs: $menuItemIds');

      final response = await StoreService.supabase
          .from('menu_items')
          .select()
          .filter('id', 'in', '(${menuItemIds.join(',')})');

      print('Menu items response: ${response.length} items');

      if (mounted) {
        final Map<String, MenuItemModel> newMenuItems = {};

        for (final json in response) {
          final menuItem = MenuItemModel.fromJson(json);
          newMenuItems[menuItem.id] = menuItem;
          print('Loaded menu item: ${menuItem.name} (${menuItem.id})');
        }

        menuItems.value = newMenuItems;

        // Check for missing items
        for (final cartItem in cartItems) {
          if (!menuItems.containsKey(cartItem.menuItemId)) {
            print('WARNING: Menu item not found: ${cartItem.menuItemId}');
          }
        }
      }
    } catch (e) {
      print('Error loading menu items: $e');
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
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
      if (mounted) {
        Get.snackbar('Error', 'Failed to load user information');
      }
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
