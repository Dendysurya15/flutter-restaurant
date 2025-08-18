import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets? padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? Colors.purple, size: fontSize + 2),
            SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: color ?? Colors.purple,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative divider-style section title
class SectionTitleDivider extends StatelessWidget {
  final String title;
  final Color? color;
  final double thickness;

  const SectionTitleDivider({
    super.key,
    required this.title,
    this.color,
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: color ?? Colors.purple, thickness: thickness),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.purple,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: color ?? Colors.purple, thickness: thickness),
        ),
      ],
    );
  }
}
