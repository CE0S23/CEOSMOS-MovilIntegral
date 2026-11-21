package com.ceosmos.practicas

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.ceosmos.ceosmos_movil_integral.R

/**
 * Sistema de diseño de CEOSMOS para las prácticas nativas (P9, P10): los mismos
 * tokens que lib/core/theme de la app Flutter y que el companion Reloj/TV.
 */
object CeosmosTema {
    val Guinda = Color(0xFF5B011D)
    val GuindaMedio = Color(0xFF8A1C3D)
    val GuindaClaro = Color(0xFFF6E4EA)
    val Cian = Color(0xFF51D7FD)
    val CianTexto = Color(0xFF08708F) // AA: cianOscuro (#0A7FA3) como texto
    val CianClaro = Color(0xFFDDF7FF)

    private val Titulos = FontFamily(
        Font(R.font.bricolage_grotesque_bold, FontWeight.Bold),
        Font(R.font.bricolage_grotesque_extrabold, FontWeight.ExtraBold),
    )
    private val Texto = FontFamily(
        Font(R.font.dm_sans_regular, FontWeight.Normal),
        Font(R.font.dm_sans_medium, FontWeight.Medium),
        Font(R.font.dm_sans_bold, FontWeight.Bold),
    )

    private fun t(size: TextUnit, w: FontWeight, track: TextUnit = 0.sp) =
        TextStyle(fontFamily = Titulos, fontSize = size, fontWeight = w, letterSpacing = track, lineHeight = size * 1.15)

    private fun d(size: TextUnit, w: FontWeight = FontWeight.Normal) =
        TextStyle(fontFamily = Texto, fontSize = size, fontWeight = w, lineHeight = size * 1.45)

    /** Misma escala que la app (displayLarge → labelSmall). */
    val tipografia = Typography(
        displayLarge = t(56.sp, FontWeight.ExtraBold, (-0.035).em),
        displayMedium = t(44.sp, FontWeight.ExtraBold, (-0.03).em),
        displaySmall = t(36.sp, FontWeight.ExtraBold, (-0.025).em),
        headlineLarge = t(34.sp, FontWeight.ExtraBold, (-0.03).em),
        headlineMedium = t(28.sp, FontWeight.Bold, (-0.02).em),
        headlineSmall = t(24.sp, FontWeight.Bold, (-0.015).em),
        titleLarge = t(21.sp, FontWeight.Bold, (-0.015).em),
        titleMedium = d(16.sp, FontWeight.Bold),
        titleSmall = d(14.sp, FontWeight.Bold),
        bodyLarge = d(16.sp),
        bodyMedium = d(14.sp),
        bodySmall = d(12.sp),
        labelLarge = d(14.sp, FontWeight.Bold),
        labelMedium = d(12.sp, FontWeight.Medium),
        labelSmall = d(11.sp, FontWeight.Bold),
    )

    val claro: ColorScheme = lightColorScheme(
        primary = Guinda, onPrimary = Color.White,
        primaryContainer = GuindaClaro, onPrimaryContainer = Guinda,
        secondary = Cian, onSecondary = Guinda,
        secondaryContainer = CianClaro, onSecondaryContainer = Guinda,
        tertiary = CianTexto, onTertiary = Color.White,
        background = Color(0xFFFFF8F3), onBackground = Color(0xFF1E0A12),
        surface = Color(0xFFFFFFFF), onSurface = Color(0xFF1E0A12),
        surfaceVariant = GuindaClaro, onSurfaceVariant = Color(0xFF6B5A60),
        outline = Color(0xFF8C7880), outlineVariant = Color(0xFFEADDE1),
        error = Color(0xFFC42A3F), onError = Color.White,
        errorContainer = Color(0xFFFBE5E8), onErrorContainer = Color(0xFF7A1020),
    )

    val oscuro: ColorScheme = darkColorScheme(
        primary = Color(0xFFF2A3BA), onPrimary = Guinda,
        primaryContainer = Guinda, onPrimaryContainer = Color(0xFFFCEFF3),
        secondary = Cian, onSecondary = Guinda,
        secondaryContainer = Color(0xFF0B3E4E), onSecondaryContainer = CianClaro,
        tertiary = Cian, onTertiary = Guinda,
        background = Color(0xFF16060D), onBackground = Color(0xFFFCEFF3),
        surface = Color(0xFF24101A), onSurface = Color(0xFFFCEFF3),
        surfaceVariant = Color(0xFF321623), onSurfaceVariant = Color(0xFFC9B3BB),
        outline = Color(0xFF8E6A79), outlineVariant = Color(0xFF4A2635),
        error = Color(0xFFFF7A8C), onError = Color(0xFF3A0010),
        errorContainer = Color(0xFF5C1422), onErrorContainer = Color(0xFFFFD9DE),
    )
}
