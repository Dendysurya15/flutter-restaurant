import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/widgets/form/field_text.dart';
import 'package:restaurant/app/widgets/form/field_number.dart';
import 'package:restaurant/app/widgets/form/field_dropdown.dart';
import 'package:restaurant/app/widgets/form/field_switch.dart';
import 'package:restaurant/app/widgets/form/section_title.dart';
import 'package:restaurant/app/widgets/form/custom_button.dart';
import '../controllers/store_controller.dart';

class StoreView extends GetView<StoreController> {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Status Card
                if (controller.hasStore.value &&
                    controller.currentStore.value != null)
                  _buildStoreStatusCard(),

                SizedBox(height: 16),

                // Basic Information
                SectionTitle(title: 'Basic Information', icon: Icons.info),
                SizedBox(height: 16),

                FieldText(
                  controller: controller.nameController,
                  label: 'Store Name',
                  hint: 'Enter your store name',
                  icon: Icons.store,
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 16),

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
                      value?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 16),

                FieldText(
                  controller: controller.descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Describe your store',
                  icon: Icons.description,
                  maxLines: 3,
                ),

                SizedBox(height: 24),

                // Contact Information
                SectionTitle(
                  title: 'Contact Information',
                  icon: Icons.contact_phone,
                ),
                SizedBox(height: 16),

                FieldText(
                  controller: controller.addressController,
                  label: 'Address (Optional)',
                  hint: 'Enter address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                SizedBox(height: 16),

                FieldText(
                  controller: controller.phoneController,
                  label: 'Phone (Optional)',
                  hint: 'Enter phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 24),

                // Service Settings
                SectionTitle(title: 'Service Settings', icon: Icons.settings),
                SizedBox(height: 16),

                FieldSwitch(
                  title: 'Delivery Available',
                  subtitle: 'Enable delivery service',
                  value: controller.deliveryAvailable,
                  onChanged: (value) =>
                      controller.deliveryAvailable.value = value,
                  icon: Icons.delivery_dining,
                ),

                FieldSwitch(
                  title: 'Dine-In Available',
                  subtitle: 'Allow dine-in',
                  value: controller.dineInAvailable,
                  onChanged: (value) =>
                      controller.dineInAvailable.value = value,
                  icon: Icons.restaurant,
                ),

                SizedBox(height: 24),

                // Pricing
                SectionTitle(title: 'Pricing', icon: Icons.attach_money),
                SizedBox(height: 16),

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
                    SizedBox(width: 16),
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

                SizedBox(height: 32),

                // Action Button
                Obx(
                  () => PrimaryButton(
                    text: controller.hasStore.value
                        ? 'Update Store'
                        : 'Create Store',
                    icon: controller.hasStore.value
                        ? Icons.update
                        : Icons.add_business,
                    onPressed: controller.hasStore.value
                        ? controller.updateStore
                        : controller.createStore,
                    isLoading: controller.isLoading.value,
                    width: double.infinity,
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
      // bottomNavigationBar: OwnerBottomNav(), // Sticky navigation
    );
  }

  Widget _buildStoreStatusCard() {
    final store = controller.currentStore.value!;
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              store.isActive ? Icons.check_circle : Icons.cancel,
              color: store.isActive ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'Store Status: ${store.isActive ? 'Active' : 'Inactive'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: store.isActive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
