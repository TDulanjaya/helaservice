import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String label;
  final String iconKey;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  IconData get icon => _iconFor(iconKey);

  static IconData _iconFor(String key) {
    switch (key) {
      case 'ac_unit':
        return Icons.ac_unit;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'plumbing':
        return Icons.plumbing;
      case 'car_repair':
        return Icons.car_repair;
      case 'carpenter':
        return Icons.carpenter;
      case 'cleaning_services':
        return Icons.cleaning_services;
      default:
        return Icons.build;
    }
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'iconKey': iconKey,
      };

  factory CategoryItem.fromMap(String id, Map<String, dynamic> map) {
    return CategoryItem(
      id: id,
      label: map['label'] ?? '',
      iconKey: map['iconKey'] ?? '',
    );
  }
}
