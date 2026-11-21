import 'package:flutter/material.dart';

/// Escala de espaciado (múltiplos de 4).
abstract final class Espacio {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radios: redondeados como las tarjetas de la paleta (12–20) y píldora.
abstract final class Radios {
  static const s = 12.0;
  static const m = 16.0;
  static const l = 20.0;
  static const pildora = 999.0;

  static final bordeS = BorderRadius.circular(s);
  static final bordeM = BorderRadius.circular(m);
  static final bordeL = BorderRadius.circular(l);
}

/// Sombras suaves teñidas de guinda (nunca gris plano).
abstract final class Sombra {
  static const suave = [
    BoxShadow(
      color: Color(0x0F5B011D),
      blurRadius: 14,
      offset: Offset(0, 3),
    ),
  ];
  static const elevada = [
    BoxShadow(
      color: Color(0x1F5B011D),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];
}
