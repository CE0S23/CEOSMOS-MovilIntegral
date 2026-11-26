package com.ceosmos.companion

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build

/**
 * Pasos de un sensor real de la tablet (1.4.0). Orden de preferencia:
 *  1. TYPE_STEP_COUNTER (contador del sistema; exige ACTIVITY_RECOGNITION en Android 10+).
 *  2. TYPE_STEP_DETECTOR (un evento por paso; mismo permiso).
 *  3. Acelerómetro con [DetectorPasos] (no necesita permiso).
 * El pulso NUNCA viene de un sensor: la tablet no tiene uno, sigue simulado y rotulado.
 */
class SensorPasos(private val contexto: Context, private val alContar: (Int) -> Unit) : SensorEventListener {
    private val gestor = contexto.getSystemService(SensorManager::class.java)
    private var base: Float? = null
    private var detectados = 0
    private val detector = DetectorPasos()
    private var tipo: Int? = null

    /** Empieza a escuchar y devuelve el nombre del sensor usado (null si no hay ninguno). */
    fun iniciar(): String? {
        val elegido = candidatos(contexto).firstOrNull() ?: return null
        val sensor = gestor?.getDefaultSensor(elegido.first) ?: return null
        tipo = elegido.first
        base = null; detectados = 0; detector.reiniciar()
        val ritmo = if (elegido.first == Sensor.TYPE_ACCELEROMETER) SensorManager.SENSOR_DELAY_GAME else SensorManager.SENSOR_DELAY_NORMAL
        return if (gestor.registerListener(this, sensor, ritmo)) elegido.second else null
    }

    fun detener() {
        runCatching { gestor?.unregisterListener(this) }
    }

    override fun onSensorChanged(e: SensorEvent) {
        when (tipo) {
            Sensor.TYPE_STEP_COUNTER -> {
                val b = base ?: e.values[0].also { base = it }
                alContar((e.values[0] - b).toInt().coerceAtLeast(0))
            }
            Sensor.TYPE_STEP_DETECTOR -> alContar(++detectados)
            Sensor.TYPE_ACCELEROMETER -> if (detector.muestra(e.values[0], e.values[1], e.values[2], e.timestamp / 1_000_000)) {
                alContar(detector.pasos)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    companion object {
        private fun permisoActividad(c: Context) =
            Build.VERSION.SDK_INT < 29 || c.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED

        /** Sensores utilizables ahora, en orden de preferencia (tipo, nombre visible). */
        fun candidatos(c: Context): List<Pair<Int, String>> {
            val g = c.getSystemService(SensorManager::class.java) ?: return emptyList()
            return buildList {
                if (permisoActividad(c) && g.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null) add(Sensor.TYPE_STEP_COUNTER to "contador de pasos")
                if (permisoActividad(c) && g.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR) != null) add(Sensor.TYPE_STEP_DETECTOR to "detector de pasos")
                if (g.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null) add(Sensor.TYPE_ACCELEROMETER to "acelerómetro")
            }
        }

        /** Hay contador o detector de pasos en el hardware (sin mirar el permiso). */
        fun tieneSensorDePasos(c: Context): Boolean {
            val g = c.getSystemService(SensorManager::class.java) ?: return false
            return g.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null || g.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR) != null
        }

        fun disponible(c: Context): String? = candidatos(c).firstOrNull()?.second
    }
}
