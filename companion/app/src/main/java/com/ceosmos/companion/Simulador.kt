package com.ceosmos.companion

import kotlin.math.sqrt
import kotlin.random.Random

/**
 * Actividad que informa el Reloj en el campo `act` de las lecturas (1.4.0).
 * Los nombres son el contrato con `lib/core/ble/ble_protocolo.dart` (`actividadesReloj`).
 */
enum class Actividad(val clave: String, val nombre: String) {
    REPOSO("reposo", "Reposo"),
    DURMIENDO("durmiendo", "Durmiendo"),
    CAMINANDO("caminando", "Caminando"),
    TROTANDO("trotando", "Trotando"),
    CORRIENDO("corriendo", "Corriendo");

    companion object {
        fun deClave(c: String?): Actividad? = entries.firstOrNull { it.clave == c }
    }
}

/**
 * Modo de simulación del Reloj. Rangos orientativos (no son una referencia médica):
 * pulso en bpm y cadencia en pasos por minuto. Los dos modos de alerta simulan a una
 * persona en reposo con el pulso fuera de lo normal; por eso informan `reposo`.
 */
enum class ModoSimulacion(
    val nombre: String,
    val actividad: Actividad,
    val hrMin: Int,
    val hrMax: Int,
    val cadencia: Int,
    val alerta: Boolean = false,
) {
    REPOSO("Reposo", Actividad.REPOSO, 60, 75, 0),
    DURMIENDO("Durmiendo", Actividad.DURMIENDO, 48, 60, 0),
    CAMINANDO("Caminando", Actividad.CAMINANDO, 85, 105, 100),
    TROTANDO("Trotando", Actividad.TROTANDO, 120, 145, 150),
    CORRIENDO("Corriendo", Actividad.CORRIENDO, 150, 175, 170),
    ALTA("Frecuencia alta", Actividad.REPOSO, 150, 190, 0, alerta = true),
    BAJA("Frecuencia baja", Actividad.REPOSO, 35, 45, 0, alerta = true),
    AUTOMATICO("Automático", Actividad.REPOSO, 60, 75, 0);

    companion object {
        /** Ciclo del modo Automático y segundos en cada etapa. */
        val CICLO = listOf(REPOSO, CAMINANDO, TROTANDO, CORRIENDO, TROTANDO, CAMINANDO)
        const val SEGUNDOS_ETAPA = 30
    }
}

/** Una lectura simulada. */
data class LecturaSimulada(val hr: Int, val pasos: Int, val actividad: Actividad)

/**
 * Generador de lecturas: el pulso avanza hacia un objetivo dentro del rango del modo
 * (como máximo [MAX_CAMBIO_POR_SEG] bpm por segundo) con un ruido leve, y el objetivo
 * cambia cada ~10 s. Los pasos crecen según la cadencia del modo. Siempre en 30–230 bpm.
 */
class Simulador(private val azar: Random = Random.Default, hrInicial: Int = 70) {
    var modo: ModoSimulacion = ModoSimulacion.REPOSO
        private set
    var hr: Double = hrInicial.toDouble()
        private set
    var pasos: Int = 0
        private set
    private var fraccionPasos = 0.0
    private var objetivo = hrInicial.toDouble()
    private var segundosObjetivo = 0.0
    private var segundosEnModo = 0.0

    fun cambiarModo(nuevo: ModoSimulacion) {
        if (nuevo == modo) return
        modo = nuevo
        segundosEnModo = 0.0
        segundosObjetivo = 0.0 // objetivo nuevo en el siguiente paso; la transición es gradual
    }

    /** Perfil vigente: en Automático, la etapa del ciclo según el tiempo transcurrido. */
    fun perfil(): ModoSimulacion {
        if (modo != ModoSimulacion.AUTOMATICO) return modo
        val etapa = (segundosEnModo / ModoSimulacion.SEGUNDOS_ETAPA).toInt() % ModoSimulacion.CICLO.size
        return ModoSimulacion.CICLO[etapa]
    }

    /** Avanza [dt] segundos. Si [pasosReales] no es nulo se usan en lugar de los simulados. */
    fun paso(dt: Double = 1.0, pasosReales: Int? = null): LecturaSimulada {
        segundosEnModo += dt
        val p = perfil()
        segundosObjetivo -= dt
        if (segundosObjetivo <= 0 || objetivo < p.hrMin || objetivo > p.hrMax) {
            objetivo = p.hrMin + azar.nextDouble() * (p.hrMax - p.hrMin)
            segundosObjetivo = 8.0 + azar.nextDouble() * 4.0
        }
        val delta = (objetivo - hr).coerceIn(-MAX_CAMBIO_POR_SEG * dt, MAX_CAMBIO_POR_SEG * dt)
        hr = (hr + delta + (azar.nextDouble() * 2 - 1) * RUIDO).coerceIn(HR_MIN.toDouble(), HR_MAX.toDouble())
        if (pasosReales != null) {
            pasos = pasosReales
        } else if (p.cadencia > 0) {
            // Cadencia ±5 % para que no sea perfectamente regular.
            fraccionPasos += p.cadencia / 60.0 * dt * (0.95 + azar.nextDouble() * 0.1)
            val enteros = fraccionPasos.toInt()
            pasos += enteros
            fraccionPasos -= enteros
        }
        return LecturaSimulada(hr.toInt().coerceIn(HR_MIN, HR_MAX), pasos, p.actividad)
    }

    companion object {
        const val HR_MIN = 30
        const val HR_MAX = 230
        const val MAX_CAMBIO_POR_SEG = 4.0
        const val RUIDO = 1.0
    }
}

/**
 * Detector de pasos con el acelerómetro (respaldo si no hay contador de pasos):
 * cuenta un paso en cada pico de la magnitud que supera [umbral] m/s² tras haber
 * bajado de la gravedad, con al menos [refractarioMs] entre pasos.
 */
class DetectorPasos(private val umbral: Double = 11.8, private val refractarioMs: Long = 280) {
    var pasos = 0
        private set
    private var armado = true
    private var ultimo = Long.MIN_VALUE / 2

    fun muestra(x: Float, y: Float, z: Float, tMs: Long): Boolean {
        val m = sqrt((x * x + y * y + z * z).toDouble())
        if (m < GRAVEDAD + 0.3) armado = true
        if (armado && m > umbral && tMs - ultimo >= refractarioMs) {
            armado = false
            ultimo = tMs
            pasos++
            return true
        }
        return false
    }

    fun reiniciar() {
        pasos = 0; armado = true; ultimo = Long.MIN_VALUE / 2
    }

    companion object {
        const val GRAVEDAD = 9.81
    }
}
