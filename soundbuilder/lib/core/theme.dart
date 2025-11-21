import 'package:flutter/material.dart';

class AppTheme {
  // Minimal Luxe color palette
  static const Color nearblack = Color.fromARGB(255, 18, 19, 22);
  static const Color nearwhite = Color.fromARGB(255, 245, 246, 248);
  static const Color calmgrey = Color.fromARGB(255, 36, 38, 42);
  static const Color mutedred = Color.fromARGB(255, 124, 58, 50);


// Light gray text on dark

  // Define the ThemeData
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: nearblack,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mutedred,
      brightness: Brightness.dark,
    ).copyWith(
      primary: mutedred,
      secondary: mutedred,
      surface: nearblack,
    ),

    // AppBar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: nearblack,
      titleTextStyle: TextStyle(
        color: nearblack,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: nearblack),
      elevation: 0,
    ),

    // Global text styles
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: nearwhite,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: nearwhite,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: nearwhite,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: nearwhite,
      ),
    ),

    // Slider styling
    sliderTheme: const SliderThemeData(
      activeTrackColor: mutedred,
      thumbColor: calmgrey,
      overlayColor: Color(0x40C8A96A), // gold with transparency
      inactiveTrackColor: Color(0xFF2C2C2C),
    ),

    // ElevatedButton styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: calmgrey,
        foregroundColor: nearwhite,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 2,
      ),
    ),
  );
}