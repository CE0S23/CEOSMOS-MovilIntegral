package com.ceosmos.companion

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

/*
 * Sistema de diseño de CEOSMOS para Reloj y TV: mismos tokens que la app Flutter
 * (lib/core/theme). Los tonos marcados «AA» se ajustaron para cumplir WCAG AA.
 */

object CeosmosColores {
    val Cian = Color(0xFF51D7FD)
    val Guinda = Color(0xFF5B011D)
    val CianOscuro = Color(0xFF0A7FA3)
    val CianTexto = Color(0xFF08708F) // AA sobre crema y cianClaro
    val CianClaro = Color(0xFFDDF7FF)
    val GuindaMedio = Color(0xFF8A1C3D)
    val GuindaClaro = Color(0xFFF6E4EA)
    val Ambar = Color(0xFFFFB547)
    val Blanco = Color(0xFFFFFFFF)
}

/** Colores semánticos resueltos para el modo activo. */
@Immutable
data class Paleta(
    val fondo: Color,
    val superficie: Color,
    val superficieAlta: Color,
    val tinta: Color,
    val textoSecundario: Color,
    val borde: Color,
    val bordeControl: Color,
    val marca: Color,
    val sobreMarca: Color,
    val enlace: Color,
    val cianSuave: Color,
    val guindaSuave: Color,
    val exito: Color,
    val advertencia: Color,
    val error: Color,
    val foco: Color,
)

val PaletaClara = Paleta(
    fondo = Color(0xFFFFF8F3),
    superficie = Color(0xFFFFFFFF),
    superficieAlta = CeosmosColores.GuindaClaro,
    tinta = Color(0xFF1E0A12),
    textoSecundario = Color(0xFF6B5A60),
    borde = Color(0xFFEADDE1),
    bordeControl = Color(0xFF8C7880),
    marca = CeosmosColores.Guinda,
    sobreMarca = CeosmosColores.Blanco,
    enlace = CeosmosColores.CianTexto,
    cianSuave = CeosmosColores.CianClaro,
    guindaSuave = CeosmosColores.GuindaClaro,
    exito = Color(0xFF17805A), // AA
    advertencia = Color(0xFF9A5800), // AA
    error = Color(0xFFC42A3F), // AA
    foco = CeosmosColores.GuindaMedio,
)

val PaletaOscura = Paleta(
    fondo = Color(0xFF16060D),
    superficie = Color(0xFF24101A),
    superficieAlta = Color(0xFF321623),
    tinta = Color(0xFFFCEFF3),
    textoSecundario = Color(0xFFC9B3BB),
    borde = Color(0xFF4A2635),
    bordeControl = Color(0xFF8E6A79),
    marca = Color(0xFFF2A3BA),
    sobreMarca = CeosmosColores.Guinda,
    enlace = CeosmosColores.Cian,
    cianSuave = Color(0xFF0B3E4E),
    guindaSuave = Color(0xFF4A1A2C),
    exito = Color(0xFF2FC08A),
    advertencia = Color(0xFFE89B12),
    error = Color(0xFFFF7A8C), // AA
    foco = CeosmosColores.Cian,
)

val LocalPaleta = staticCompositionLocalOf { PaletaOscura }

object Fuentes {
    val Titulos = FontFamily(
        Font(R.font.bricolage_grotesque_bold, FontWeight.Bold),
        Font(R.font.bricolage_grotesque_extrabold, FontWeight.ExtraBold),
    )
    val Texto = FontFamily(
        Font(R.font.dm_sans_regular, FontWeight.Normal),
        Font(R.font.dm_sans_medium, FontWeight.Medium),
        Font(R.font.dm_sans_bold, FontWeight.Bold),
    )
}

/** Escala adaptada al formato: compacta en el reloj, grande para verse a distancia en la TV. */
enum class Formato { RELOJ, TV }

private fun titulo(size: TextUnit, peso: FontWeight, tracking: TextUnit) =
    TextStyle(fontFamily = Fuentes.Titulos, fontSize = size, fontWeight = peso, letterSpacing = tracking, lineHeight = size * 1.08)

private fun texto(size: TextUnit, peso: FontWeight = FontWeight.Normal) =
    TextStyle(fontFamily = Fuentes.Texto, fontSize = size, fontWeight = peso, lineHeight = size * 1.4)

fun escala(formato: Formato): Typography = when (formato) {
    Formato.RELOJ -> Typography(
        displayLarge = titulo(46.sp, FontWeight.ExtraBold, (-0.04).em),
        displayMedium = titulo(36.sp, FontWeight.ExtraBold, (-0.03).em),
        headlineSmall = titulo(24.sp, FontWeight.Bold, (-0.02).em),
        titleLarge = titulo(18.sp, FontWeight.Bold, (-0.01).em),
        titleMedium = texto(14.sp, FontWeight.Bold),
        bodyLarge = texto(14.sp),
        bodyMedium = texto(12.sp),
        bodySmall = texto(11.sp),
        labelLarge = texto(13.sp, FontWeight.Bold),
        labelMedium = texto(12.sp, FontWeight.Medium),
        labelSmall = texto(11.sp, FontWeight.Medium),
    )
    Formato.TV -> Typography(
        displayLarge = titulo(120.sp, FontWeight.ExtraBold, (-0.04).em),
        displayMedium = titulo(64.sp, FontWeight.ExtraBold, (-0.03).em),
        displaySmall = titulo(52.sp, FontWeight.ExtraBold, (-0.025).em),
        headlineLarge = titulo(44.sp, FontWeight.Bold, (-0.02).em),
        headlineSmall = titulo(26.sp, FontWeight.Bold, (-0.01).em),
        titleLarge = titulo(22.sp, FontWeight.Bold, 0.sp),
        titleMedium = texto(20.sp, FontWeight.Bold),
        bodyLarge = texto(22.sp),
        bodyMedium = texto(18.sp),
        bodySmall = texto(14.sp),
        labelLarge = texto(24.sp, FontWeight.Bold),
        labelMedium = texto(16.sp, FontWeight.Bold),
        labelSmall = texto(14.sp, FontWeight.Medium),
    )
}

@Composable
fun TemaCeosmos(formato: Formato, oscuro: Boolean = isSystemInDarkTheme(), contenido: @Composable () -> Unit) {
    val p = if (oscuro) PaletaOscura else PaletaClara
    val esquema = if (oscuro) {
        darkColorScheme(
            primary = p.marca, onPrimary = p.sobreMarca,
            secondary = CeosmosColores.Cian, onSecondary = CeosmosColores.Guinda,
            tertiary = CeosmosColores.Cian, background = p.fondo, onBackground = p.tinta,
            surface = p.superficie, onSurface = p.tinta, onSurfaceVariant = p.textoSecundario,
            surfaceVariant = p.superficieAlta, outline = p.bordeControl, outlineVariant = p.borde,
            error = p.error,
        )
    } else {
        lightColorScheme(
            primary = p.marca, onPrimary = p.sobreMarca,
            secondary = CeosmosColores.Cian, onSecondary = CeosmosColores.Guinda,
            tertiary = p.enlace, background = p.fondo, onBackground = p.tinta,
            surface = p.superficie, onSurface = p.tinta, onSurfaceVariant = p.textoSecundario,
            surfaceVariant = p.superficieAlta, outline = p.bordeControl, outlineVariant = p.borde,
            error = p.error,
        )
    }
    androidx.compose.runtime.CompositionLocalProvider(LocalPaleta provides p) {
        MaterialTheme(colorScheme = esquema, typography = escala(formato), content = contenido)
    }
}
