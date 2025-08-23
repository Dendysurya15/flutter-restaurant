import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StoreCardWidget extends StatelessWidget {
  final dynamic store;
  final VoidCallback? onTap;

  const StoreCardWidget({super.key, required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Image - Full width
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: store.imageUrl != null && store.imageUrl!.isNotEmpty
                    ? Image.network(
                        store.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
            ),

            // Store Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor().withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getStoreStatus(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Row with 3 columns
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Price Range
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPriceRange(store),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Middle Column - Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                store.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Column - Opening Hours
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _getTodayHours(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Address Row
                  if (store.address != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Service Badges Row
                  Row(
                    children: [
                      if (store.deliveryAvailable)
                        _buildServiceBadge(
                          'Delivery',
                          Icons.delivery_dining,
                          Colors.blue,
                        ),
                      if (store.deliveryAvailable && store.dineInAvailable)
                        const SizedBox(width: 8),
                      if (store.dineInAvailable)
                        _buildServiceBadge(
                          'Dine In',
                          Icons.restaurant,
                          Colors.purple,
                        ),
                      const Spacer(),

                      // Delivery fee if applicable
                      if (store.deliveryAvailable && store.deliveryFee > 0)
                        Text(
                          'Delivery: Rp ${NumberFormat('#,###', 'id_ID').format(store.deliveryFee.toInt())}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriceRange(dynamic store) {
    final minPrice = store.minimumOrder > 0
        ? store.minimumOrder.toInt()
        : 15000;
    final maxPrice = minPrice + 35000;

    return 'Rp ${NumberFormat('#,###', 'id_ID').format(minPrice)} - Rp ${NumberFormat('#,###', 'id_ID').format(maxPrice)}';
  }

  Color _getStatusColor() {
    if (!store.isActive) return Colors.grey;
    return _isOpenNow() ? Colors.green : Colors.red;
  }

  String _getStoreStatus() {
    if (!store.isActive) return 'Closed';
    return _isOpenNow() ? 'Open' : 'Closed';
  }

  bool _isOpenNow() {
    if (store.openingHours == null) return true;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final todayHours = store.openingHours![dayName];

    if (todayHours == null || todayHours == 'closed') return false;

    try {
      final parts = todayHours.split('-');
      if (parts.length != 2) return true;

      final openParts = parts[0].split(':');
      final closeParts = parts[1].split(':');

      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final currentHour = now.hour;
      final currentMinute = now.minute;
      final currentTotalMinutes = currentHour * 60 + currentMinute;
      final openTotalMinutes = openHour * 60 + openMinute;
      final closeTotalMinutes = closeHour * 60 + closeMinute;

      if (openTotalMinutes <= closeTotalMinutes) {
        return currentTotalMinutes >= openTotalMinutes &&
            currentTotalMinutes <= closeTotalMinutes;
      } else {
        return currentTotalMinutes >= openTotalMinutes ||
            currentTotalMinutes <= closeTotalMinutes;
      }
    } catch (e) {
      return true;
    }
  }

  String _getTodayHours() {
    if (store.openingHours == null) return 'No hours';

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final todayHours = store.openingHours![dayName];

    if (todayHours == null || todayHours == 'closed') {
      return 'Closed today';
    }

    return todayHours;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}
