import 'package:flutter/material.dart';

class FieldDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(T?)? validator;
  final Function(T?) onChanged;
  final bool enabled;

  const FieldDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple, width: 2),
        ),
        enabled: enabled,
      ),
      validator: validator,
      isExpanded: true,
    );
  }
}

// Helper class for dropdown options
class DropdownOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DropdownOption({required this.value, required this.label, this.icon});

  DropdownMenuItem<T> toDropdownMenuItem() {
    return DropdownMenuItem<T>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16), SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
  }
}

// Predefined category options for restaurants
class RestaurantCategories {
  static const List<DropdownOption<String>> options = [
    DropdownOption(
      value: 'fast_food',
      label: 'Fast Food',
      icon: Icons.fastfood,
    ),
    DropdownOption(
      value: 'fine_dining',
      label: 'Fine Dining',
      icon: Icons.restaurant_menu,
    ),
    DropdownOption(value: 'cafe', label: 'Cafe', icon: Icons.local_cafe),
    DropdownOption(value: 'bakery', label: 'Bakery', icon: Icons.cake),
    DropdownOption(value: 'pizza', label: 'Pizza', icon: Icons.local_pizza),
    DropdownOption(
      value: 'asian',
      label: 'Asian Cuisine',
      icon: Icons.ramen_dining,
    ),
    DropdownOption(
      value: 'mexican',
      label: 'Mexican',
      icon: Icons.lunch_dining,
    ),
    DropdownOption(value: 'italian', label: 'Italian', icon: Icons.restaurant),
    DropdownOption(
      value: 'burger',
      label: 'Burger Joint',
      icon: Icons.lunch_dining,
    ),
    DropdownOption(
      value: 'dessert',
      label: 'Dessert Shop',
      icon: Icons.icecream,
    ),
    DropdownOption(value: 'seafood', label: 'Seafood', icon: Icons.set_meal),
    DropdownOption(value: 'vegetarian', label: 'Vegetarian', icon: Icons.eco),
    DropdownOption(value: 'other', label: 'Other', icon: Icons.more_horiz),
  ];

  static List<DropdownMenuItem<String>> get dropdownItems {
    return options.map((option) => option.toDropdownMenuItem()).toList();
  }
}
