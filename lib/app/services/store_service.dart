import 'package:get/get.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  static final supabase = Supabase.instance.client;

  static Future<List<StoreModel>> getUserStores() async {
    // Get current user from AuthController
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.id;

    if (userId == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('stores')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((store) => StoreModel.fromJson(store))
        .toList();
  }

  static Future<StoreModel> createStore(Map<String, dynamic> storeData) async {
    // Get current user from AuthController
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.id;

    if (userId == null) throw Exception('User not authenticated');

    // Add owner_id to store data
    storeData['owner_id'] = userId;

    final response = await supabase
        .from('stores')
        .insert(storeData)
        .select()
        .single();

    return StoreModel.fromJson(response);
  }

  static Future<StoreModel> updateStore(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    // Add updated_at timestamp
    storeData['updated_at'] = DateTime.now().toIso8601String();

    final response = await supabase
        .from('stores')
        .update(storeData)
        .eq('id', storeId)
        .select()
        .single();

    return StoreModel.fromJson(response);
  }

  static Future<void> updateStoreStatus(String storeId, bool isActive) async {
    await supabase
        .from('stores')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', storeId);
  }

  static Future<void> deleteStore(String storeId) async {
    await supabase.from('stores').delete().eq('id', storeId);
  }
}
