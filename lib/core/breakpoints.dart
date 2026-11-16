import 'package:flutter/widgets.dart';

enum ScreenSize { mobile, tablet, desktop }

class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double desktop = 1024;

  static ScreenSize fromWidth(double width) {
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static ScreenSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  /// Horizontal page padding for the current width.
  static double pagePadding(BuildContext context) =>
      of(context) == ScreenSize.mobile ? 16 : 32;

  /// Width of a single news card in the horizontal/home carousel.
  static double cardWidth(BuildContext context) {
    final size = of(context);
    return switch (size) {
      ScreenSize.mobile => 200.0,
      ScreenSize.tablet => 250.0,
      ScreenSize.desktop => 290.0,
    };
  }

  /// Max cross-axis extent for article grids (auto-scales columns per width).
  static double gridExtent(BuildContext context) {
    final size = of(context);
    return switch (size) {
      ScreenSize.mobile => 300.0,
      ScreenSize.tablet => 360.0,
      ScreenSize.desktop => 380.0,
    };
  }

  /// Height of the horizontal home carousel.
  static double carouselHeight(BuildContext context) {
    final size = of(context);
    return switch (size) {
      ScreenSize.mobile => 160.0,
      _ => 200.0,
    };
  }
}
