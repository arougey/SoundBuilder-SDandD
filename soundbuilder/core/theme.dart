import 'package:flutter/material.dart';

class AppTheme {
  // Minimal Luxe color palette
  static const Color primary = Color(0xFF121212); // Deep charcoal
  static const Color primaryVariant = Color(0xFF1E1E1E); // Slightly lighter gray
  static const Color secondary = Color(0xFFC8A96A); // Muted gold accent
  static const Color background = Color(0xFF0E0E0E); // Near black background
  static const Color surface = Color(0xFF1A1A1A); // Card surfaces

  static const Color onPrimary = Color(0xFFF5F5F5); // Off-white text/icons
  static const Color onSecondary = Color(0xFF121212); // Dark text on gold
  static const Color onSurface = Color(0xFFE0E0E0); // Light gray text on dark

  // Define the ThemeData
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
    ),

    // AppBar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryVariant,
      titleTextStyle: TextStyle(
        color: onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: onPrimary),
      elevation: 0,
    ),

    // Global text styles
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
    ),

    // Slider styling
    sliderTheme: const SliderThemeData(
      activeTrackColor: secondary,
      thumbColor: secondary,
      overlayColor: Color(0x40C8A96A), // gold with transparency
      inactiveTrackColor: Color(0xFF2C2C2C),
    ),

    // ElevatedButton styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: onSurface,
        foregroundColor: onSecondary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 2,
      ),
    ),

    // Card styling
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 3,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}