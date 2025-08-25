import 'package:flutter/material.dart';

class MenuItemModel {
  final String title;
  final IconData icon;
  final List<String>? subItems;

  MenuItemModel({
    required this.title,
    required this.icon,
    this.subItems,
  });
}
