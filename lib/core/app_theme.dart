import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF0F172A);
  static const blue = Color(0xFF1E40AF);
  static const blueSoft = Color(0xFFDBEAFE);

  static const slate = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const canvas = Color(0xFFF8FAFC);

  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const greenCanvas = Color(0xFFF0FDF4);

  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);

  static const red = Color(0xFFFF5A64);
  static const redSoft = Color(0xFFFFEBEC);

  static const adminNavy = Color(0xFF10192D);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),

    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      titleSmall: TextStyle(
        color: AppColors.navy,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: AppColors.slate, fontSize: 13),
      bodySmall: TextStyle(color: AppColors.slate, fontSize: 11),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.blueSoft,
      surfaceTintColor: Colors.transparent,
      height: 66,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: AppColors.navy,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
