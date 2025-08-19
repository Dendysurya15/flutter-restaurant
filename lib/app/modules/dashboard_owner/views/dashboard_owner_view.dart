// dashboard_owner_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:restaurant/app/widgets/bottom_navigation/owner_bottom_nav.dart';
import '../controllers/dashboard_owner_controller.dart';

class DashboardOwnerView extends GetView<DashboardOwnerController> {
  const DashboardOwnerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: Colors.purple[400]),
            SizedBox(height: 16),
            Text(
              'Owner Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your dashboard content here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: OwnerBottomNav(), // Sticky navigation
    );
  }
}
