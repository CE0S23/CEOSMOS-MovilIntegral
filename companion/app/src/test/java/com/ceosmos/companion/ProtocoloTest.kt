package com.ceosmos.companion

import com.ceosmos.companion.ble.Protocolo
import com.ceosmos.companion.ble.Protocolo.Entrante
import com.ceosmos.companion.ble.Protocolo.Rol
import org.json.JSONObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** White Box del protocolo del periférico (mismos vectores que la prueba de Dart). */
class ProtocoloTest {
    private fun hex(b: ByteArray) = b.joinToString("") { "%02x".format(it) }
    private val reto = ByteArray(16) { it.toByte() }

    @Test fun uuidsFijosYDistintos() {
        assertEquals("6c3e1000-9b1a-4c5e-8a10-ce05a0b1e000", Rol.RELOJ.servicio.toString())
        assertEquals("6c3e2003-9b1a-4c5e-8a10-ce05a0b1e000", Rol.TV.deDispositivo.toString())
        val todos = Rol.entries.flatMap { listOf(it.servicio, it.auth, it.aDispositivo, it.deDispositivo) }.toSet()
        assertEquals(8, todos.size)
        assertEquals(Rol.TV, Rol.deCaracteristica(Rol.TV.auth))
        assertNull(Rol.deCaracteristica(Protocolo.CCCD))
        assertEquals(listOf(Rol.RELOJ, Rol.TV), Rol.deLista("reloj, tv,otro"))
    }

    @Test fun hmacCompatibleConCeosmos() {
        // Mismo vector calculado con Python/Dart: HMAC-SHA256("123456", 00..0f ‖ rol).
        assertEquals("40f2513526965e935fcefb9697aff28b25ae0b6a218786db3c0dc2502d6bb336", hex(Protocolo.hmac("123456", reto, Rol.RELOJ)))
        assertEquals("847d88dd481248921c75867d220a9ec0d2924909b21a52386bc05ac5bbc152bf", hex(Protocolo.hmac("123456", reto, Rol.TV)))
    }

    @Test fun respuestaSoloValidaConPinRetoYRolCorrectos() {
        val r = Protocolo.hmac("123456", reto, Rol.RELOJ)
        assertTrue(Protocolo.respuestaValida("123456", reto, r, Rol.RELOJ))
        assertFalse(Protocolo.respuestaValida("654321", reto, r, Rol.RELOJ))
        assertFalse(Protocolo.respuestaValida("123456", reto, r, Rol.TV)) // respuesta del reloj no sirve para la TV
        assertFalse(Protocolo.respuestaValida("123456", null, r, Rol.RELOJ)) // sin reto previo (o ya usado)
        assertFalse(Protocolo.respuestaValida("123456", reto.copyOf(15), r, Rol.RELOJ))
        assertFalse(Protocolo.respuestaValida("123456", reto, r.copyOf(31), Rol.RELOJ))
        assertFalse(Protocolo.respuestaValida("123456", reto, ByteArray(0), Rol.RELOJ))
    }

    @Test fun pinValido() {
        assertTrue(Protocolo.pinValido("000000"))
        listOf("", "12345", "1234567", "12a456").forEach { assertFalse(it, Protocolo.pinValido(it)) }
    }

    @Test fun datosDeFabricante() {
        assertArrayEquals(byteArrayOf(1, 0xAB.toByte(), 1, 2, 0xFF.toByte()),
            Protocolo.datosFabricante(Rol.RELOJ, byteArrayOf(0xAB.toByte(), 1, 2, 0xFF.toByte())))
    }

    private fun b(j: String) = j.toByteArray()

    @Test fun decodificaSesionYValidaRangos() {
        val s = Protocolo.decodificar(b("""{"t":"session","state":"running","title":"Órbita","mode":"focus","rem":60,"tot":300,"hr":72,"user":"ana"}"""), Rol.TV) as Entrante.Sesion
        assertEquals("running", s.estado); assertEquals(60, s.restante); assertEquals(72, s.hr)
        assertNull((Protocolo.decodificar(b("""{"t":"session","state":"idle","rem":0,"tot":0,"hr":999}"""), Rol.TV) as Entrante.Sesion).hr)
        assertNull(Protocolo.decodificar(b("""{"t":"session","state":"hack","rem":1,"tot":1}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"session","state":"running","rem":-1,"tot":1}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"session","state":"running","rem":99999,"tot":1}"""), Rol.TV))
    }

    @Test fun notificacionSoloParaElReloj() {
        assertEquals("Hola", (Protocolo.decodificar(b("""{"t":"notif","msg":" Hola "}"""), Rol.RELOJ) as Entrante.Notificacion).texto)
        assertNull(Protocolo.decodificar(b("""{"t":"notif","msg":"Hola"}"""), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"notif","msg":"   "}"""), Rol.RELOJ))
        assertNull(Protocolo.decodificar(b("""{"t":"notif","msg":"${"x".repeat(121)}"}"""), Rol.RELOJ))
    }

    @Test fun entradasInvalidas() {
        assertNull(Protocolo.decodificar(ByteArray(0), Rol.TV))
        assertNull(Protocolo.decodificar(ByteArray(Protocolo.MAX_BYTES + 1) { 0x20 }, Rol.TV))
        assertNull(Protocolo.decodificar(b("{no json"), Rol.TV))
        assertNull(Protocolo.decodificar(b("""{"t":"rm"}"""), Rol.TV))
        assertEquals(Entrante.Adios, Protocolo.decodificar(b("""{"t":"bye"}"""), Rol.TV))
        assertEquals("CEOSMOS", (Protocolo.decodificar(b("""{"t":"hello","name":"CEOSMOS"}"""), Rol.TV) as Entrante.Saludo).nombre)
    }

    @Test fun mensajesSalientesCompatibles() {
        assertEquals("hr", JSONObject(String(Protocolo.lectura(70, 5))).getString("t"))
        assertEquals("toggle", JSONObject(String(Protocolo.boton("toggle"))).getString("a"))
        assertEquals("next", JSONObject(String(Protocolo.comando("next"))).getString("c"))
        assertTrue(Protocolo.saludo("x".repeat(50)).size < Protocolo.MAX_BYTES)
    }
}
