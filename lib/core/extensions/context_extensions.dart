import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension ContextExtensions on BuildContext {
  // Screen measurements
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  double get topPadding => MediaQuery.paddingOf(this).top;

  // Modern Responsive Typography Scale
  TextStyle _customTextStyle({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double height = 1.25,
  }) {
    // Dynamic scale factor relative to standard base width (375px)
    final widthScale = (screenWidth / 375).clamp(0.85, 1.25);
    final textScale = MediaQuery.textScaleFactorOf(this);
    
    return TextStyle(
      fontSize: size * widthScale * textScale,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // Headings
  TextStyle get h1 => _customTextStyle(size: 24, weight: FontWeight.bold, height: 1.2);
  TextStyle get h2 => _customTextStyle(size: 18, weight: FontWeight.w700, height: 1.2);
  TextStyle get h3 => _customTextStyle(size: 16, weight: FontWeight.w600);
  TextStyle get body => _customTextStyle(size: 14, weight: FontWeight.normal);
  TextStyle get bodyBold => _customTextStyle(size: 14, weight: FontWeight.w600);
  TextStyle get caption => _customTextStyle(size: 12, weight: FontWeight.normal, color: AppColors.textSecondary);
  TextStyle get captionBold => _customTextStyle(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary);
  TextStyle get mutedText => _customTextStyle(size: 11, weight: FontWeight.normal, color: AppColors.textMuted);

  // Dynamic builder utility
  TextStyle customStyle({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double height = 1.25,
  }) {
    return _customTextStyle(size: size, weight: weight, color: color, height: height);
  }

  // SnackBar helper
  void showAppSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// SizedBox numerical extensions for clean Spacers
extension SpacerExtensions on num {
  SizedBox get height => SizedBox(height: toDouble());
  SizedBox get width => SizedBox(width: toDouble());
}
