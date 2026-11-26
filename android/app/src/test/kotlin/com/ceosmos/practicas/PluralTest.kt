package com.ceosmos.practicas

import org.junit.Assert.assertEquals
import org.junit.Test

/** 1.4.0 · Regresión: «1 incidencias» / «1 documentos» en las pantallas nativas. */
class PluralTest {
    @Test fun singularSoloConUno() {
        assertEquals("1 incidencia", Plural.contar(1, "incidencia", "incidencias"))
        assertEquals("0 incidencias", Plural.contar(0, "incidencia", "incidencias"))
        assertEquals("2 documentos", Plural.contar(2, "documento", "documentos"))
        assertEquals("conocido", Plural.palabra(-1, "conocido", "conocidos"))
    }
}
