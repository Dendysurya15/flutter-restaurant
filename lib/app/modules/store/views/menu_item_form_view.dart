import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/menu_item_form_controller.dart';

class MenuItemFormView extends GetView<MenuItemFormController> {
  const MenuItemFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Menu Item'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.saveMenuItem,
              child: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Item Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),

                      // Item Name
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g., Caesar Salad, Grilled Chicken',
                          border: OutlineInputBorder(),
                        ),
                        validator: controller.validateName,
                        textCapitalization: TextCapitalization.words,
                      ),

                      SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: controller.descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe ingredients and preparation',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: controller.priceController,
                        decoration: InputDecoration(
                          labelText: 'Price *',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: controller.validatePrice,
                      ),

                      SizedBox(height: 16),

                      // Preparation Time
                      TextFormField(
                        controller: controller.preparationTimeController,
                        decoration: InputDecoration(
                          labelText: 'Preparation Time (minutes)',
                          hintText: '15',
                          border: OutlineInputBorder(),
                          suffixText: 'min',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: controller.validatePreparationTime,
                      ),

                      SizedBox(height: 16),

                      // Category Dropdown
                      Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.selectedCategoryId.value.isEmpty
                              ? null
                              : controller.selectedCategoryId.value,
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                          ),
                          items: controller.categories
                              .where((category) => category.isActive)
                              .map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              })
                              .toList(),
                          onChanged: controller.onCategoryChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 16),

                      // Sort Order
                      TextFormField(
                        controller: controller.sortOrderController,
                        decoration: InputDecoration(
                          labelText: 'Sort Order',
                          hintText: '0',
                          border: OutlineInputBorder(),
                          helperText: 'Lower numbers appear first',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: controller.validateSortOrder,
                      ),

                      SizedBox(height: 16),

                      // Switches
                      Obx(
                        () => SwitchListTile(
                          title: Text('Available'),
                          subtitle: Text(
                            controller.isAvailable.value
                                ? 'This item is available for ordering'
                                : 'This item is currently unavailable',
                          ),
                          value: controller.isAvailable.value,
                          onChanged: (value) =>
                              controller.isAvailable.value = value,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      Obx(
                        () => SwitchListTile(
                          title: Row(
                            children: [
                              Text('Vegetarian'),
                              SizedBox(width: 8),
                              Icon(Icons.eco, size: 16, color: Colors.green),
                            ],
                          ),
                          subtitle: Text(
                            'This item is suitable for vegetarians',
                          ),
                          value: controller.isVegetarian.value,
                          onChanged: (value) =>
                              controller.isVegetarian.value = value,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      Obx(
                        () => SwitchListTile(
                          title: Row(
                            children: [
                              Text('Spicy'),
                              SizedBox(width: 8),
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.red,
                              ),
                            ],
                          ),
                          subtitle: Text('This item is spicy'),
                          value: controller.isSpicy.value,
                          onChanged: (value) =>
                              controller.isSpicy.value = value,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.saveMenuItem,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isLoading.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : Text('Save Menu Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
