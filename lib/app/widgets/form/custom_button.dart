import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final bool isLoading;
  final ButtonType type;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: type == ButtonType.flat ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  _ButtonColors _getColors() {
    switch (type) {
      case ButtonType.primary:
        return _ButtonColors(
          background: backgroundColor ?? Colors.purple,
          foreground: foregroundColor ?? Colors.white,
        );
      case ButtonType.secondary:
        return _ButtonColors(
          background: backgroundColor ?? Colors.grey[200]!,
          foreground: foregroundColor ?? Colors.black87,
        );
      case ButtonType.success:
        return _ButtonColors(
          background: backgroundColor ?? Colors.green,
          foreground: foregroundColor ?? Colors.white,
        );
      case ButtonType.warning:
        return _ButtonColors(
          background: backgroundColor ?? Colors.orange,
          foreground: foregroundColor ?? Colors.white,
        );
      case ButtonType.danger:
        return _ButtonColors(
          background: backgroundColor ?? Colors.red,
          foreground: foregroundColor ?? Colors.white,
        );
      case ButtonType.flat:
        return _ButtonColors(
          background: backgroundColor ?? Colors.transparent,
          foreground: foregroundColor ?? Colors.purple,
        );
    }
  }
}

// Button types enum
enum ButtonType { primary, secondary, success, warning, danger, flat }

// Helper class for button colors
class _ButtonColors {
  final Color background;
  final Color foreground;

  _ButtonColors({required this.background, required this.foreground});
}

// Predefined button variations
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      type: ButtonType.primary,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      type: ButtonType.secondary,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const DangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      type: ButtonType.danger,
    );
  }
}
