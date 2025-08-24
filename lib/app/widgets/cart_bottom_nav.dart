import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';

class CartBottomNavWidget extends StatelessWidget {
  final String? currentStoreId;
  final String? currentStoreName;

  const CartBottomNavWidget({
    super.key,
    this.currentStoreId,
    this.currentStoreName,
  });

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return StreamBuilder<List<CartItemModel>>(
      stream: cartService.cartStream,
      builder: (context, snapshot) {
        final cartItems = cartService.cartItems;
        if (cartItems.isEmpty) return const SizedBox.shrink();

        final totalItems = cartService.totalItems;
        final totalPrice = cartService.totalPrice;

        // Get store name - priority: provided name > try to find from store ID > fallback
        String storeName = currentStoreName ?? 'Your Cart';

        // If no store name provided but we have cart items, try to determine store name
        if (currentStoreName == null && cartItems.isNotEmpty) {
          final firstItem = cartItems.first;
          // You can add logic here to fetch store name by storeId if needed
          // For now, show a generic message
          storeName = 'Your Order';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$totalItems items',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp.${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // Navigate to cart page
                  Get.toNamed('/cart');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lihat Keranjang',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
