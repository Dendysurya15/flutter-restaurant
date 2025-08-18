import 'package:restaurant/app/controllers/auth_controller.dart';
import 'package:restaurant/app/widgets/bottom_navigation/customer_bottom_nav.dart';
import 'package:restaurant/app/routes/app_pages.dart';
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
        title: Obx(() => Text('Welcome ${authC.userRole.value.toUpperCase()}')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authC.logout(),
          ),
        ],
      ),
      body: Obx(() {
        final role = authC.userRole.value;

        if (role == 'owner') {
          // Redirect to separate dashboard page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.DASHBOARD_OWNER);
          });

          return Center(child: CircularProgressIndicator());
        } else {
          // Customer content
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('HomeView is working', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text(
                  'Role: ${authC.userRole.value}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }
      }),
      bottomNavigationBar: Obx(() {
        final role = authC.userRole.value;
        return role == 'customer' ? CustomerBottomNav() : SizedBox.shrink();
      }),
    );
  }
}
