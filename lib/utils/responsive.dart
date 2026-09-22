import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight, dependency-free responsive utility.
///
/// Set your base design size (commonly 375x812 from iPhone X-like mockups)
/// and then scale widths, heights and font sizes consistently everywhere.
class Responsive {
  static const double baseWidth = 375;
  static const double baseHeight = 812;

  final Size screenSize;
  final double widthScale;
  final double heightScale;

  Responsive._(this.screenSize, this.widthScale, this.heightScale);

  factory Responsive.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    return Responsive._(size, w / baseWidth, h / baseHeight);
  }

  /// Scale value that works well for fonts. Uses a conservative factor
  /// to avoid text becoming too large on short-but-wide screens.
  double get fontScale => math.min(widthScale, heightScale * 1.1);

  /// Scale a width value that was specified for the baseWidth.
  double rw(double value) => value * widthScale;

  /// Scale a height value that was specified for the baseHeight.
  double rh(double value) => value * heightScale;

  /// Scale a font size.
  double rf(double fontSize) => fontSize * fontScale;

  /// Percentage helpers.
  double sw(double fraction) => screenSize.width * fraction; // 0..1
  double sh(double fraction) => screenSize.height * fraction; // 0..1
}

extension ResponsiveContext on BuildContext {
  /// Get the [Responsive] instance for this context.
  Responsive get rsp => Responsive.of(this);

  /// Screen width/height fractions: context.sw(0.5) => 50% width
  double sw(double fraction) => rsp.sw(fraction);
  double sh(double fraction) => rsp.sh(fraction);

  /// Responsive width/height from design pixels.
  double rw(double value) => rsp.rw(value);
  double rh(double value) => rsp.rh(value);

  /// Responsive font size.
  double rf(double value) => rsp.rf(value);

  /// Common responsive paddings.
  EdgeInsets pad(double all) => EdgeInsets.all(rw(all));
  EdgeInsets pxy(double horizontal, double vertical) =>
      EdgeInsets.symmetric(horizontal: rw(horizontal), vertical: rh(vertical));
  EdgeInsets ph(double horizontal) => EdgeInsets.symmetric(horizontal: rw(horizontal));
  EdgeInsets pv(double vertical) => EdgeInsets.symmetric(vertical: rh(vertical));
}

/// A SizedBox that scales width/height values from your base design.
class ResponsiveGap extends StatelessWidget {
  final double? width;
  final double? height;
  const ResponsiveGap({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width != null ? context.rw(width!) : null,
      height: height != null ? context.rh(height!) : null,
    );
  }
}

/// A convenience wrapper to size a child by percentages of the screen.
class ResponsiveBox extends StatelessWidget {
  final double? widthPercent; // 0..1
  final double? heightPercent; // 0..1
  final AlignmentGeometry alignment;
  final Widget child;

  const ResponsiveBox({
    super.key,
    this.widthPercent,
    this.heightPercent,
    this.alignment = Alignment.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = widthPercent != null ? context.sw(widthPercent!) : null;
    final height = heightPercent != null ? context.sh(heightPercent!) : null;
    return SizedBox(
      width: width,
      height: height,
      child: Align(alignment: alignment, child: child),
    );
  }
}

