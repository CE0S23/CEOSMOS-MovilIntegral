package com.ceosmos.companion

import org.junit.Assert.assertEquals
import org.junit.Test

/** 1.4.0 · Regresión: «1 pasos» en la pantalla del Reloj. */
class PluralTest {
    @Test fun singularSoloConUno() {
        assertEquals("1 paso", Plural.contar(1, "paso", "pasos"))
        assertEquals("0 pasos", Plural.contar(0, "paso", "pasos"))
        assertEquals("12 pasos", Plural.contar(12, "paso", "pasos"))
    }
}
