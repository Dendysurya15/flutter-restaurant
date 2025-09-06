// app/bindings/cart_item_binding.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/cart_item/controllers/cart_item_controller.dart';

class CartItemBinding extends Bindings {
  @override
  void dependencies() {
    // Don't create new controller - use the permanent one
    // Just ensure it's initialized for cart page
    final controller = Get.find<CartItemController>();

    // Call this when navigating to cart page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeForCartPage();
    });
  }
}
