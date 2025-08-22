import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/category_form_controller.dart';

class CategoryFormView extends GetView<CategoryFormController> {
  const CategoryFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Category'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.saveCategory,
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
        child: Padding(
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
                        'Category Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),

                      // Category Name
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name *',
                          hintText: 'e.g., Appetizers, Main Course',
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
                          hintText: 'Brief description of this category',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
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

                      // Active Status
                      Obx(
                        () => SwitchListTile(
                          title: Text('Active'),
                          subtitle: Text(
                            controller.isActive.value
                                ? 'This category is active and visible'
                                : 'This category is inactive and hidden',
                          ),
                          value: controller.isActive.value,
                          onChanged: (value) =>
                              controller.isActive.value = value,
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
                      : controller.saveCategory,
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
                      : Text('Save Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
