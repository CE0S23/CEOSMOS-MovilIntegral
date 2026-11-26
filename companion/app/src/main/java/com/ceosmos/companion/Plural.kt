package com.ceosmos.companion

/** Singular y plural de los textos con contador (1.4.0): «1 paso», «2 pasos». */
object Plural {
    fun contar(n: Int, singular: String, plural: String): String =
        "$n ${if (kotlin.math.abs(n) == 1) singular else plural}"
}
