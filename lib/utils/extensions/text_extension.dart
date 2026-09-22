import 'package:flutter/material.dart';
import 'package:school_desk_app/utils/extensions/general_ectensions.dart';

extension ResponsiveText on BuildContext {
  TextStyle _baseText({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double height = 1.3,
  }) {
    final textScale = MediaQuery.textScaleFactorOf(this);
    final screenWidth = mediaQueryWidth;

    final widthScale = (screenWidth / 375).clamp(0.9, 1.3);

    return TextStyle(
      fontSize: size * widthScale * textScale,
      fontWeight: weight,
      color: color ?? Colors.black,
      height: height,
    );
  }

  TextStyle get h1 => _baseText(size: 22, weight: FontWeight.w700);
  TextStyle get h2 => _baseText(size: 16, weight: FontWeight.w600);
  TextStyle get h3 => _baseText(size: 26, weight: FontWeight.w600);
  TextStyle get h4 => _baseText(size: 18, weight: FontWeight.w600);
  TextStyle get h5 => _baseText(size: 30, weight: FontWeight.w600);

  TextStyle get body => _baseText(size: 14);
  TextStyle get boldBody => _baseText(size: 14, weight: FontWeight.w600);
  TextStyle get bodySmall => _baseText(size: 12);

  TextStyle get buttonText =>
      _baseText(size: 14, weight: FontWeight.w600, color: Colors.white);

  TextStyle text({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double height = 1.3,
  }) {
    return _baseText(size: size, weight: weight, color: color, height: height);
  }
}
