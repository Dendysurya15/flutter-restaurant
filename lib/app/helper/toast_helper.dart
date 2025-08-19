// toast_helper.dart
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  static void showToast({
    required BuildContext context,
    required String title,
    required String description,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: _getIcon(type),
      borderRadius: BorderRadius.circular(12.0),
      pauseOnHover: false,
    );
  }

  /// Pick icon based on toast type
  static Icon _getIcon(ToastificationType type) {
    switch (type) {
      case ToastificationType.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 27);
      case ToastificationType.error:
        return const Icon(Icons.error, color: Colors.red, size: 27);
      case ToastificationType.warning:
        return const Icon(
          Icons.warning_rounded,
          color: Colors.orange,
          size: 27,
        );
      case ToastificationType.info:
        return const Icon(Icons.info, color: Colors.blue, size: 27);
      default:
        return const Icon(Icons.notifications, size: 27);
    }
  }
}
