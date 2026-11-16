import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B2150);
  static const line = Color(0xFFD9D9E0);
  static const field = Color(0xFFF9F9F9);
  static const badge = Color(0xFF2B4C9B);
  static const avatar = Color(0xFFF0486B);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.ink).copyWith(
    primary: AppColors.ink,
    onSurface: AppColors.ink,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    dividerColor: AppColors.line,
    textTheme: Typography.blackMountainView.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
