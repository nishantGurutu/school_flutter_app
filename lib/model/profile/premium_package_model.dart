import 'package:flutter/material.dart';

class PremiumPackage {
  final String title;
  final String subtitle;
  final String price;
  final List<Color> gradientColors;
  final IconData icon;

  const PremiumPackage({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.gradientColors,
    this.icon = Icons.workspace_premium,
  });
}
