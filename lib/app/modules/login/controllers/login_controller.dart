import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailC = TextEditingController(text: 'suryadendy18@gmail.com');
  final passwordC = TextEditingController(text: "testing");

  final count = 0.obs;

  void increment() => count.value++;
}
