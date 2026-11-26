package com.ceosmos.practicas

import com.ceosmos.practicas.p05.AccesoSeguroChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** 1.4.0 · Regresión: los campos nativos de usuario no admiten espacios. */
class SinEspaciosTest {
    private val canal = AccesoSeguroChannel()

    @Test fun limpiaEspaciosEnCualquierPosicion() {
        assertEquals("qa@ejemplo.com" to true, SinEspacios.limpiar(" qa @ejemplo.com\t"))
        assertEquals("qa@ejemplo.com" to false, SinEspacios.limpiar("qa@ejemplo.com"))
    }

    @Test fun normalizaNombreDePersona() {
        assertEquals("Ana María López", SinEspacios.normalizarNombre("  Ana   María  López "))
    }

    @Test fun seguridadRechazaUsuarioConEspacios() {
        val r = canal.validateLogin("alu mno", "ClaveLarga1")
        assertFalse(r["ok"] as Boolean)
        assertEquals("El usuario no puede contener espacios.", r["message"])
    }

    @Test fun seguridadRechazaContrasenaConEspacios() {
        val r = canal.validateLogin("alumno", "Clave Larga1")
        assertFalse(r["ok"] as Boolean)
        assertEquals("La contraseña no puede contener espacios.", r["message"])
    }

    @Test fun seguridadSinEspaciosSigueValidandoElResto() {
        val r = canal.validateLogin("alumno", "corta")
        assertFalse(r["ok"] as Boolean)
        assertTrue((r["message"] as String).contains("8 caracteres"))
    }
}
