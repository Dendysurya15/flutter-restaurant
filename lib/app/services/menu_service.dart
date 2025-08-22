import 'package:get/get.dart';
import 'package:restaurant/app/data/models/menu_category_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MenuCategoryModel>> getCategories(String storeId) async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .select()
          .eq('store_id', storeId)
          .eq('is_active', true)
          .order('sort_order');

      return (response as List)
          .map((json) => MenuCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<MenuItemModel>> getMenuItems(String storeId) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('store_id', storeId)
          .order('sort_order');

      return (response as List)
          .map((json) => MenuItemModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load menu items: $e');
    }
  }

  Future<MenuCategoryModel> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .insert(data)
          .select()
          .single();

      return MenuCategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<MenuItemModel> createMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .insert(data)
          .select()
          .single();

      return MenuItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
  }

  Future<MenuCategoryModel> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .update(data)
          .eq('id', categoryId)
          .select()
          .single();

      return MenuCategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<MenuItemModel> updateMenuItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .update(data)
          .eq('id', itemId)
          .select()
          .single();

      return MenuItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('menu_categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _supabase.from('menu_items').delete().eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  Future<void> toggleMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    try {
      await _supabase
          .from('menu_items')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to toggle menu item availability: $e');
    }
  }
}
