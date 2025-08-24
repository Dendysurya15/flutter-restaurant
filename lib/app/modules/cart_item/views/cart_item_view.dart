import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/cart_item_controller.dart';

class CartItemView extends GetView<CartItemController> {
  const CartItemView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CartItemView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'CartItemView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
