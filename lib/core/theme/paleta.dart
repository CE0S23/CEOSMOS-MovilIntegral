import 'package:flutter/material.dart';

import 'colores.dart';

/// Colores semánticos de CEOSMOS que el [ColorScheme] no cubre. Se leen con
/// `context.paleta` y cambian solos entre modo claro y oscuro.
@immutable
class CeosmosPaleta extends ThemeExtension<CeosmosPaleta> {
  const CeosmosPaleta({
    required this.fondo,
    required this.superficie,
    required this.superficieAlta,
    required this.tinta,
    required this.textoSecundario,
    required this.borde,
    required this.bordeControl,
    required this.marca,
    required this.sobreMarca,
    required this.cian,
    required this.sobreCian,
    required this.enlace,
    required this.cianSuave,
    required this.guindaSuave,
    required this.acento,
    required this.sobreAcento,
    required this.exito,
    required this.advertencia,
    required this.error,
    required this.info,
  });

  /// Fondo de pantalla (crema en claro).
  final Color fondo;
  final Color superficie;
  /// Superficie destacada: barra de sesión, avatares, celdas vacías.
  final Color superficieAlta;
  final Color tinta;
  final Color textoSecundario;
  /// Borde decorativo de tarjetas.
  final Color borde;
  /// Borde de inputs y controles (3:1).
  final Color bordeControl;
  /// Guinda legible: títulos de marca, íconos de marca, modo «Enfoque».
  final Color marca;
  final Color sobreMarca;
  final Color cian;
  /// Texto sobre cian: siempre guinda.
  final Color sobreCian;
  /// Cian legible para texto, íconos y enlaces.
  final Color enlace;
  final Color cianSuave;
  final Color guindaSuave;
  final Color acento;
  final Color sobreAcento;
  final Color exito;
  final Color advertencia;
  final Color error;
  final Color info;

  static const claro = CeosmosPaleta(
    fondo: CeosmosColores.fondo,
    superficie: CeosmosColores.superficie,
    superficieAlta: CeosmosColores.guindaClaro,
    tinta: CeosmosColores.tinta,
    textoSecundario: CeosmosColores.textoSecundario,
    borde: CeosmosColores.borde,
    bordeControl: CeosmosColores.bordeControl,
    marca: CeosmosColores.guinda,
    sobreMarca: CeosmosColores.blanco,
    cian: CeosmosColores.cian,
    sobreCian: CeosmosColores.guinda,
    enlace: CeosmosColores.cianTexto,
    cianSuave: CeosmosColores.cianClaro,
    guindaSuave: CeosmosColores.guindaClaro,
    acento: CeosmosColores.ambar,
    sobreAcento: CeosmosColores.guinda,
    exito: CeosmosColores.exitoTexto,
    advertencia: CeosmosColores.advertenciaTexto,
    error: CeosmosColores.errorTexto,
    info: CeosmosColores.cianTexto,
  );

  static const oscuro = CeosmosPaleta(
    fondo: CeosmosColores.oscuroFondo,
    superficie: CeosmosColores.oscuroSuperficie,
    superficieAlta: CeosmosColores.oscuroSuperficieAlta,
    tinta: CeosmosColores.oscuroTinta,
    textoSecundario: CeosmosColores.oscuroTextoSecundario,
    borde: CeosmosColores.oscuroBorde,
    bordeControl: CeosmosColores.oscuroBordeControl,
    marca: CeosmosColores.oscuroGuinda,
    sobreMarca: CeosmosColores.guinda,
    cian: CeosmosColores.cian,
    sobreCian: CeosmosColores.guinda,
    enlace: CeosmosColores.cian,
    cianSuave: CeosmosColores.oscuroCianSuave,
    guindaSuave: CeosmosColores.oscuroGuindaSuave,
    acento: CeosmosColores.ambar,
    sobreAcento: CeosmosColores.guinda,
    exito: CeosmosColores.oscuroExito,
    advertencia: CeosmosColores.advertencia,
    error: CeosmosColores.oscuroError,
    info: CeosmosColores.cian,
  );

  @override
  CeosmosPaleta copyWith() => this;

  @override
  CeosmosPaleta lerp(CeosmosPaleta? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CeosmosPaleta(
      fondo: l(fondo, other.fondo),
      superficie: l(superficie, other.superficie),
      superficieAlta: l(superficieAlta, other.superficieAlta),
      tinta: l(tinta, other.tinta),
      textoSecundario: l(textoSecundario, other.textoSecundario),
      borde: l(borde, other.borde),
      bordeControl: l(bordeControl, other.bordeControl),
      marca: l(marca, other.marca),
      sobreMarca: l(sobreMarca, other.sobreMarca),
      cian: l(cian, other.cian),
      sobreCian: l(sobreCian, other.sobreCian),
      enlace: l(enlace, other.enlace),
      cianSuave: l(cianSuave, other.cianSuave),
      guindaSuave: l(guindaSuave, other.guindaSuave),
      acento: l(acento, other.acento),
      sobreAcento: l(sobreAcento, other.sobreAcento),
      exito: l(exito, other.exito),
      advertencia: l(advertencia, other.advertencia),
      error: l(error, other.error),
      info: l(info, other.info),
    );
  }
}

extension CeosmosContexto on BuildContext {
  /// Paleta semántica del tema activo (claro u oscuro).
  CeosmosPaleta get paleta =>
      Theme.of(this).extension<CeosmosPaleta>() ?? CeosmosPaleta.claro;

  /// Escala tipográfica del tema activo.
  TextTheme get texto => Theme.of(this).textTheme;
}
