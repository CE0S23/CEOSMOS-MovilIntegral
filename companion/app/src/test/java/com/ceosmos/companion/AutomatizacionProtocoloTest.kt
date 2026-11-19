package com.ceosmos.companion

import com.ceosmos.companion.ble.Protocolo
import com.ceosmos.companion.ble.Protocolo.Entrante
import com.ceosmos.companion.ble.Protocolo.Rol
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.SecureRandom

/**
 * P13-14 · Pruebas unitarias del protocolo del lado del periférico (Reloj / TV),
 * complementarias a [ProtocoloTest]: entrada válida, vacía, fuera de rango,
 * resultado esperado y manejo de excepciones. Corren en la JVM (sin Bluetooth).
 */
class AutomatizacionProtocoloTest {
    private fun b(j: String) = j.toByteArray(Charsets.UTF_8)

    @Test fun entradaValida_sesionCompletaDeCeosmos() {
        val s = Protocolo.decodificar(
            b("""{"t":"session","state":"paused","title":"Bosque","mode":"calm","rem":120,"tot":1500,"user":"ana"}"""),
            Rol.RELOJ,
        ) as Entrante.Sesion
        assertEquals(Entrante.Sesion("paused", "Bosque", "calm", 120, 1500, null, "ana"), s)
    }

    @Test fun entradaVacia_oCamposVacios_seDescartan() {
        assertNull(Protocolo.decodificar(ByteArray(0), Rol.RELOJ))
        assertNull(Protocolo.decodificar(b("{}"), Rol.RELOJ))
        assertNull(Protocolo.decodificar(b("""{"t":""}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"hello","name":""}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"session"}"""), Rol.TV)) // sin estado ni tiempos
    }

    @Test fun valoresFueraDeRango() {
        // 4 h = 14 400 s es el máximo; 14 401 se rechaza. Tiempos negativos también.
        assertNotNull(Protocolo.decodificar(b("""{"t":"session","state":"running","rem":14400,"tot":14400}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"session","state":"running","rem":14401,"tot":14400}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"session","state":"running","rem":1,"tot":-1}"""), Rol.TV))
        // Pulso fuera de 30..230 no invalida la sesión: solo se omite el dato.
        val s29 = Protocolo.decodificar(b("""{"t":"session","state":"running","rem":1,"tot":1,"hr":29}"""), Rol.TV) as Entrante.Sesion
        val s230 = Protocolo.decodificar(b("""{"t":"session","state":"running","rem":1,"tot":1,"hr":230}"""), Rol.TV) as Entrante.Sesion
        assertNull(s29.hr)
        assertEquals(230, s230.hr)
        // Nombre de 31 caracteres y notificación de 121 → fuera de rango.
        assertNull(Protocolo.decodificar(b("""{"t":"hello","name":"${"n".repeat(31)}"}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"notif","msg":"${"m".repeat(121)}"}"""), Rol.RELOJ))
    }

    @Test fun resultadoEsperado_handshakeCompletoComoLoHaceCeosmos() {
        // El periférico genera un reto aleatorio; CEOSMOS responde HMAC(PIN, reto‖rol).
        val reto = ByteArray(16).also { SecureRandom().nextBytes(it) }
        val respuestaDeCeosmos = Protocolo.hmac("482913", reto, Rol.TV)
        assertEquals(32, respuestaDeCeosmos.size)
        assertTrue(Protocolo.respuestaValida("482913", reto, respuestaDeCeosmos, Rol.TV))
        // La misma respuesta no sirve para otro reto (reto de un solo uso) ni para otro rol.
        val otroReto = reto.copyOf().also { it[0] = (it[0] + 1).toByte() }
        assertFalse(Protocolo.respuestaValida("482913", otroReto, respuestaDeCeosmos, Rol.TV))
        assertFalse(Protocolo.respuestaValida("482913", reto, respuestaDeCeosmos, Rol.RELOJ))
        // Lo que envía el periférico cabe en un mensaje y lo entiende CEOSMOS (campos esperados).
        val lectura = JSONObject(String(Protocolo.lectura(72, 1240)))
        assertEquals(listOf("hr", 72, 1240), listOf(lectura.getString("t"), lectura.getInt("hr"), lectura.getInt("steps")))
        assertTrue(Protocolo.lectura(230, 1_000_000).size <= Protocolo.MAX_BYTES)
    }

    @Test fun manejoDeExcepciones_entradaMaliciosaNoRompeElServidor() {
        // JSON roto, binario arbitrario, UTF-8 inválido o tipos equivocados: null, nunca excepción.
        val basura = listOf(
            b("{"), b("null"), b("[1,2,3]"), byteArrayOf(0xFF.toByte(), 0xFE.toByte(), 0x00),
            b("""{"t":"session","state":"running","rem":"diez","tot":true}"""),
            b("""{"t":"hello","name":{"a":1}}"""),
        )
        basura.forEach { entrada ->
            val r = runCatching { Protocolo.decodificar(entrada, Rol.TV) }
            assertTrue("no debe lanzar con ${String(entrada)}", r.isSuccess)
            assertFalse(r.getOrNull() is Entrante.Sesion)
        }
        // PIN vacío: HMAC con llave vacía lanza IllegalArgumentException en la JVM; el
        // periférico nunca lo usa porque su PIN siempre es de 6 dígitos (pinValido).
        assertFalse(Protocolo.pinValido(""))
        val e = runCatching { Protocolo.hmac("", ByteArray(16), Rol.RELOJ) }.exceptionOrNull()
        assertTrue(e is IllegalArgumentException)
    }
}
