import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FieldSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final RxBool value;
  final Function(bool) onChanged;
  final IconData icon;
  final bool enabled;
  final Color? activeColor;

  const FieldSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.enabled = true,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 4),
        child: SwitchListTile(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          secondary: Icon(icon, color: activeColor ?? Colors.purple, size: 24),
          value: value.value,
          onChanged: enabled ? onChanged : null,
          activeColor: activeColor ?? Colors.purple,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}

// Alternative compact switch widget
class FieldSwitchCompact extends StatelessWidget {
  final String label;
  final RxBool value;
  final Function(bool) onChanged;
  final IconData? icon;
  final bool enabled;
  final Color? activeColor;

  const FieldSwitchCompact({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.enabled = true,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: activeColor ?? Colors.purple, size: 20),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Switch(
              value: value.value,
              onChanged: enabled ? onChanged : null,
              activeColor: activeColor ?? Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
