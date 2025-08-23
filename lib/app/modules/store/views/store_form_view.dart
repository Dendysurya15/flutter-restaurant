import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/widgets/form/field_text.dart';
import 'package:restaurant/app/widgets/form/field_number.dart';
import 'package:restaurant/app/widgets/form/field_dropdown.dart';
import 'package:restaurant/app/widgets/form/field_switch.dart';
import 'package:restaurant/app/widgets/form/section_title.dart';
import 'package:restaurant/app/widgets/form/custom_button.dart';
import '../controllers/store_controller.dart';

class StoreFormView extends GetView<StoreController> {
  const StoreFormView({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if editing existing store
    final dynamic editingStore = Get.arguments;
    final bool isEditing = editingStore != null;

    // Initialize form with existing data if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        controller.initializeFormForEditing(editingStore);
      } else {
        controller.resetForm();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Store' : 'Add Store'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              const SectionTitle(title: 'Basic Information', icon: Icons.info),
              const SizedBox(height: 16),

              FieldText(
                controller: controller.nameController,
                label: 'Store Name',
                hint: 'Enter your store name',
                icon: Icons.store,
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Store name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              FieldDropdown<String>(
                value: controller.categoryController.text.isEmpty
                    ? null
                    : controller.categoryController.text,
                items: RestaurantCategories.dropdownItems,
                label: 'Category',
                hint: 'Select category',
                icon: Icons.category,
                onChanged: (value) =>
                    controller.categoryController.text = value ?? '',
                validator: (value) =>
                    value?.isEmpty == true ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),

              FieldText(
                controller: controller.descriptionController,
                label: 'Description (Optional)',
                hint: 'Describe your store',
                icon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Contact Information
              const SectionTitle(
                title: 'Contact Information',
                icon: Icons.contact_phone,
              ),
              const SizedBox(height: 16),

              FieldText(
                controller: controller.addressController,
                label: 'Address (Optional)',
                hint: 'Enter full address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              FieldText(
                controller: controller.phoneController,
                label: 'Phone (Optional)',
                hint: 'Enter phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Opening Hours
              const SectionTitle(
                title: 'Opening Hours',
                icon: Icons.access_time,
              ),
              const SizedBox(height: 16),
              _buildOpeningHoursSection(),

              const SizedBox(height: 24),

              // Service Settings
              const SectionTitle(
                title: 'Service Settings',
                icon: Icons.settings,
              ),
              const SizedBox(height: 16),

              FieldSwitch(
                title: 'Delivery Available',
                subtitle: 'Enable delivery service for customers',
                value: controller.deliveryAvailable,
                onChanged: (value) =>
                    controller.deliveryAvailable.value = value,
                icon: Icons.delivery_dining,
              ),

              FieldSwitch(
                title: 'Dine-In Available',
                subtitle: 'Allow customers to dine in your restaurant',
                value: controller.dineInAvailable,
                onChanged: (value) => controller.dineInAvailable.value = value,
                icon: Icons.restaurant,
              ),

              const SizedBox(height: 24),

              // Pricing
              const SectionTitle(title: 'Pricing', icon: Icons.attach_money),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FieldNumber(
                      controller: controller.deliveryFeeController,
                      label: 'Delivery Fee',
                      hint: '0',
                      icon: Icons.money,
                      prefixText: 'Rp ',
                      min: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FieldNumber(
                      controller: controller.minimumOrderController,
                      label: 'Minimum Order',
                      hint: '0',
                      icon: Icons.shopping_cart,
                      prefixText: 'Rp ',
                      min: 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Store Status (only show when editing)
              if (isEditing) ...[
                const SectionTitle(
                  title: 'Store Status',
                  icon: Icons.toggle_on,
                ),
                const SizedBox(height: 16),
                FieldSwitch(
                  title: 'Store Active',
                  subtitle: 'Customers can see and order from your store',
                  value: controller.isStoreActive,
                  onChanged: (value) => controller.isStoreActive.value = value,
                  icon: Icons.visibility,
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => PrimaryButton(
                        text: isEditing ? 'Update Store' : 'Create Store',
                        icon: isEditing ? Icons.update : Icons.add_business,
                        onPressed: () {
                          if (isEditing) {
                            controller.updateStore(editingStore.id);
                          } else {
                            controller.createStore();
                          }
                        },
                        isLoading: controller.isLoading.value,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your store opening hours',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final dayName = dayNames[index];

              return Obx(() => _buildDayRow(day, dayName));
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String day, String dayName) {
    final currentHours = controller.openingHours[day] ?? 'closed';
    final isClosed = currentHours == 'closed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: !isClosed,
            onChanged: (isOpen) {
              if (isOpen) {
                controller.setDayHours(day, '09:00-22:00');
              } else {
                controller.setDayHours(day, 'closed');
              }
            },
          ),
          const SizedBox(width: 16),
          if (!isClosed) ...[
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      day,
                      'open',
                      currentHours.split('-')[0],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: _buildTimeField(
                      day,
                      'close',
                      currentHours.split('-')[1],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Closed',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeField(String day, String type, String currentTime) {
    return InkWell(
      onTap: () => _selectTime(day, type, currentTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          currentTime,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _selectTime(String day, String type, String currentTime) async {
    final timeParts = currentTime.split(':');
    final currentTimeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: Get.context!,
      initialTime: currentTimeOfDay,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final timeString =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      final currentHours = controller.openingHours[day] ?? '09:00-22:00';
      final timeParts = currentHours.split('-');

      final newTime = type == 'open'
          ? '$timeString-${timeParts.length > 1 ? timeParts[1] : '22:00'}'
          : '${timeParts[0]}-$timeString';

      controller.setDayHours(day, newTime);
    }
  }
}

class RestaurantCategories {
  static const List<String> categories = [
    'Fast Food',
    'Fine Dining',
    'Casual Dining',
    'Cafe',
    'Bakery',
    'Pizza',
    'Asian Cuisine',
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Japanese',
    'Thai',
    'Mediterranean',
    'American',
    'Seafood',
    'Steakhouse',
    'Vegetarian/Vegan',
    'Breakfast & Brunch',
    'Desserts',
    'Ice Cream',
    'Juice Bar',
    'Food Truck',
    'Catering',
    'Other',
  ];

  static List<DropdownMenuItem<String>> get dropdownItems {
    return categories.map((category) {
      return DropdownMenuItem<String>(value: category, child: Text(category));
    }).toList();
  }
}
