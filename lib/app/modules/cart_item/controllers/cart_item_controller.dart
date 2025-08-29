import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/services/store_service.dart';
import 'package:restaurant/app/services/menu_service.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/data/models/user_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';

class CartItemController extends GetxController {
  final CartService cartService = Get.find<CartService>();

  final MenuService menuService = Get.find<MenuService>();

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

  // Loading states
  final isProcessingOrder = false.obs;
  final isLoadingData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCartData();
    loadUserInfo();

    // Listen to instructions changes
    instructionsController.addListener(() {
      specialInstructions.value = instructionsController.text;
    });
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

        // Load store info and menu items in parallel
        await Future.wait([
          loadStoreInfo(storeId),
          loadMenuItems(storeId, cartItems),
        ]);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load cart data: $e');
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> loadStoreInfo(String storeId) async {
    try {
      // Get store from Supabase
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
      // Get unique menu item IDs from cart
      final menuItemIds = cartItems.map((item) => item.menuItemId).toList();

      // Fetch menu items from Supabase using 'in' filter
      final response = await StoreService.supabase
          .from('menu_items')
          .select()
          .filter('id', 'in', '(${menuItemIds.join(',')})');

      // Convert to MenuItemModel and store in map

      print(response);
      for (final json in response) {
        final menuItem = MenuItemModel.fromJson(json);
        menuItems[menuItem.id] = menuItem;

        print("Menu Item Loaded: ${menuItem.name} - ${menuItem.id}");
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load menu items: $e');
    }
  }

  void loadUserInfo() async {
    try {
      // TODO: Get current user from your auth service
      // currentUser.value = await authService.getCurrentUser();

      // Mock user data for now
      currentUser.value = UserModel(
        id: 'user_id',
        email: 'user@example.com',
        role: 'customer',
        fullName: 'John Doe',
        phone: '+1234567890',
        address: '123 Main St, City',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set default delivery address if available
      if (currentUser.value?.address != null) {
        deliveryAddress.value = currentUser.value!.address!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user information');
    }
  }

  void selectOrderType(String type) {
    selectedOrderType.value = type;
  }

  void getCurrentLocation() async {
    isLoadingLocation.value = true;

    try {
      // TODO: Implement location service
      // final position = await locationService.getCurrentPosition();
      // final address = await locationService.getAddressFromCoordinates(position);

      // Mock location for now
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

  void processOrder() async {
    if (isProcessingOrder.value) return;

    // Validation
    if (selectedOrderType.value == 'delivery' &&
        deliveryAddress.value.isEmpty) {
      Get.snackbar('Error', 'Please provide delivery address');
      return;
    }

    final cartItems = cartService.cartItems;
    if (cartItems.isEmpty) {
      Get.snackbar('Error', 'Cart is empty');
      return;
    }

    if (subtotal < (storeInfo.value?.minimumOrder ?? 0)) {
      Get.snackbar(
        'Error',
        'Minimum order amount is Rp.${storeInfo.value?.minimumOrder ?? 0}',
      );
      return;
    }

    isProcessingOrder.value = true;

    try {
      // TODO: Create order in your backend
      // final orderData = {
      //   'customer_id': currentUser.value?.id,
      //   'store_id': storeInfo.value?.id,
      //   'order_type': selectedOrderType.value,
      //   'delivery_address': selectedOrderType.value == 'delivery' ? deliveryAddress.value : null,
      //   'subtotal': subtotal,
      //   'delivery_fee': deliveryFee,
      //   'total_amount': totalAmount,
      //   'special_instructions': specialInstructions.value,
      //   'items': cartItems.map((item) => item.toJson()).toList(),
      // };

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart after successful order
      await cartService.clearCart();

      Get.snackbar(
        'Order Placed!',
        'Your order has been placed successfully',
        backgroundColor: Colors.green.shade100,
      );

      // Navigate to order confirmation or orders page
      Get.offAllNamed('/orders'); // or wherever you want to redirect
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order. Please try again.');
    } finally {
      isProcessingOrder.value = false;
    }
  }
}
