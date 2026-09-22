import 'package:flutter/material.dart';

class AppColors {
  // Existing palette (kept for backward compatibility)
  static const Color gradientStart = Color(0xFFdc72f2);
  static const Color primaryColor = Color(0xFFa36be2);
  static const Color unselectedButtonColor = Color(0xFFf7ecff);
  static const Color lightBackground = Colors.white;
  static const Color lightText = Color(0xFF2D2D2D);
  static const Color lightCard = Color(0xFFF7F7F7);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color darkBackground = Color(0xFF121212);
  static const Color backgroundColor = Color(0xFFf5f6f9);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;
  static const Color warning = Colors.orangeAccent;

  static LinearGradient get appGradient => const LinearGradient(
    colors: [gradientStart, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Home (screenshot) palette
  static const Color homeBackground = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF121225);
  static const Color surface2 = Color(0xFF17172D);
  static const Color border = Color(0xFF242445);

  static const Color accentPurple = Color(0xFFB46BFF);
  static const Color accentPurple2 = Color(0xFF8B5CFF);

  static const Color textPrimary = Color(0xFFF1F1F7);
  static const Color textSecondary = Color(0xFFB9B9C8);
  static const Color textMuted = Color(0xFF8A8AA3);

  static const Color navSurface = Color(0xFF0F0F1D);
  static const Color navBorder = Color(0xFF1F1F39);
  static const Color navIconMuted = Color(0xFF9A9AB2);

  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [accentPurple, accentPurple2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
