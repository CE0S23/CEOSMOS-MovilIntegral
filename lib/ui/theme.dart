import 'package:flutter/material.dart';

abstract final class Cosmos {
  static const background = Color(0xFF0B0D18);
  static const surface = Color(0xFF141725);
  static const elevated = Color(0xFF1C2032);
  static const border = Color(0xFF2B3046);
  static const lavender = Color(0xFFC2ADFF);
  static const mint = Color(0xFF8AD8BC);
  static const peach = Color(0xFFEABD9C);
  static const text = Color(0xFFF3F0FF);
  static const muted = Color(0xFFA5A9BE);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: lavender,
      onPrimary: background,
      secondary: mint,
      surface: surface,
      onSurface: text,
      outline: border,
    ),
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -.8,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -.4,
      ),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    ).apply(bodyColor: text, displayColor: text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lavender),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: border),
      ),
    ),
    chipTheme: ChipThemeData(
      side: const BorderSide(color: border),
      backgroundColor: surface,
      selectedColor: const Color(0xFF39304F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Color(0xFF39304F),
      height: 74,
    ),
    dividerColor: border,
  );
}
