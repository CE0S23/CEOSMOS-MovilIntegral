import 'package:flutter/material.dart';

/// Familias empaquetadas en assets/fonts (OFL, sin carga por red).
abstract final class Fuentes {
  /// Títulos y números grandes (700–800).
  static const titulos = 'Bricolage Grotesque';
  /// Texto, botones, formularios y tablas (400/500/700).
  static const texto = 'DM Sans';
}

/// Escala tipográfica única de CEOSMOS (displayLarge → labelSmall).
///
/// Bricolage para display/headline/titleLarge, con tracking negativo que
/// crece con el tamaño; DM Sans para todo lo demás.
TextTheme escalaCeosmos(Color tinta, Color secundario) {
  TextStyle bri(double size, FontWeight w, double tracking, double h) =>
      TextStyle(
        fontFamily: Fuentes.titulos,
        fontSize: size,
        fontWeight: w,
        letterSpacing: tracking,
        height: h,
        color: tinta,
      );
  TextStyle dm(double size, FontWeight w, double h, [double tracking = 0]) =>
      TextStyle(
        fontFamily: Fuentes.texto,
        fontSize: size,
        fontWeight: w,
        height: h,
        letterSpacing: tracking,
        color: tinta,
      );
  return TextTheme(
    displayLarge: bri(56, FontWeight.w800, -2.0, 1.04),
    displayMedium: bri(44, FontWeight.w800, -1.4, 1.08),
    displaySmall: bri(36, FontWeight.w800, -1.0, 1.1),
    headlineLarge: bri(34, FontWeight.w800, -1.0, 1.12),
    headlineMedium: bri(28, FontWeight.w700, -0.6, 1.15),
    headlineSmall: bri(24, FontWeight.w700, -0.4, 1.2),
    titleLarge: bri(21, FontWeight.w700, -0.3, 1.25),
    titleMedium: dm(16, FontWeight.w700, 1.35),
    titleSmall: dm(14, FontWeight.w700, 1.35),
    bodyLarge: dm(16, FontWeight.w400, 1.5),
    bodyMedium: dm(14, FontWeight.w400, 1.5),
    bodySmall: dm(12, FontWeight.w400, 1.45).copyWith(color: secundario),
    labelLarge: dm(14, FontWeight.w700, 1.2, 0.1),
    labelMedium: dm(12, FontWeight.w500, 1.3, 0.2),
    labelSmall: dm(11, FontWeight.w700, 1.3, 0.4),
  );
}
