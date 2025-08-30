import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ModalAlertType { success, error, warning, info, confirmation, custom }

class ModalAlert extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? content;
  final ModalAlertType type;
  final IconData? customIcon;
  final Color? customColor;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool isDismissible;
  final bool isProcessing;
  final double? maxHeight;

  const ModalAlert({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.type = ModalAlertType.info,
    this.customIcon,
    this.customColor,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.onClose,
    this.showCloseButton = true,
    this.isDismissible = true,
    this.isProcessing = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight ?? Get.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Key change: Use minimum space
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: onClose ?? () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
          ),

          // Content - No Expanded, just wrap content
          if (content != null)
            Container(
              constraints: BoxConstraints(
                maxHeight:
                    (maxHeight ?? Get.height * 0.9) -
                    200, // Reserve space for header and buttons
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: content!,
              ),
            ),

          // Bottom Actions
          if (primaryButtonText != null || secondaryButtonText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (secondaryButtonText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : (onSecondaryPressed ?? () => Get.back()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: config.color),
                        ),
                        child: Text(
                          secondaryButtonText!,
                          style: TextStyle(color: config.color),
                        ),
                      ),
                    ),
                    if (primaryButtonText != null) const SizedBox(width: 16),
                  ],
                  if (primaryButtonText != null)
                    Expanded(
                      flex: secondaryButtonText != null ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : onPrimaryPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isProcessing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Processing...'),
                                ],
                              )
                            : Text(
                                primaryButtonText!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  ModalConfig _getTypeConfig() {
    switch (type) {
      case ModalAlertType.success:
        return ModalConfig(
          icon: Icons.check_circle,
          color: Colors.green.shade600,
        );
      case ModalAlertType.error:
        return ModalConfig(icon: Icons.error, color: Colors.red.shade600);
      case ModalAlertType.warning:
        return ModalConfig(icon: Icons.warning, color: Colors.orange.shade600);
      case ModalAlertType.info:
        return ModalConfig(icon: Icons.info, color: Colors.blue.shade600);
      case ModalAlertType.confirmation:
        return ModalConfig(
          icon: Icons.help_outline,
          color: Colors.purple.shade600,
        );
      case ModalAlertType.custom:
        return ModalConfig(
          icon: customIcon ?? Icons.circle,
          color: customColor ?? Colors.grey.shade600,
        );
    }
  }

  // Static methods for easy usage
  static void showSuccess({
    required String title,
    String? subtitle,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onClose,
    double? maxHeight,
  }) {
    show(
      title: title,
      subtitle: subtitle,
      content: content,
      type: ModalAlertType.success,
      primaryButtonText: primaryButtonText ?? 'OK',
      onPrimaryPressed: onPrimaryPressed ?? () => Get.back(),
      onClose: onClose,
      maxHeight: maxHeight,
    );
  }

  static void showError({
    required String title,
    String? subtitle,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onClose,
    double? maxHeight,
  }) {
    show(
      title: title,
      subtitle: subtitle,
      content: content,
      type: ModalAlertType.error,
      primaryButtonText: primaryButtonText ?? 'OK',
      onPrimaryPressed: onPrimaryPressed ?? () => Get.back(),
      onClose: onClose,
      maxHeight: maxHeight,
    );
  }

  static void showWarning({
    required String title,
    String? subtitle,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onClose,
    double? maxHeight,
  }) {
    show(
      title: title,
      subtitle: subtitle,
      content: content,
      type: ModalAlertType.warning,
      primaryButtonText: primaryButtonText ?? 'OK',
      onPrimaryPressed: onPrimaryPressed ?? () => Get.back(),
      onClose: onClose,
      maxHeight: maxHeight,
    );
  }

  static void showConfirmation({
    required String title,
    String? subtitle,
    Widget? content,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isProcessing = false,
    double? maxHeight,
  }) {
    show(
      title: title,
      subtitle: subtitle,
      content: content,
      type: ModalAlertType.confirmation,
      primaryButtonText: primaryButtonText ?? 'Confirm',
      secondaryButtonText: secondaryButtonText ?? 'Cancel',
      onPrimaryPressed: onConfirm,
      onSecondaryPressed: onCancel ?? () => Get.back(),
      isProcessing: isProcessing,
      isDismissible: !isProcessing,
      maxHeight: maxHeight,
    );
  }

  static void show({
    required String title,
    String? subtitle,
    Widget? content,
    ModalAlertType type = ModalAlertType.info,
    IconData? customIcon,
    Color? customColor,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    VoidCallback? onClose,
    bool showCloseButton = true,
    bool isDismissible = true,
    bool isProcessing = false,
    double? maxHeight,
  }) {
    Get.bottomSheet(
      ModalAlert(
        title: title,
        subtitle: subtitle,
        content: content,
        type: type,
        customIcon: customIcon,
        customColor: customColor,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        onClose: onClose,
        showCloseButton: showCloseButton,
        isDismissible: isDismissible,
        isProcessing: isProcessing,
        maxHeight: maxHeight,
      ),
      isScrollControlled:
          true, // Important: Enable scroll control for dynamic sizing
      isDismissible: isDismissible,
      enableDrag: isDismissible,
    );
  }
}

class ModalConfig {
  final IconData icon;
  final Color color;

  ModalConfig({required this.icon, required this.color});
}
