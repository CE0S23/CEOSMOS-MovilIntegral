package com.ceosmos.practicas

/**
 * Singular y plural de los textos con contador (1.4.0), igual que `lib/core/plural.dart`:
 * «1 incidencia», «2 incidencias», «0 incidencias».
 */
object Plural {
    fun palabra(n: Int, singular: String, plural: String): String = if (kotlin.math.abs(n) == 1) singular else plural

    fun contar(n: Int, singular: String, plural: String): String = "$n ${palabra(n, singular, plural)}"
}
