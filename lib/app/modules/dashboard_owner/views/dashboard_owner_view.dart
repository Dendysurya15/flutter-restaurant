// dashboard_owner_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
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
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                toastification.show(
                  alignment: Alignment.topCenter,
                  context: context, // optional if you use ToastificationWrapper
                  title: Text('Hello, world!'),
                  autoCloseDuration: const Duration(seconds: 4),
                  showIcon: true,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  icon: Icon(Icons.check_circle, color: Colors.white),
                  showProgressBar: true,
                  animationDuration: const Duration(milliseconds: 300),
                  animationBuilder: (context, animation, alignment, child) {
                    return FadeTransition(child: child, opacity: animation);
                  },
                );
              },
              child: const Text('Perform Action'),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: OwnerBottomNav(), // Sticky navigation
    );
  }
}
