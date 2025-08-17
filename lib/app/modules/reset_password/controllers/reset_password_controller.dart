import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final emailC = TextEditingController(text: 'test@gmail.com');

  final count = 0.obs;

  void increment() => count.value++;
}
