import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/modules/cart_item/controllers/cart_item_controller.dart';

class ItemDisplayWidget extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback? onTap;

  const ItemDisplayWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartItemController>();
    CartItemModel? cartItem = cartController.getCartItem(item.id);
    // If not in cart, create a temporary cartItem with quantity 1 for UI
    if (cartItem == null) {
      cartItem = CartItemModel(
        id: '',
        customerId: '',
        storeId: item.storeId ?? '',
        menuItemId: item.id,
        quantity: 1,
        price: item.price,
        specialInstructions: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Name and Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp.${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 15,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.preparationTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.preparationTime} min',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildTags(),
                ],
              ),
            ),
            // Right: Image and Button/Counter
            Column(
              children: [
                SizedBox(width: 60, height: 60, child: _buildImage()),
                const SizedBox(height: 8),
                SizedBox(
                  width: 60,
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          if (cartController.getCartItem(item.id) == null ||
                              cartItem!.quantity <= 1) {
                            cartController.removeItem(item.id);
                          } else {
                            cartController.decrementItem(item.id);
                          }
                        },
                      ),
                      Text(
                        '${cartController.getCartItem(item.id)?.quantity ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          if (cartController.getCartItem(item.id) == null) {
                            cartController.addToCart(item);
                          } else {
                            cartController.incrementItem(item.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: Icon(Icons.restaurant_menu, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildTags(),
      ],
    );
  }

  Widget _buildTags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.isVegetarian)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 12),
          ),
        if (item.isSpicy)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.description!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Rp.${item.price}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            if (item.preparationTime != null) ...[
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.preparationTime} min',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    // Use a controller/provider for cart state, here is a simple example using GetX
    final cartController = Get.find<CartItemController>();
    final cartItem = cartController.getCartItem(item.id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 48, height: 48, child: _buildImage()),
        const SizedBox(width: 8),
        cartItem == null
            ? SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(60, 32),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    cartController.addToCart(item);
                  },
                ),
              )
            : SizedBox(
                height: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        cartController.decrementItem(item.id);
                      },
                    ),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        cartController.incrementItem(item.id);
                      },
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
