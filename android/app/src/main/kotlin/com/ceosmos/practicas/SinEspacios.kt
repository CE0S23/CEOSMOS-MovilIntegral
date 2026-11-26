package com.ceosmos.practicas

/**
 * Reglas de espacios en los campos de usuario (1.4.0), iguales a las de Flutter
 * (`lib/core/sin_espacios.dart`) y a las de la API (`@SinEspacios`).
 *
 * - Correo, usuario, códigos y contraseñas: sin espacios en ninguna posición.
 * - Nombres de persona: sin espacios al inicio ni al final y sin dobles.
 */
object SinEspacios {
    const val MENSAJE = "Este campo no admite espacios. Los quitamos por ti."

    fun tieneEspacios(valor: String): Boolean = valor.any { it.isWhitespace() }

    /** Devuelve el texto sin espacios y si se quitó alguno (para avisar). */
    fun limpiar(valor: String): Pair<String, Boolean> {
        val limpio = valor.filterNot { it.isWhitespace() }
        return limpio to (limpio.length != valor.length)
    }

    /** Nombre de persona listo para guardar. */
    fun normalizarNombre(valor: String): String = valor.trim().replace(Regex("""\s+"""), " ")
}
