import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  final emailC = TextEditingController(text: 'test@gmail.com');
  final passwordC = TextEditingController(text: "testing");

  // Role selection - default to customer
  final selectedRole = 'customer'.obs;

  final count = 0.obs;

  void increment() => count.value++;

  // Method to change role
  void setRole(String role) {
    selectedRole.value = role;
  }

  @override
  void onClose() {
    emailC.dispose();
    passwordC.dispose();
    super.onClose();
  }
}
