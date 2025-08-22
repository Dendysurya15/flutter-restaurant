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
                      hint: '0.00',
                      icon: Icons.money,
                      prefixText: '\$ ',
                      min: 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FieldNumber(
                      controller: controller.minimumOrderController,
                      label: 'Minimum Order',
                      hint: '0.00',
                      icon: Icons.shopping_cart,
                      prefixText: '\$ ',
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
                    // Only the button needs to be reactive for loading state
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
}

// Add this to your categories file or create it
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
