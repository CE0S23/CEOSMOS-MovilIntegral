package com.ceosmos.companion

import com.ceosmos.companion.ble.Protocolo
import com.ceosmos.companion.ble.Protocolo.Entrante
import com.ceosmos.companion.ble.Protocolo.Rol
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/** 1.4.0 · Perfiles de simulación, campo `act` del protocolo y detector de pasos. */
class SimuladorTest {
    /** Lleva el simulador a régimen y devuelve las lecturas de los [n] segundos siguientes. */
    private fun regimen(modo: ModoSimulacion, n: Int = 120, semilla: Int = 7): List<LecturaSimulada> {
        val s = Simulador(Random(semilla))
        s.cambiarModo(modo)
        repeat(90) { s.paso() } // transición gradual hasta el rango
        return List(n) { s.paso() }
    }

    @Test fun cadaModoQuedaEnSuRangoConMargenDeRuido() {
        ModoSimulacion.entries.filter { it != ModoSimulacion.AUTOMATICO }.forEach { m ->
            val l = regimen(m)
            l.forEach { assertTrue("${m.nombre}: ${it.hr}", it.hr in (m.hrMin - 3)..(m.hrMax + 3)) }
            assertTrue(l.all { it.actividad == m.actividad })
        }
    }

    @Test fun siempreDentroDe30a230() {
        ModoSimulacion.entries.forEach { m -> regimen(m, 300, semilla = 3).forEach { assertTrue(it.hr in 30..230) } }
    }

    @Test fun cadenciaDePasosRealista() {
        fun pasosPorMinuto(m: ModoSimulacion): Int {
            val l = regimen(m, 60)
            return l.last().pasos - l.first().pasos
        }
        assertEquals(0, pasosPorMinuto(ModoSimulacion.DURMIENDO))
        assertEquals(0, pasosPorMinuto(ModoSimulacion.REPOSO))
        assertTrue(pasosPorMinuto(ModoSimulacion.CAMINANDO) in 85..110)
        assertTrue(pasosPorMinuto(ModoSimulacion.TROTANDO) in 135..160)
        assertTrue(pasosPorMinuto(ModoSimulacion.CORRIENDO) in 155..180)
    }

    @Test fun transicionGradualSinSaltos() {
        val s = Simulador(Random(1), hrInicial = 65)
        s.cambiarModo(ModoSimulacion.CORRIENDO)
        var previo = 65
        repeat(40) {
            val l = s.paso()
            assertTrue("salto de $previo a ${l.hr}", kotlin.math.abs(l.hr - previo) <= (Simulador.MAX_CAMBIO_POR_SEG + Simulador.RUIDO + 1).toInt())
            previo = l.hr
        }
    }

    @Test fun automaticoRecorreElCiclo() {
        val s = Simulador(Random(5))
        s.cambiarModo(ModoSimulacion.AUTOMATICO)
        val vistas = mutableSetOf<Actividad>()
        repeat(ModoSimulacion.CICLO.size * ModoSimulacion.SEGUNDOS_ETAPA) { vistas += s.paso().actividad }
        assertEquals(setOf(Actividad.REPOSO, Actividad.CAMINANDO, Actividad.TROTANDO, Actividad.CORRIENDO), vistas)
    }

    @Test fun pasosRealesSustituyenALosSimulados() {
        val s = Simulador(Random(2))
        s.cambiarModo(ModoSimulacion.CORRIENDO)
        assertEquals(42, s.paso(1.0, pasosReales = 42).pasos)
    }

    @Test fun lecturaLlevaActividadYCabeEn180Bytes() {
        val b = Protocolo.lectura(230, 1_000_000, "durmiendo")
        val j = JSONObject(String(b))
        assertEquals("durmiendo", j.getString("act"))
        assertTrue(b.size <= Protocolo.MAX_BYTES)
        // Sin actividad el mensaje es el de siempre (compatible con CEOSMOS 1.3).
        assertFalse(JSONObject(String(Protocolo.lectura(70, 10))).has("act"))
        // Fuera de rango se acota a 30–230.
        assertEquals(230, JSONObject(String(Protocolo.lectura(400, 0))).getInt("hr"))
    }

    @Test fun alertaSeDecodificaEnRelojYTv() {
        val m = """{"t":"alert","lvl":"urgente","msg":"Pulso muy alto: 192 bpm"}""".toByteArray()
        assertEquals(Entrante.Alerta("Pulso muy alto: 192 bpm", "urgente"), Protocolo.decodificar(m, Rol.RELOJ))
        assertEquals(Entrante.Alerta("Pulso muy alto: 192 bpm", "urgente"), Protocolo.decodificar(m, Rol.TV))
        assertNull(Protocolo.decodificar("""{"t":"alert","lvl":"otro","msg":"x"}""".toByteArray(), Rol.TV))
        assertNull(Protocolo.decodificar("""{"t":"alert","msg":""}""".toByteArray(), Rol.RELOJ))
    }

    @Test fun detectorDePasosCuentaPicosConRefractario() {
        val d = DetectorPasos()
        var t = 0L
        repeat(10) {
            d.muestra(0f, 0f, 9.8f, t); t += 100
            d.muestra(0f, 0f, 13f, t); t += 100 // pico
            d.muestra(0f, 0f, 13f, t); t += 100 // mismo pico: no cuenta
        }
        assertEquals(10, d.pasos)
        // En reposo (solo gravedad) no cuenta nada.
        val quieto = DetectorPasos()
        repeat(100) { quieto.muestra(0f, 0f, 9.81f, it * 20L) }
        assertEquals(0, quieto.pasos)
    }
}
