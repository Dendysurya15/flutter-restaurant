import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomToast {
  static void success({required String title, required String message}) {
    _showToast(title: title, message: message, color: Colors.green);
  }

  static void error({required String title, required String message}) {
    _showToast(title: title, message: message, color: Colors.red);
  }

  static void info({required String title, required String message}) {
    _showToast(title: title, message: message, color: Colors.blue);
  }

  static void _showToast({
    required String title,
    required String message,
    required Color color,
  }) {
    Get.dialog(
      _ToastWidget(title: title, message: message, color: color),
      barrierColor: Colors.transparent,
      barrierDismissible: true,
    );

    Future.delayed(Duration(seconds: 3), () {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    });
  }
}

class _ToastWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const _ToastWidget({
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message,
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
