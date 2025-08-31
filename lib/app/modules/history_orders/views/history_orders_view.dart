import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/history_orders_controller.dart';

class HistoryOrdersView extends GetView<HistoryOrdersController> {
  const HistoryOrdersView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HistoryOrdersView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'HistoryOrdersView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
