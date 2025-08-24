import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';

class CartService {
  static const String _boxName = 'cart_items';
  late Box<CartItemModel> _cartBox;

  // Stream controller to notify UI of changes
  final StreamController<List<CartItemModel>> _cartStreamController =
      StreamController<List<CartItemModel>>.broadcast();

  Stream<List<CartItemModel>> get cartStream => _cartStreamController.stream;

  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Initialize Hive and open the box
  Future<void> init() async {
    await Hive.initFlutter();

    // Register the adapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CartItemModelAdapter());
    }

    _cartBox = await Hive.openBox<CartItemModel>(_boxName);

    // Emit initial cart items
    _emitCartItems();
  }

  // Get all cart items
  List<CartItemModel> get cartItems => _cartBox.values.toList();

  // Add item to cart
  Future<void> addToCart(MenuItemModel item) async {
    final existing = getCartItem(item.id);
    if (existing != null) {
      await incrementItem(item.id);
      return;
    }

    final cartItem = CartItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: 'customer_id', // Replace with actual customer id
      storeId: item.storeId ?? '',
      menuItemId: item.id,
      quantity: 1,
      price: item.price,
      specialInstructions: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _cartBox.put(cartItem.menuItemId, cartItem);
    _emitCartItems();
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
      _emitCartItems();
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
      _emitCartItems();
    }
  }

  // Remove item from cart
  Future<void> removeItem(String menuItemId) async {
    await _cartBox.delete(menuItemId);
    _emitCartItems();
  }

  // Clear cart
  Future<void> clearCart() async {
    await _cartBox.clear();
    _emitCartItems();
  }

  // Total items
  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Total price
  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.quantity * item.price);

  // Private method to emit cart changes
  void _emitCartItems() {
    _cartStreamController.add(cartItems);
  }

  // Close the box and stream controller
  Future<void> dispose() async {
    await _cartStreamController.close();
    await _cartBox.close();
  }
}
