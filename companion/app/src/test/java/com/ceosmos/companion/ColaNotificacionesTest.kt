package com.ceosmos.companion

import com.ceosmos.companion.ble.ColaNotificaciones
import com.ceosmos.companion.ble.ColaNotificaciones.Pendiente
import com.ceosmos.companion.ble.Protocolo
import com.ceosmos.companion.ble.Protocolo.Rol
import com.ceosmos.companion.ble.Rebote
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 1.4.0 · Regresión de «los botones del Reloj y la TV fallan a veces».
 * Causa raíz: se notificaba sin esperar `onNotificationSent`; con una lectura del Reloj
 * en vuelo, la notificación del botón recibía «ocupado» y se perdía.
 */
class ColaNotificacionesTest {
    private fun lectura(hr: Int, dir: String = "C1") = Pendiente(dir, Rol.RELOJ, Protocolo.lectura(hr, 0), null)
    private fun boton(c: String, rol: Rol = Rol.RELOJ, dir: String = "C1") = Pendiente(dir, rol, Protocolo.boton(c), c)

    /** Simula el servidor de Android: solo acepta si no hay otra en vuelo. */
    private fun simular(cola: ColaNotificaciones, ocupadoCada: Int = 0): List<String> {
        val entregadas = mutableListOf<String>()
        var n = 0
        while (true) {
            val p = cola.tomar() ?: break
            n++
            if (ocupadoCada > 0 && n % ocupadoCada == 0 && cola.reintentar(p)) continue
            cola.enviada(p)
            val c = cola.confirmar()!!
            entregadas += c.etiqueta ?: "hr"
        }
        return entregadas
    }

    @Test fun soloUnaEnVuelo() {
        val cola = ColaNotificaciones()
        cola.encolar(lectura(70)); cola.encolar(boton("toggle"))
        val p = cola.tomar()!!
        cola.enviada(p)
        assertNull("no se envía otra hasta la confirmación", cola.tomar())
        assertSame(p, cola.confirmar())
        assertTrue(cola.tomar() != null)
    }

    @Test fun botonAntesQueLecturas() {
        val cola = ColaNotificaciones()
        cola.encolar(lectura(70)); cola.encolar(lectura(71, "C2")); cola.encolar(boton("stop"))
        assertEquals("stop", cola.tomar()!!.etiqueta)
    }

    @Test fun lecturasNoSeAcumulan() {
        val cola = ColaNotificaciones()
        repeat(30) { cola.encolar(lectura(60 + it)) }
        assertEquals(1, cola.tamano)
        assertEquals(89, String(cola.tomar()!!.bytes).substringAfter("\"hr\":").substringBefore(",").toInt())
    }

    @Test fun ocupadoSeReintentaYNoSePierdeNingunBoton() {
        val cola = ColaNotificaciones(maxIntentos = 6)
        // 50 pulsaciones intercaladas con lecturas; el sistema responde «ocupado» 1 de cada 3 veces.
        repeat(50) { cola.encolar(lectura(70 + it % 10)); cola.encolar(boton("toggle")) }
        val entregadas = simular(cola, ocupadoCada = 3)
        assertEquals(50, entregadas.count { it == "toggle" })
    }

    @Test fun trasMaxIntentosSeDescartaYSeAvisa() {
        val cola = ColaNotificaciones(maxIntentos = 2)
        cola.encolar(boton("next", Rol.TV))
        val p = cola.tomar()!!
        assertTrue(cola.reintentar(p))
        val p2 = cola.tomar()!!
        assertFalse("se descarta tras 2 intentos", cola.reintentar(p2))
        assertNull(cola.tomar())
    }

    @Test fun desconexionVaciaSoloEseCentralYDevuelveLosBotones() {
        val cola = ColaNotificaciones()
        cola.encolar(boton("toggle", dir = "C1")); cola.encolar(lectura(70, "C1")); cola.encolar(boton("stop", dir = "C2"))
        val perdidos = cola.vaciar("C1")
        assertEquals(listOf("toggle"), perdidos.map { it.etiqueta })
        assertEquals(1, cola.tamano)
    }

    @Test fun reboteIgnoraLaDoblePulsacion() {
        val r = Rebote(350)
        assertTrue(r.permitir("tv:toggle", 1_000))
        assertFalse("doble disparo de la misma tecla", r.permitir("tv:toggle", 1_100))
        assertTrue("otra tecla no espera", r.permitir("tv:next", 1_100))
        assertTrue(r.permitir("tv:toggle", 1_400))
    }
}
