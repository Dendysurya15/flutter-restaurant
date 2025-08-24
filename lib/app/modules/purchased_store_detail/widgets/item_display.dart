import 'package:flutter/material.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/services/cart_service.dart'; // Update this path

class ItemDisplayWidget extends StatefulWidget {
  final MenuItemModel item;
  final VoidCallback? onTap;

  const ItemDisplayWidget({super.key, required this.item, this.onTap});

  @override
  State<ItemDisplayWidget> createState() => _ItemDisplayWidgetState();
}

class _ItemDisplayWidgetState extends State<ItemDisplayWidget> {
  final CartService cartService = CartService();

  @override
  Widget build(BuildContext context) {
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
                    widget.item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp.${widget.item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 15,
                    ),
                  ),
                  if (widget.item.description != null &&
                      widget.item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.item.preparationTime != null) ...[
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
                          '${widget.item.preparationTime} min',
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
                  child: StreamBuilder<List<CartItemModel>>(
                    stream: cartService.cartStream,
                    builder: (context, snapshot) {
                      final cartItem = cartService.getCartItem(widget.item.id);
                      final quantity = cartItem?.quantity ?? 0;

                      if (quantity == 0) {
                        // Show only + button when quantity is 0
                        return IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            cartService.addToCart(widget.item);
                          },
                        );
                      } else {
                        // Show counter when quantity > 0
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (quantity <= 1) {
                                  cartService.removeItem(widget.item.id);
                                } else {
                                  cartService.decrementItem(widget.item.id);
                                }
                              },
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                cartService.incrementItem(widget.item.id);
                              },
                            ),
                          ],
                        );
                      }
                    },
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
      child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.item.imageUrl!,
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

  Widget _buildTags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.item.isVegetarian)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 12),
          ),
        if (widget.item.isSpicy)
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
}
