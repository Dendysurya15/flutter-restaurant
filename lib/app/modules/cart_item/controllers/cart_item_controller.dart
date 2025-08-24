import 'package:get/get.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';

class CartItemController extends GetxController {
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;

  // Add item to cart
  void addToCart(MenuItemModel item) {
    final existing = cartItems.firstWhereOrNull((e) => e.menuItemId == item.id);
    if (existing != null) {
      incrementItem(item.id);
      return;
    }
    cartItems.add(
      CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: 'customer_id', // Replace with actual customer id
        storeId: item.storeId ?? '',
        menuItemId: item.id,
        quantity: 1,
        price: item.price,
        specialInstructions: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Get cart item by menuItemId
  CartItemModel? getCartItem(String menuItemId) {
    return cartItems.firstWhereOrNull((e) => e.menuItemId == menuItemId);
  }

  // Increment item quantity
  void incrementItem(String menuItemId) {
    final item = getCartItem(menuItemId);
    if (item != null) {
      final updated = CartItemModel(
        id: item.id,
        customerId: item.customerId,
        storeId: item.storeId,
        menuItemId: item.menuItemId,
        quantity: item.quantity + 1,
        price: item.price,
        specialInstructions: item.specialInstructions,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );
      final idx = cartItems.indexOf(item);
      cartItems[idx] = updated;
    }
  }

  // Decrement item quantity
  void decrementItem(String menuItemId) {
    final item = getCartItem(menuItemId);
    if (item != null) {
      if (item.quantity > 1) {
        final updated = CartItemModel(
          id: item.id,
          customerId: item.customerId,
          storeId: item.storeId,
          menuItemId: item.menuItemId,
          quantity: item.quantity - 1,
          price: item.price,
          specialInstructions: item.specialInstructions,
          createdAt: item.createdAt,
          updatedAt: DateTime.now(),
        );
        final idx = cartItems.indexOf(item);
        cartItems[idx] = updated;
      } else {
        cartItems.remove(item);
      }
    }
  }

  // Remove item from cart
  void removeItem(String menuItemId) {
    final item = getCartItem(menuItemId);
    if (item != null) {
      cartItems.remove(item);
    }
  }

  // Clear cart
  void clearCart() {
    cartItems.clear();
  }

  // Total items
  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Total price (requires price from MenuItemModel, so you may need to store price in CartItemModel)
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.quantity * item.price);
}
