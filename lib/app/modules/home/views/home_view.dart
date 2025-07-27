import 'package:firebase_auth_get_x/app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final AuthController authC = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeView'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authC.logout();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('HomeView is working ', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
