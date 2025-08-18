import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FieldNumber extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool allowDecimal;
  final String? prefixText;
  final String? suffixText;
  final double? min;
  final double? max;
  final bool enabled;
  final Function(String)? onChanged;

  const FieldNumber({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.allowDecimal = true,
    this.prefixText,
    this.suffixText,
    this.min,
    this.max,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        suffixText: suffixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple, width: 2),
        ),
        enabled: enabled,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator ?? _defaultValidator,
      onChanged: onChanged,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) return null;

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min!) {
      return 'Value must be at least $min';
    }

    if (max != null && number > max!) {
      return 'Value must not exceed $max';
    }

    return null;
  }
}
