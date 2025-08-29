import 'dart:async';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';

class CartService extends GetxController {
  static const String _boxName = 'cart_items';
  late Box<CartItemModel> _cartBox;

  // Use GetX observable instead of Stream
  final RxList<CartItemModel> _cartItems = <CartItemModel>[].obs;

  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Getter for reactive cart items
  RxList<CartItemModel> get cartItems => _cartItems;

  // Initialize Hive and open the box
  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CartItemModelAdapter());
    }

    _cartBox = await Hive.openBox<CartItemModel>(_boxName);

    // Load initial cart items into observable list
    _loadCartItems();
  }

  // Load cart items from Hive into observable list
  void _loadCartItems() {
    _cartItems.value = _cartBox.values.toList();
    update(); // Notify GetBuilder widgets
  }

  // Add item to cart
  Future<void> addToCart(MenuItemModel item) async {
    final existing = getCartItem(item.id);
    if (existing != null) {
      await incrementItem(item.id);
      return;
    }

    final cartItem = CartItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: 'customer_id',
      storeId: item.storeId ?? '',
      menuItemId: item.id,
      quantity: 1,
      price: item.price,
      specialInstructions: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive then update observable
    await _cartBox.put(cartItem.menuItemId, cartItem);
    _loadCartItems();
  }

  // Get cart item by menuItemId
  CartItemModel? getCartItem(String menuItemId) {
    return _cartBox.get(menuItemId);
  }

  // Increment item quantity
  Future<void> incrementItem(String menuItemId) async {
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
      await _cartBox.put(menuItemId, updated);
      _loadCartItems();
    }
  }

  // Decrement item quantity
  Future<void> decrementItem(String menuItemId) async {
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
        await _cartBox.put(menuItemId, updated);
      } else {
        await _cartBox.delete(menuItemId);
      }
      _loadCartItems();
    }
  }

  // Remove item from cart
  Future<void> removeItem(String menuItemId) async {
    await _cartBox.delete(menuItemId);
    _loadCartItems();
  }

  // Clear cart
  Future<void> clearCart() async {
    await _cartBox.clear();
    _loadCartItems();
  }

  // Total items - now reactive
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Total price - now reactive
  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity * item.price);

  // Close the box
  Future<void> dispose() async {
    await _cartBox.close();
  }
}
