import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/controllers/auth_controller.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/widgets/notification/custom_toast.dart';

class StoreController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();

  // Observable variables
  var isLoading = false.obs;
  var hasStore = false.obs;
  var currentStore = Rxn<StoreModel>();

  // Form controllers
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final deliveryFeeController = TextEditingController();
  final minimumOrderController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Store settings
  var deliveryAvailable = true.obs;
  var dineInAvailable = true.obs;
  var isActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkExistingStore();
  }

  @override
  void onClose() {
    nameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    phoneController.dispose();
    deliveryFeeController.dispose();
    minimumOrderController.dispose();
    super.onClose();
  }

  // Check if owner already has a store
  Future<void> checkExistingStore() async {
    try {
      isLoading.value = true;

      // Get current user from AuthController
      final currentUser = authController.currentUserData.value;
      if (currentUser == null || currentUser.id.isEmpty) {
        CustomToast.error(
          title: 'Error',
          message: 'No authenticated user found',
        );
        return;
      }

      final response = await supabase
          .from('stores')
          .select()
          .eq('owner_id', currentUser.id) // Now guaranteed non-null
          .maybeSingle();

      if (response != null) {
        currentStore.value = StoreModel.fromJson(response);
        hasStore.value = true;
        _populateForm();
      } else {
        hasStore.value = false;
        currentStore.value = null;
      }
    } catch (e) {
      CustomToast.error(title: 'Error', message: 'Failed to check store: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Populate form with existing store data
  void _populateForm() {
    if (currentStore.value != null) {
      final store = currentStore.value!;
      nameController.text = store.name;
      categoryController.text = store.category;
      descriptionController.text = store.description ?? '';
      addressController.text = store.address ?? '';
      phoneController.text = store.phone ?? '';
      deliveryFeeController.text = store.deliveryFee.toString();
      minimumOrderController.text = store.minimumOrder.toString();
      deliveryAvailable.value = store.deliveryAvailable;
      dineInAvailable.value = store.dineInAvailable;
      isActive.value = store.isActive;
    }
  }

  // Create new store
  Future<void> createStore() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Get current user from AuthController
      final currentUser = authController.currentUserData.value;
      if (currentUser == null || currentUser.id.isEmpty) {
        CustomToast.error(
          title: 'Error',
          message: 'No authenticated user found',
        );
        return;
      }

      final storeData = {
        'owner_id': currentUser
            .id, // Fixed: use currentUser.id instead of authController.user.value?.id
        'name': nameController.text.trim(),
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'address': addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'delivery_available': deliveryAvailable.value,
        'dine_in_available': dineInAvailable.value,
        'delivery_fee': double.tryParse(deliveryFeeController.text) ?? 0.0,
        'minimum_order': double.tryParse(minimumOrderController.text) ?? 0.0,
        'is_active': isActive.value,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('stores')
          .insert(storeData)
          .select()
          .single();

      currentStore.value = StoreModel.fromJson(response);
      hasStore.value = true;

      CustomToast.success(
        title: 'Success',
        message: 'Store created successfully!',
      );
    } catch (e) {
      CustomToast.error(title: 'Error', message: 'Failed to create store: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing store
  Future<void> updateStore() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final storeData = {
        'name': nameController.text.trim(),
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'address': addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'delivery_available': deliveryAvailable.value,
        'dine_in_available': dineInAvailable.value,
        'delivery_fee': double.tryParse(deliveryFeeController.text) ?? 0.0,
        'minimum_order': double.tryParse(minimumOrderController.text) ?? 0.0,
        'is_active': isActive.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('stores')
          .update(storeData)
          .eq('id', currentStore.value!.id)
          .select()
          .single();

      currentStore.value = StoreModel.fromJson(response);

      CustomToast.success(
        title: 'Success',
        message: 'Store updated successfully!',
      );
    } catch (e) {
      CustomToast.error(title: 'Error', message: 'Failed to update store: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete store
  Future<void> deleteStore() async {
    try {
      // Show confirmation dialog
      bool confirmed =
          await Get.dialog<bool>(
            AlertDialog(
              title: Text('Delete Store'),
              content: Text(
                'Are you sure you want to delete your store? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      isLoading.value = true;

      await supabase.from('stores').delete().eq('id', currentStore.value!.id);

      currentStore.value = null;
      hasStore.value = false;
      _clearForm();

      CustomToast.success(
        title: 'Success',
        message: 'Store deleted successfully!',
      );
    } catch (e) {
      CustomToast.error(title: 'Error', message: 'Failed to delete store: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form
  void _clearForm() {
    nameController.clear();
    categoryController.clear();
    descriptionController.clear();
    addressController.clear();
    phoneController.clear();
    deliveryFeeController.clear();
    minimumOrderController.clear();
    deliveryAvailable.value = true;
    dineInAvailable.value = true;
    isActive.value = true;
  }

  // Toggle store active status
  Future<void> toggleStoreStatus() async {
    try {
      isLoading.value = true;

      final newStatus = !currentStore.value!.isActive;

      final response = await supabase
          .from('stores')
          .update({
            'is_active': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentStore.value!.id)
          .select()
          .single();

      currentStore.value = StoreModel.fromJson(response);
      isActive.value = newStatus;

      CustomToast.success(title: 'Success', message: 'Store status updated!');
    } catch (e) {
      CustomToast.error(
        title: 'Error',
        message: 'Failed to update store status: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
