import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:restaurant/app/modules/admin_manage_store/controllers/admin_manage_store_controller.dart';
import 'package:restaurant/app/data/models/store_model.dart';

class TableWidget extends GetView<AdminManageStoreController> {
  const TableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.stores.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredStores.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No stores found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Stores (${controller.filteredStores.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (controller.isLoading.value)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // DataTable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade50,
                  ),
                  dataRowColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.blue.shade50;
                    }
                    return null;
                  }),
                  columns: [
                    DataColumn(
                      label: const Text(
                        'Store',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: (columnIndex, ascending) {
                        controller.sort(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: (columnIndex, ascending) {
                        controller.sort(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: (columnIndex, ascending) {
                        controller.sort(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: (columnIndex, ascending) {
                        controller.sort(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Created',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: (columnIndex, ascending) {
                        controller.sort(columnIndex, ascending);
                      },
                    ),
                    const DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: controller.filteredStores.map((store) {
                    return DataRow(
                      cells: [
                        // Store Name with Image
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: store.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          store.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.store,
                                                  color: Colors.grey.shade400,
                                                  size: 20,
                                                );
                                              },
                                        ),
                                      )
                                    : Icon(
                                        Icons.store,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    store.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (store.phone != null)
                                    Text(
                                      store.phone!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Category
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              store.category,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Address
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              store.address ?? 'No address',
                              style: TextStyle(
                                color: store.address != null
                                    ? Colors.black
                                    : Colors.grey.shade500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),

                        // Status
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: store.isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: store.isActive
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: store.isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  store.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: store.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Created Date
                        DataCell(
                          Text(
                            DateFormat('MMM dd\nyyyy').format(store.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Toggle Status Button
                              Tooltip(
                                message: store.isActive
                                    ? 'Deactivate'
                                    : 'Activate',
                                child: InkWell(
                                  onTap: () =>
                                      _showToggleDialog(context, store),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: store.isActive
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: store.isActive
                                            ? Colors.red.shade200
                                            : Colors.green.shade200,
                                      ),
                                    ),
                                    child: Icon(
                                      store.isActive
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 14,
                                      color: store.isActive
                                          ? Colors.red.shade600
                                          : Colors.green.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // More Actions
                              PopupMenuButton<String>(
                                tooltip: 'More Actions',
                                onSelected: (value) =>
                                    _handleMenuAction(context, value, store),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 16),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit Store'),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showToggleDialog(BuildContext context, StoreModel store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.isActive ? 'Deactivate Store' : 'Activate Store'),
        content: Text(
          store.isActive
              ? 'Are you sure you want to deactivate "${store.name}"? This will make the store unavailable to customers.'
              : 'Are you sure you want to activate "${store.name}"? This will make the store available to customers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.toggleStoreStatus(store);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: store.isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(store.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    StoreModel store,
  ) {
    switch (action) {
      case 'view':
        _showStoreDetails(context, store);
        break;
      case 'edit':
        Get.snackbar('Info', 'Edit store functionality not implemented yet');
        break;
    }
  }

  void _showStoreDetails(BuildContext context, StoreModel store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Category', store.category),
              if (store.description != null)
                _DetailRow('Description', store.description!),
              if (store.address != null) _DetailRow('Address', store.address!),
              if (store.phone != null) _DetailRow('Phone', store.phone!),
              _DetailRow(
                'Delivery Available',
                store.deliveryAvailable ? 'Yes' : 'No',
              ),
              _DetailRow(
                'Dine-in Available',
                store.dineInAvailable ? 'Yes' : 'No',
              ),
              if (store.deliveryAvailable) ...[
                _DetailRow(
                  'Delivery Fee',
                  'Rp ${NumberFormat('#,###').format(store.deliveryFee)}',
                ),
                _DetailRow(
                  'Minimum Order',
                  'Rp ${NumberFormat('#,###').format(store.minimumOrder)}',
                ),
              ],
              _DetailRow('Status', store.isActive ? 'Active' : 'Inactive'),
              _DetailRow(
                'Created',
                DateFormat('MMM dd, yyyy HH:mm').format(store.createdAt),
              ),
              _DetailRow(
                'Last Updated',
                DateFormat('MMM dd, yyyy HH:mm').format(store.updatedAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
