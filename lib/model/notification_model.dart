import 'package:flutter/material.dart';

class NotificationModel {
  final String name;
  final String action;
  final String body;
  final String timeLabel;
  final String imageUrl;
  final bool isVerified;

  const NotificationModel({
    required this.name,
    required this.action,
    required this.body,
    required this.timeLabel,
    required this.imageUrl,
    this.isVerified = false,
  });
}

class AlertModel {
  final String title;
  final String body;
  final List<Color> gradientColors;
  final IconData icon;

  const AlertModel({
    required this.title,
    required this.body,
    required this.gradientColors,
    required this.icon,
  });
}
