import 'package:flutter/material.dart';

import 'colores.dart';
import 'medidas.dart';
import 'paleta.dart';
import 'tipografia.dart';

/// ThemeData claro y oscuro de CEOSMOS. Lo usan la app principal y cada
/// práctica Flutter (todas comparten tokens).
abstract final class CeosmosTema {
  static final ThemeData claro = _construir(
    Brightness.light,
    const ColorScheme(
      brightness: Brightness.light,
      primary: CeosmosColores.guinda,
      onPrimary: CeosmosColores.blanco,
      primaryContainer: CeosmosColores.guindaClaro,
      onPrimaryContainer: CeosmosColores.guinda,
      secondary: CeosmosColores.cian,
      onSecondary: CeosmosColores.guinda,
      secondaryContainer: CeosmosColores.cianClaro,
      onSecondaryContainer: CeosmosColores.guinda,
      tertiary: CeosmosColores.cianTexto,
      onTertiary: CeosmosColores.blanco,
      tertiaryContainer: CeosmosColores.ambar,
      onTertiaryContainer: CeosmosColores.guinda,
      error: CeosmosColores.errorTexto,
      onError: CeosmosColores.blanco,
      errorContainer: Color(0xFFFBE5E8),
      onErrorContainer: Color(0xFF7A1020),
      surface: CeosmosColores.superficie,
      onSurface: CeosmosColores.tinta,
      onSurfaceVariant: CeosmosColores.textoSecundario,
      surfaceContainerLowest: CeosmosColores.superficie,
      surfaceContainerLow: Color(0xFFFFFBF8),
      surfaceContainer: Color(0xFFFDF3F2),
      surfaceContainerHigh: Color(0xFFF9EBEE),
      surfaceContainerHighest: CeosmosColores.guindaClaro,
      outline: CeosmosColores.bordeControl,
      outlineVariant: CeosmosColores.borde,
      shadow: CeosmosColores.guinda,
      scrim: CeosmosColores.tinta,
      inverseSurface: CeosmosColores.tinta,
      onInverseSurface: CeosmosColores.fondo,
      inversePrimary: CeosmosColores.cian,
      surfaceTint: Colors.transparent,
    ),
    CeosmosPaleta.claro,
  );

  static final ThemeData oscuro = _construir(
    Brightness.dark,
    const ColorScheme(
      brightness: Brightness.dark,
      primary: CeosmosColores.oscuroGuinda,
      onPrimary: CeosmosColores.guinda,
      primaryContainer: CeosmosColores.guinda,
      onPrimaryContainer: CeosmosColores.oscuroTinta,
      secondary: CeosmosColores.cian,
      onSecondary: CeosmosColores.guinda,
      secondaryContainer: CeosmosColores.oscuroCianSuave,
      onSecondaryContainer: CeosmosColores.cianClaro,
      tertiary: CeosmosColores.cian,
      onTertiary: CeosmosColores.guinda,
      tertiaryContainer: CeosmosColores.ambar,
      onTertiaryContainer: CeosmosColores.guinda,
      error: CeosmosColores.oscuroError,
      onError: Color(0xFF3A0010),
      errorContainer: Color(0xFF5C1422),
      onErrorContainer: Color(0xFFFFD9DE),
      surface: CeosmosColores.oscuroSuperficie,
      onSurface: CeosmosColores.oscuroTinta,
      onSurfaceVariant: CeosmosColores.oscuroTextoSecundario,
      surfaceContainerLowest: CeosmosColores.oscuroFondo,
      surfaceContainerLow: Color(0xFF1D0A13),
      surfaceContainer: CeosmosColores.oscuroSuperficie,
      surfaceContainerHigh: CeosmosColores.oscuroSuperficieAlta,
      surfaceContainerHighest: Color(0xFF3B1B2A),
      outline: CeosmosColores.oscuroBordeControl,
      outlineVariant: CeosmosColores.oscuroBorde,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: CeosmosColores.oscuroTinta,
      onInverseSurface: CeosmosColores.tinta,
      inversePrimary: CeosmosColores.guinda,
      surfaceTint: Colors.transparent,
    ),
    CeosmosPaleta.oscuro,
  );

  static ThemeData _construir(
    Brightness brillo,
    ColorScheme cs,
    CeosmosPaleta p,
  ) {
    final oscuro = brillo == Brightness.dark;
    final texto = escalaCeosmos(p.tinta, p.textoSecundario);
    final radioS = RoundedRectangleBorder(borderRadius: Radios.bordeS);
    final deshabilitadoFondo = p.tinta.withValues(alpha: .10);
    final deshabilitadoTexto = p.tinta.withValues(alpha: .40);
    // Hover/pressed del botón primario: guindaMedio en claro.
    final primarioActivo = oscuro
        ? const Color(0xFFF7C1D0)
        : CeosmosColores.guindaMedio;
    final foco = oscuro ? CeosmosColores.cian : CeosmosColores.guindaMedio;

    WidgetStateProperty<Color?> fondoBoton(Color base, Color activo) =>
        WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return deshabilitadoFondo;
          if (s.contains(WidgetState.pressed) ||
              s.contains(WidgetState.hovered)) {
            return activo;
          }
          return base;
        });
    WidgetStateProperty<Color?> textoBoton(Color base) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? deshabilitadoTexto : base,
        );
    final bordeFoco = WidgetStateProperty.resolveWith<BorderSide?>(
      (s) => s.contains(WidgetState.focused)
          ? BorderSide(color: foco, width: 2)
          : null,
    );
    final tamBoton = WidgetStateProperty.all(const Size(48, 52));
    final relleno = WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: Espacio.xl, vertical: Espacio.l),
    );
    final formaBoton = WidgetStateProperty.all<OutlinedBorder>(radioS);
    final textoEtiqueta = WidgetStateProperty.all(texto.labelLarge);

    // Secundario: fondo cian, texto guinda (igual en claro y oscuro).
    final secundario = ButtonStyle(
      backgroundColor: fondoBoton(
        CeosmosColores.cian,
        const Color(0xFF8FE6FE),
      ),
      foregroundColor: textoBoton(CeosmosColores.guinda),
      iconColor: textoBoton(CeosmosColores.guinda),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: bordeFoco,
      minimumSize: tamBoton,
      padding: relleno,
      shape: formaBoton,
      textStyle: textoEtiqueta,
      elevation: WidgetStateProperty.all(0),
    );

    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: Radios.bordeS,
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: cs,
      scaffoldBackgroundColor: p.fondo,
      canvasColor: p.fondo,
      fontFamily: Fuentes.texto,
      textTheme: texto,
      primaryTextTheme: texto,
      extensions: [p],
      dividerColor: p.borde,
      focusColor: CeosmosColores.cian.withValues(alpha: .28),
      hoverColor: p.marca.withValues(alpha: .05),
      splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
      iconTheme: IconThemeData(color: p.tinta, size: 22),
      dividerTheme: DividerThemeData(color: p.borde, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        // Encabezados: fondo crema con título guinda en toda la app.
        backgroundColor: p.fondo,
        foregroundColor: p.marca,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: texto.titleLarge?.copyWith(color: p.marca),
        iconTheme: IconThemeData(color: p.marca),
        actionsIconTheme: IconThemeData(color: p.marca),
        shape: Border(bottom: BorderSide(color: p.borde)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: fondoBoton(cs.primary, primarioActivo),
          foregroundColor: textoBoton(cs.onPrimary),
          iconColor: textoBoton(cs.onPrimary),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? const BorderSide(color: CeosmosColores.cian, width: 2.5)
                : null,
          ),
          minimumSize: tamBoton,
          padding: relleno,
          shape: formaBoton,
          textStyle: textoEtiqueta,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: secundario),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secundario),
      textButtonTheme: TextButtonThemeData(
        // Terciario: texto cian legible, sin fondo.
        style: ButtonStyle(
          foregroundColor: textoBoton(p.enlace),
          iconColor: textoBoton(p.enlace),
          overlayColor: WidgetStateProperty.all(
            p.enlace.withValues(alpha: .08),
          ),
          side: bordeFoco,
          shape: formaBoton,
          textStyle: textoEtiqueta,
          minimumSize: WidgetStateProperty.all(const Size(48, 44)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          side: bordeFoco,
          minimumSize: WidgetStateProperty.all(const Size(44, 44)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espacio.l + 2,
          vertical: Espacio.l + 2,
        ),
        labelStyle: texto.bodyMedium?.copyWith(color: p.textoSecundario),
        floatingLabelStyle: texto.labelMedium?.copyWith(color: p.marca),
        hintStyle: texto.bodyMedium?.copyWith(color: p.textoSecundario),
        helperStyle: texto.bodySmall,
        errorStyle: texto.bodySmall?.copyWith(
          color: cs.error,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: p.textoSecundario,
        suffixIconColor: p.textoSecundario,
        border: borde(p.bordeControl),
        enabledBorder: borde(p.bordeControl),
        disabledBorder: borde(p.borde),
        focusedBorder: borde(foco, 2),
        errorBorder: borde(cs.error),
        focusedErrorBorder: borde(cs.error, 2),
      ),
      cardTheme: CardThemeData(
        color: p.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radios.bordeL,
          side: BorderSide(color: p.borde),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.superficie,
        selectedColor: p.cianSuave,
        disabledColor: deshabilitadoFondo,
        checkmarkColor: p.marca,
        labelStyle: texto.labelMedium?.copyWith(color: p.tinta),
        secondaryLabelStyle: texto.labelMedium?.copyWith(
          color: oscuro ? CeosmosColores.cianClaro : CeosmosColores.guinda,
          fontWeight: FontWeight.w700,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.selected)
                ? (oscuro ? CeosmosColores.cian : CeosmosColores.cianTexto)
                : p.borde,
          ),
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: Espacio.s),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.cianSuave,
        height: 74,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? (oscuro ? CeosmosColores.cian : CeosmosColores.guinda)
                : p.textoSecundario,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => texto.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? p.marca : p.textoSecundario,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.superficie,
        indicatorColor: p.cianSuave,
        selectedIconTheme: IconThemeData(color: p.marca),
        unselectedIconTheme: IconThemeData(color: p.textoSecundario),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.enlace,
        textColor: p.tinta,
        selectedColor: p.marca,
        selectedTileColor: p.guindaSuave,
        titleTextStyle: texto.titleSmall,
        subtitleTextStyle: texto.bodySmall,
        shape: radioS,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radios.bordeL),
        titleTextStyle: texto.headlineSmall?.copyWith(color: p.marca),
        contentTextStyle: texto.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.superficie,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: p.bordeControl,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: texto.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: oscuro ? CeosmosColores.cianTexto : CeosmosColores.cian,
        shape: radioS,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.marca,
        unselectedLabelColor: p.textoSecundario,
        indicatorColor: p.marca,
        dividerColor: p.borde,
        labelStyle: texto.labelLarge,
        unselectedLabelStyle: texto.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: texto.labelMedium?.copyWith(color: cs.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: oscuro ? CeosmosColores.cian : CeosmosColores.guinda,
        linearTrackColor: p.guindaSuave,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.onPrimary : p.bordeControl,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.primary : p.superficieAlta,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.primary : p.bordeControl,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.cianSuave : p.superficie,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.marca : p.tinta,
          ),
          side: WidgetStateProperty.all(BorderSide(color: p.bordeControl)),
          textStyle: WidgetStateProperty.all(texto.labelMedium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: oscuro ? CeosmosColores.cian : CeosmosColores.guinda,
        foregroundColor: oscuro ? CeosmosColores.guinda : CeosmosColores.blanco,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: Radios.bordeM),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: CeosmosColores.ambar,
        textColor: CeosmosColores.guinda,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.superficie,
        surfaceTintColor: Colors.transparent,
        shape: radioS,
        textStyle: texto.bodyMedium,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: texto.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(p.superficie),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: p.bordeControl, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.primary : p.bordeControl,
        ),
      ),
    );
  }
}
