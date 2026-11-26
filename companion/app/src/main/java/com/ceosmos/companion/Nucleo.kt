package com.ceosmos.companion

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.ceosmos.companion.ble.Protocolo
import com.ceosmos.companion.ble.Protocolo.Rol
import com.ceosmos.companion.ble.ServidorGatt
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.security.SecureRandom
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Estado que observa la interfaz. */
data class Estado(
    val roles: List<Rol> = emptyList(),
    val pin: String = "------",
    val id: String = "",
    val activo: Boolean = false,
    val anunciando: Set<Rol> = emptySet(),
    val conectados: Int = 0,
    val autenticado: Set<Rol> = emptySet(),
    val suscrito: Set<Rol> = emptySet(),
    val error: String? = null,
    val bloqueos: Int = 0,
    val multiAnuncio: Boolean = true,
    val nombreCentral: String? = null,
    val hr: Int = 72,
    val pasos: Int = 0,
    val simulando: Boolean = true,
    /** 1.4.0: modo de simulación elegido y actividad que se informa en `act`. */
    val modo: ModoSimulacion = ModoSimulacion.REPOSO,
    val actividad: Actividad = Actividad.REPOSO,
    /** Origen de los pasos: simulados o un sensor real de la tablet. */
    val pasosReales: Boolean = false,
    val sensorPasos: String? = null,
    /** Último botón/tecla: texto, si sigue en curso y si llegó (feedback visible). */
    val envio: Envio? = null,
    /** Última alerta de salud recibida de CEOSMOS. */
    val alerta: String? = null,
    val alertaUrgente: Boolean = false,
    val notificaciones: List<String> = emptyList(),
    val sesion: Protocolo.Entrante.Sesion? = null,
    val registro: List<String> = emptyList(),
)

/** Resultado visible de un botón del Reloj o una tecla de la TV. */
data class Envio(val comando: String, val estado: EstadoEnvio, val instante: Long = System.currentTimeMillis())

enum class EstadoEnvio { ENVIANDO, ENTREGADO, FALLIDO, SIN_CEOSMOS }

/** Texto legible de cada comando (feedback en pantalla). */
fun nombreComando(c: String) = when (c) {
    "toggle" -> "Pausar / reanudar"
    "stop" -> "Terminar"
    "next" -> "Siguiente"
    "prev" -> "Anterior"
    else -> c
}

/**
 * Núcleo del compañero: PIN e id persistentes, servidor GATT, simulación de
 * lecturas del reloj y envío de comandos. Lo usa [ServicioCompanion] (primer
 * plano, sigue anunciando con la app en segundo plano) y la interfaz.
 */
object Nucleo : ServidorGatt.Oyente {
    private val _estado = MutableStateFlow(Estado())
    val estado: StateFlow<Estado> = _estado
    private var servidor: ServidorGatt? = null
    private lateinit var app: Context
    private val main = Handler(Looper.getMainLooper())
    private val hora = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    private var pinActual = ""
    private val simulador = Simulador()
    private val rebote = com.ceosmos.companion.ble.Rebote(REBOTE_MS)
    private var sensores: SensorPasos? = null
    private var simuladorPasosReales: Int? = null

    /** Rebote: la misma tecla repetida en menos de este tiempo se ignora (doble disparo). */
    const val REBOTE_MS = 350L

    val roles: List<Rol> = Rol.deLista(BuildConfig.ROLES)

    fun preparar(contexto: Context) {
        if (::app.isInitialized) return
        app = contexto.applicationContext
        val prefs = app.getSharedPreferences("companion", Context.MODE_PRIVATE)
        pinActual = prefs.getString("pin", null) ?: nuevoPin().also { prefs.edit().putString("pin", it).apply() }
        val id = prefs.getString("id", null) ?: ByteArray(4).also { SecureRandom().nextBytes(it) }
            .joinToString("") { "%02x".format(it) }.also { prefs.edit().putString("id", it).apply() }
        _estado.value = _estado.value.copy(roles = roles, pin = pinActual, id = id)
    }

    private fun nuevoPin() = (SecureRandom().nextInt(900_000) + 100_000).toString()

    /** Revoca el acceso: PIN nuevo y se desconecta a todos los centrales. */
    fun regenerarPin() {
        pinActual = nuevoPin()
        app.getSharedPreferences("companion", Context.MODE_PRIVATE).edit().putString("pin", pinActual).apply()
        _estado.value = _estado.value.copy(pin = pinActual)
        reiniciar()
        registro("PIN regenerado: los centrales deben volver a autenticarse")
    }

    @Synchronized
    fun iniciarServidor() {
        if (servidor != null) return
        val idBytes = _estado.value.id.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
        servidor = ServidorGatt(app, roles, idBytes, { pinActual }, this).also { it.iniciar() }
        _estado.value = _estado.value.copy(activo = true)
        programarSimulacion()
        alCambiar()
    }

    @Synchronized
    fun detenerServidor() {
        servidor?.detener()
        servidor = null
        main.removeCallbacksAndMessages(null)
        _estado.value = _estado.value.copy(activo = false, anunciando = emptySet(), conectados = 0, autenticado = emptySet(), suscrito = emptySet())
    }

    fun reiniciar() {
        detenerServidor()
        iniciarServidor()
    }

    fun alternarSimulacion() {
        _estado.value = _estado.value.copy(simulando = !_estado.value.simulando)
    }

    /** Cambia el modo de simulación (la transición del pulso es gradual). */
    fun elegirModo(modo: ModoSimulacion) {
        simulador.cambiarModo(modo)
        _estado.value = _estado.value.copy(modo = modo, actividad = simulador.perfil().actividad)
        registro("Simulación: ${modo.nombre}")
    }

    /** Qué sensor de pasos tiene el equipo (null = ninguno: solo simulación). */
    fun sensorDisponible(): String? = SensorPasos.disponible(app)

    /** Activa o desactiva los pasos del sensor real (el pulso sigue simulado). */
    fun usarPasosReales(activar: Boolean) {
        sensores?.detener()
        sensores = null
        simuladorPasosReales = null
        if (!activar) {
            _estado.value = _estado.value.copy(pasosReales = false, sensorPasos = null)
            return
        }
        val s = SensorPasos(app) { pasos -> main.post { simuladorPasosReales = pasos } }
        val tipo = s.iniciar()
        if (tipo == null) {
            _estado.value = _estado.value.copy(pasosReales = false, sensorPasos = null)
            registro("Sin sensor de pasos: se mantiene la simulación")
            return
        }
        sensores = s
        simuladorPasosReales = 0
        _estado.value = _estado.value.copy(pasosReales = true, sensorPasos = tipo)
        registro("Pasos del sensor real ($tipo)")
    }

    /** Botón de acción del reloj o tecla del control de la TV (con rebote y feedback). */
    fun enviarComando(rol: Rol, comando: String): Boolean {
        if (!rebote.permitir("${rol.etiqueta}:$comando", System.currentTimeMillis())) return false
        val bytes = if (rol == Rol.RELOJ) Protocolo.boton(comando) else Protocolo.comando(comando)
        val n = servidor?.notificar(rol, bytes, etiqueta = comando) ?: 0
        _estado.value = _estado.value.copy(envio = Envio(comando, if (n > 0) EstadoEnvio.ENVIANDO else EstadoEnvio.SIN_CEOSMOS))
        registro(if (n > 0) "${rol.nombre} → CEOSMOS: $comando" else "Sin CEOSMOS conectado: «$comando» no se envió")
        return n > 0
    }

    override fun alEntregar(rol: Rol, etiqueta: String?, ok: Boolean) {
        if (etiqueta == null) return
        main.post {
            val actual = _estado.value.envio
            // Línea para scripts/medir_botones.sh (latencia pulsación → confirmación GATT).
            if (actual?.comando == etiqueta) {
                Log.i(ServidorGatt.TAG, "MEDICION ${rol.etiqueta} $etiqueta ${if (ok) "ok" else "fallo"} ${System.currentTimeMillis() - actual.instante} ms")
            }
            if (actual?.comando == etiqueta) {
                _estado.value = _estado.value.copy(envio = actual.copy(estado = if (ok) EstadoEnvio.ENTREGADO else EstadoEnvio.FALLIDO))
            }
            if (!ok) registro("${rol.nombre}: «$etiqueta» no llegó a CEOSMOS")
        }
    }

    private fun programarSimulacion() {
        main.postDelayed(object : Runnable {
            override fun run() {
                val s = servidor ?: return
                val e = _estado.value
                if (Rol.RELOJ in roles && e.simulando) {
                    // Lectura simulada cada segundo según el modo (pulso SIMULADO, no médico).
                    val l = simulador.paso(1.0, simuladorPasosReales)
                    _estado.value = e.copy(hr = l.hr, pasos = l.pasos, actividad = l.actividad)
                    if (s.suscrito(Rol.RELOJ)) s.notificar(Rol.RELOJ, Protocolo.lectura(l.hr, l.pasos, l.actividad.clave))
                }
                main.postDelayed(this, 1000)
            }
        }, 1000)
    }

    // ---- ServidorGatt.Oyente ----

    override fun alCambiar() {
        val s = servidor
        _estado.value = _estado.value.copy(
            anunciando = s?.anunciando?.toSet() ?: emptySet(),
            conectados = s?.conectados() ?: 0,
            autenticado = roles.filter { s?.autenticado(it) == true }.toSet(),
            suscrito = roles.filter { s?.suscrito(it) == true }.toSet(),
            error = s?.error,
            bloqueos = s?.bloqueos() ?: 0,
            multiAnuncio = s?.multiAnuncio ?: true,
        )
    }

    override fun alRecibir(rol: Rol, mensaje: Protocolo.Entrante) {
        main.post {
            val e = _estado.value
            _estado.value = when (mensaje) {
                is Protocolo.Entrante.Saludo -> e.copy(nombreCentral = mensaje.nombre)
                is Protocolo.Entrante.Adios -> e.copy(nombreCentral = null)
                is Protocolo.Entrante.Notificacion -> e.copy(
                    notificaciones = (listOf("${hora.format(Date())}  ${mensaje.texto}") + e.notificaciones).take(5)
                )
                is Protocolo.Entrante.Sesion -> e.copy(sesion = mensaje)
                is Protocolo.Entrante.Alerta -> e.copy(alerta = "${hora.format(Date())}  ${mensaje.texto}", alertaUrgente = mensaje.nivel == "urgente")
            }
            if (mensaje is Protocolo.Entrante.Notificacion) vibrar()
            if (mensaje is Protocolo.Entrante.Alerta && rol == Rol.RELOJ) vibrar(patron = true)
            registro("CEOSMOS → ${rol.nombre}: ${mensaje::class.simpleName}")
        }
    }

    override fun registro(texto: String) {
        // Solo eventos: nunca PIN, retos, respuestas ni contenido de mensajes.
        Log.i(ServidorGatt.TAG, texto)
        main.post {
            _estado.value = _estado.value.copy(registro = (listOf("${hora.format(Date())}  $texto") + _estado.value.registro).take(30))
        }
    }

    /** Descarta la alerta visible (botón «Entendido»). */
    fun descartarAlerta() {
        _estado.value = _estado.value.copy(alerta = null, alertaUrgente = false)
    }

    @SuppressLint("MissingPermission")
    private fun vibrar(patron: Boolean = false) {
        runCatching {
            val v = app.getSystemService(android.os.Vibrator::class.java)
            v?.vibrate(
                if (patron) android.os.VibrationEffect.createWaveform(longArrayOf(0, 300, 150, 300, 150, 300), -1)
                else android.os.VibrationEffect.createOneShot(200, android.os.VibrationEffect.DEFAULT_AMPLITUDE)
            )
        }
    }
}

/**
 * Servicio en primer plano (tipo connectedDevice): mantiene el servidor GATT y el
 * anuncio aunque la app pase a segundo plano. Reinicia el servidor si el Bluetooth
 * se apaga y se vuelve a encender.
 */
class ServicioCompanion : Service() {
    private val receptor = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            when (i.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)) {
                BluetoothAdapter.STATE_ON -> Nucleo.reiniciar()
                BluetoothAdapter.STATE_TURNING_OFF, BluetoothAdapter.STATE_OFF -> {
                    Nucleo.detenerServidor()
                    Nucleo.registro("Bluetooth apagado: se reanudará al encenderlo")
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Nucleo.preparar(this)
        val canal = NotificationChannel("companion", "Conexión con CEOSMOS", NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
        val abrir = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE,
        )
        val n: Notification = NotificationCompat.Builder(this, "companion")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentTitle(getString(R.string.app_name))
            .setContentText("Esperando a CEOSMOS por Bluetooth LE")
            .setContentIntent(abrir)
            .setOngoing(true)
            .build()
        ServiceCompat.startForeground(
            this, 7, n,
            if (Build.VERSION.SDK_INT >= 29) ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE else 0,
        )
        registerReceiver(receptor, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Nucleo.iniciarServidor()
        return START_STICKY
    }

    override fun onDestroy() {
        runCatching { unregisterReceiver(receptor) }
        Nucleo.detenerServidor()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
