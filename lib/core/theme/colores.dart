import 'package:flutter/material.dart';

/// Tokens de color crudos de CEOSMOS (paleta base + complementarios).
///
/// Las pantallas no deben usarlos directamente: leen [CeosmosPaleta] con
/// `context.paleta`, que resuelve el valor correcto en modo claro u oscuro.
/// Los valores marcados «AA» se oscurecieron/aclararon respecto a la paleta
/// entregada para cumplir WCAG AA (ver memoria/11 - Sistema de diseño).
abstract final class CeosmosColores {
  // Base
  static const cian = Color(0xFF51D7FD);
  static const guinda = Color(0xFF5B011D);

  // Complementarios
  static const cianOscuro = Color(0xFF0A7FA3);
  /// AA: #0A7FA3 da 4.36:1 sobre el crema y 4.11:1 sobre cianClaro; este tono
  /// da 5.36:1 y 5.05:1. Se usa para texto, íconos y enlaces cian.
  static const cianTexto = Color(0xFF08708F);
  static const cianClaro = Color(0xFFDDF7FF);
  static const guindaMedio = Color(0xFF8A1C3D);
  static const guindaClaro = Color(0xFFF6E4EA);
  static const ambar = Color(0xFFFFB547);

  // Neutros (claro)
  static const fondo = Color(0xFFFFF8F3);
  static const superficie = Color(0xFFFFFFFF);
  static const tinta = Color(0xFF1E0A12);
  static const textoSecundario = Color(0xFF6B5A60);
  static const borde = Color(0xFFEADDE1);
  /// AA (componentes, 3:1): borde de inputs y controles. #EADDE1 solo da 1.32:1.
  static const bordeControl = Color(0xFF8C7880);

  // Estados (claro). Los «Texto» son las variantes AA para texto e íconos.
  static const exito = Color(0xFF1F9E6E);
  static const exitoTexto = Color(0xFF17805A); // AA: #1F9E6E da 3.40:1 en blanco
  static const advertencia = Color(0xFFE89B12);
  static const advertenciaTexto = Color(0xFF9A5800); // AA: #E89B12 da 2.30:1
  static const error = Color(0xFFD62F45);
  static const errorTexto = Color(0xFFC42A3F); // AA también sobre su fondo suave
  static const info = cianOscuro;

  // Modo oscuro
  static const oscuroFondo = Color(0xFF16060D);
  static const oscuroSuperficie = Color(0xFF24101A);
  static const oscuroSuperficieAlta = Color(0xFF321623);
  static const oscuroTinta = Color(0xFFFCEFF3);
  static const oscuroTextoSecundario = Color(0xFFC9B3BB);
  static const oscuroGuinda = Color(0xFFF2A3BA);
  static const oscuroBorde = Color(0xFF4A2635);
  static const oscuroBordeControl = Color(0xFF8E6A79); // AA 3:1
  static const oscuroCianSuave = Color(0xFF0B3E4E);
  static const oscuroGuindaSuave = Color(0xFF4A1A2C);
  static const oscuroExito = Color(0xFF2FC08A); // AA sobre superficie oscura
  static const oscuroError = Color(0xFFFF7A8C); // AA: #D62F45 da 3.74:1

  static const blanco = Color(0xFFFFFFFF);
}
