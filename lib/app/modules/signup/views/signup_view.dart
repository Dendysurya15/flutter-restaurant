import 'package:restaurant/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    AuthService authC = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('SignupView'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: controller.emailC,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: controller.passwordC,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Role Selection
            const Text(
              'Select Role:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Obx(
              () => Column(
                children: [
                  // RadioListTile<String>(
                  //   title: const Text('Admin'),
                  //   subtitle: const Text('Manage users and settings'),
                  //   value: 'admin',
                  //   groupValue: controller.selectedRole.value,
                  //   onChanged: (value) {
                  //     controller.selectedRole.value = value!;
                  //   },
                  // ),
                  RadioListTile<String>(
                    title: const Text('Customer'),
                    subtitle: const Text('Browse and order food'),
                    value: 'customer',
                    groupValue: controller.selectedRole.value,
                    onChanged: (value) {
                      controller.selectedRole.value = value!;
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Owner'),
                    subtitle: const Text('Manage restaurant and orders'),
                    value: 'owner',
                    groupValue: controller.selectedRole.value,
                    onChanged: (value) {
                      controller.selectedRole.value = value!;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authC.signup(
                  controller.emailC.text,
                  controller.passwordC.text,
                  role: controller.selectedRole.value,
                );
              },
              child: const Text('Daftar'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Sudah punya akun?"),
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
