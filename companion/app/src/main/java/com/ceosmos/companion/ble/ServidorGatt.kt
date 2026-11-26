package com.ceosmos.companion.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import com.ceosmos.companion.ble.Protocolo.Rol
import java.security.SecureRandom
import java.util.concurrent.ConcurrentHashMap

/**
 * Periférico BLE: servidor GATT + anuncio para uno o dos roles (Reloj / TV).
 *
 * Seguridad (lo comprueba el servidor, no la interfaz):
 *  - Sin autenticación por reto/HMAC no se aceptan escrituras ni suscripciones.
 *  - El reto es aleatorio (SecureRandom), de un solo uso y por conexión.
 *  - 3 respuestas erróneas → se corta el enlace y se bloquea esa dirección 60 s.
 *  - Un central que no se autentica en 30 s se desconecta.
 *  - Cada mensaje se valida (tamaño, JSON, tipo y rangos) antes de usarse.
 *  - En el registro (Logcat) nunca se escriben el PIN, los retos ni las respuestas.
 */
@SuppressLint("MissingPermission") // la actividad pide los permisos antes de iniciar el servicio
class ServidorGatt(
    private val contexto: Context,
    val roles: List<Rol>,
    private val idEstable: ByteArray,
    private val pin: () -> String,
    private val oyente: Oyente,
) {
    interface Oyente {
        fun alCambiar()
        fun alRecibir(rol: Rol, mensaje: Protocolo.Entrante)
        fun registro(texto: String)

        /** Resultado final de una notificación con [etiqueta] (botón o tecla); null = lectura. */
        fun alEntregar(rol: Rol, etiqueta: String?, ok: Boolean) {}
    }

    /** 1.4.0: una notificación en vuelo a la vez (ver [ColaNotificaciones]); solo en el hilo principal. */
    private val cola = ColaNotificaciones(MAX_INTENTOS_NOTIFICACION)
    private val vencida = Runnable { terminarEnVuelo(ok = true, motivo = "sin confirmación a tiempo") }

    private val manager = contexto.getSystemService(BluetoothManager::class.java)
    private var servidor: BluetoothGattServer? = null
    private val pendientes = ArrayDeque<BluetoothGattService>()
    private val anuncios = mutableMapOf<Rol, AdvertiseCallback>()
    private val azar = SecureRandom()
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    private data class Clave(val direccion: String, val rol: Rol)

    private val conectados = ConcurrentHashMap<String, BluetoothDevice>()
    private val retos = ConcurrentHashMap<Clave, ByteArray>()
    private val autenticados = ConcurrentHashMap.newKeySet<Clave>()
    private val suscritos = ConcurrentHashMap.newKeySet<Clave>()
    private val fallos = ConcurrentHashMap<String, Int>()
    private val bloqueados = ConcurrentHashMap<String, Long>()
    private val escriturasLargas = ConcurrentHashMap<Pair<String, java.util.UUID>, ByteArray>()

    val anunciando = ConcurrentHashMap.newKeySet<Rol>()
    var error: String? = null
        private set
    var multiAnuncio: Boolean = true
        private set

    fun conectados(): Int = conectados.size
    fun autenticado(rol: Rol) = autenticados.any { it.rol == rol }
    fun suscrito(rol: Rol) = suscritos.any { it.rol == rol }
    fun bloqueos(): Int = bloqueados.count { it.value > System.currentTimeMillis() }

    fun iniciar() {
        val adaptador = manager.adapter
        if (adaptador == null || !adaptador.isEnabled) {
            error = "Bluetooth apagado"
            oyente.alCambiar()
            return
        }
        error = null
        multiAnuncio = adaptador.isMultipleAdvertisementSupported
        servidor = manager.openGattServer(contexto, callback)
        if (servidor == null) {
            error = "No se pudo abrir el servidor GATT"
            oyente.alCambiar()
            return
        }
        pendientes.clear()
        roles.forEach { pendientes.add(crearServicio(it)) }
        agregarSiguiente()
    }

    fun detener() {
        val adv = manager.adapter?.bluetoothLeAdvertiser
        anuncios.values.forEach { runCatching { adv?.stopAdvertising(it) } }
        anuncios.clear()
        anunciando.clear()
        handler.post { vaciarColas() }
        conectados.values.forEach { runCatching { servidor?.cancelConnection(it) } }
        runCatching { servidor?.close() }
        servidor = null
        conectados.clear(); retos.clear(); autenticados.clear(); suscritos.clear()
        oyente.alCambiar()
    }

    /**
     * Encola [bytes] por notificación para cada central autenticado y suscrito al rol y
     * devuelve cuántos destinatarios hay. Con [etiqueta] (botón/tecla) va por la cola
     * prioritaria y el resultado llega en [Oyente.alEntregar]; sin ella es una lectura y
     * sustituye a la lectura anterior aún no enviada (no se acumula atraso).
     */
    fun notificar(rol: Rol, bytes: ByteArray, etiqueta: String? = null): Int {
        if (servidor == null) return 0
        val destinos = suscritos.filter { it.rol == rol && it in autenticados && conectados.containsKey(it.direccion) }
        handler.post {
            for (clave in destinos) cola.encolar(ColaNotificaciones.Pendiente(clave.direccion, rol, bytes, etiqueta))
            bombear()
        }
        return destinos.size
    }

    /** Envía la siguiente notificación si no hay otra en vuelo (siempre en el hilo principal). */
    private fun bombear() {
        val p = cola.tomar() ?: return
        val s = servidor
        val d = conectados[p.direccion]
        val c = s?.getService(p.rol.servicio)?.getCharacteristic(p.rol.deDispositivo)
        if (s == null || d == null || c == null) {
            if (p.etiqueta != null) oyente.alEntregar(p.rol, p.etiqueta, false)
            bombear()
            return
        }
        val estado = if (Build.VERSION.SDK_INT >= 33) {
            // P13-14 (lint WrongConstant): esta sobrecarga devuelve BluetoothStatusCodes, no GATT_*.
            s.notifyCharacteristicChanged(d, c, false, p.bytes)
        } else {
            @Suppress("DEPRECATION")
            c.value = p.bytes
            @Suppress("DEPRECATION")
            if (s.notifyCharacteristicChanged(d, c, false)) BluetoothStatusCodes.SUCCESS else ERROR_OCUPADO
        }
        if (estado == BluetoothStatusCodes.SUCCESS) {
            cola.enviada(p)
            handler.postDelayed(vencida, ESPERA_CONFIRMACION_MS)
        } else if (cola.reintentar(p)) {
            // Ocupado: se reintenta en breve sin perder el orden.
            handler.postDelayed({ bombear() }, REINTENTO_MS)
        } else {
            oyente.registro("Notificación descartada tras ${com.ceosmos.companion.Plural.contar(p.intentos, "intento", "intentos")} (estado $estado)")
            if (p.etiqueta != null) oyente.alEntregar(p.rol, p.etiqueta, false)
            bombear()
        }
    }

    private fun terminarEnVuelo(ok: Boolean, motivo: String? = null) {
        val p = cola.confirmar() ?: return
        handler.removeCallbacks(vencida)
        // Error en la confirmación: vuelve al frente de su cola (si quedan intentos).
        val reintenta = !ok && conectados.containsKey(p.direccion) && cola.reintentar(p)
        if (!reintenta) {
            if (motivo != null) oyente.registro("Notificación: $motivo")
            if (p.etiqueta != null) oyente.alEntregar(p.rol, p.etiqueta, ok)
        }
        bombear()
    }

    private fun vaciarColas(direccion: String? = null) {
        val habiaEnVuelo = cola.enVuelo
        val conEtiqueta = cola.vaciar(direccion)
        if (habiaEnVuelo != null && cola.enVuelo == null) handler.removeCallbacks(vencida)
        conEtiqueta.forEach { oyente.alEntregar(it.rol, it.etiqueta, false) }
    }

    // ------------------------------------------------------------------

    private fun crearServicio(rol: Rol): BluetoothGattService {
        val servicio = BluetoothGattService(rol.servicio, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        servicio.addCharacteristic(
            BluetoothGattCharacteristic(
                rol.auth,
                BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_WRITE,
                BluetoothGattCharacteristic.PERMISSION_READ or BluetoothGattCharacteristic.PERMISSION_WRITE,
            )
        )
        servicio.addCharacteristic(
            BluetoothGattCharacteristic(
                rol.aDispositivo,
                BluetoothGattCharacteristic.PROPERTY_WRITE,
                BluetoothGattCharacteristic.PERMISSION_WRITE,
            )
        )
        val notif = BluetoothGattCharacteristic(
            rol.deDispositivo,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ,
        )
        notif.addDescriptor(
            BluetoothGattDescriptor(
                Protocolo.CCCD,
                BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE,
            )
        )
        servicio.addCharacteristic(notif)
        return servicio
    }

    /** Android solo admite agregar un servicio a la vez: se espera onServiceAdded. */
    private fun agregarSiguiente() {
        val s = pendientes.removeFirstOrNull() ?: return
        if (servidor?.addService(s) != true) {
            error = "No se pudo registrar el servicio ${s.uuid}"
            oyente.alCambiar()
        }
    }

    private fun anunciar(rol: Rol) {
        val adv = manager.adapter?.bluetoothLeAdvertiser
        if (adv == null) {
            error = "Este equipo no puede anunciar por BLE"
            oyente.alCambiar()
            return
        }
        val ajustes = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .setTimeout(0)
            .build()
        // 31 bytes por paquete: el UUID de 128 bits va en el anuncio y el id en la respuesta de escaneo.
        val datos = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(rol.servicio))
            .build()
        val respuesta = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addManufacturerData(Protocolo.FABRICANTE, Protocolo.datosFabricante(rol, idEstable))
            .build()
        val cb = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                anunciando.add(rol)
                oyente.registro("Anunciando servicio ${rol.nombre}")
                oyente.alCambiar()
            }

            override fun onStartFailure(errorCode: Int) {
                anunciando.remove(rol)
                error = "No se pudo anunciar ${rol.nombre} (código $errorCode" +
                    (if (errorCode == ADVERTISE_FAILED_TOO_MANY_ADVERTISERS) ": demasiados anunciantes" else "") + ")"
                oyente.registro(error!!)
                oyente.alCambiar()
            }
        }
        anuncios[rol] = cb
        adv.startAdvertising(ajustes, datos, respuesta, cb)
    }

    private fun bloqueado(d: BluetoothDevice): Boolean = (bloqueados[d.address] ?: 0) > System.currentTimeMillis()

    private fun responder(d: BluetoothDevice, id: Int, estado: Int, offset: Int, valor: ByteArray?, necesita: Boolean) {
        if (necesita) servidor?.sendResponse(d, id, estado, offset, valor)
    }

    private fun procesarEscritura(d: BluetoothDevice, uuid: java.util.UUID, valor: ByteArray): Int {
        val rol = Protocolo.Rol.deCaracteristica(uuid) ?: return BluetoothGatt.GATT_FAILURE
        if (rol !in roles) return BluetoothGatt.GATT_FAILURE
        val clave = Clave(d.address, rol)
        if (bloqueado(d)) return Protocolo.GATT_SIN_AUTORIZACION
        return when (uuid) {
            rol.auth -> {
                val reto = retos.remove(clave) // de un solo uso
                if (Protocolo.respuestaValida(pin(), reto, valor, rol)) {
                    autenticados.add(clave)
                    fallos.remove(d.address)
                    oyente.registro("Central autenticado para ${rol.nombre}")
                    oyente.alCambiar()
                    BluetoothGatt.GATT_SUCCESS
                } else {
                    val n = (fallos[d.address] ?: 0) + 1
                    fallos[d.address] = n
                    oyente.registro("Autenticación rechazada para ${rol.nombre} (intento $n de ${Protocolo.MAX_FALLOS})")
                    if (n >= Protocolo.MAX_FALLOS) {
                        bloqueados[d.address] = System.currentTimeMillis() + Protocolo.BLOQUEO_MS
                        fallos.remove(d.address)
                        oyente.registro("Dirección bloqueada 60 s por intentos fallidos")
                        servidor?.cancelConnection(d)
                    }
                    oyente.alCambiar()
                    Protocolo.GATT_SIN_AUTORIZACION
                }
            }
            rol.aDispositivo -> {
                if (clave !in autenticados) {
                    oyente.registro("Escritura rechazada: central no autenticado")
                    return Protocolo.GATT_SIN_AUTORIZACION
                }
                val m = Protocolo.decodificar(valor, rol)
                if (m == null) {
                    oyente.registro("Mensaje inválido descartado (${valor.size} bytes)")
                    Protocolo.GATT_ERROR_APLICACION
                } else {
                    oyente.alRecibir(rol, m)
                    BluetoothGatt.GATT_SUCCESS
                }
            }
            else -> BluetoothGatt.GATT_FAILURE
        }
    }

    private val callback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService) {
            val rol = Rol.deServicio(service.uuid)
            if (status == BluetoothGatt.GATT_SUCCESS && rol != null) anunciar(rol)
            else error = "Servicio no agregado (estado $status)"
            agregarSiguiente()
            oyente.alCambiar()
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                if (bloqueado(device)) {
                    servidor?.cancelConnection(device)
                    return
                }
                conectados[device.address] = device
                oyente.registro("Central conectado")
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                conectados.remove(device.address)
                handler.post { vaciarColas(device.address) }
                roles.forEach {
                    val c = Clave(device.address, it)
                    retos.remove(c); autenticados.remove(c); suscritos.remove(c)
                }
                oyente.registro("Central desconectado")
            }
            oyente.alCambiar()
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            handler.post {
                if (cola.enVuelo?.direccion == device.address) terminarEnVuelo(status == BluetoothGatt.GATT_SUCCESS)
            }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            oyente.registro("MTU $mtu")
        }

        override fun onCharacteristicReadRequest(device: BluetoothDevice, requestId: Int, offset: Int, c: BluetoothGattCharacteristic) {
            val rol = Rol.deCaracteristica(c.uuid)
            if (rol == null || rol !in roles || c.uuid != rol.auth) {
                servidor?.sendResponse(device, requestId, BluetoothGatt.GATT_READ_NOT_PERMITTED, offset, null)
                return
            }
            if (bloqueado(device)) {
                servidor?.sendResponse(device, requestId, Protocolo.GATT_SIN_AUTORIZACION, offset, null)
                return
            }
            val clave = Clave(device.address, rol)
            val reto = if (offset == 0) ByteArray(16).also { azar.nextBytes(it); retos[clave] = it } else retos[clave]
            if (offset == 0) {
                // Quien pidió un reto tiene 30 s para responderlo; si no, se corta el enlace.
                // (Un central que solo usa el otro rol de la tablet no se ve afectado.)
                handler.postDelayed({
                    if (conectados.containsKey(device.address) && clave !in autenticados) {
                        oyente.registro("Central sin autenticar a tiempo: desconectado")
                        servidor?.cancelConnection(device)
                    }
                }, Protocolo.LIMITE_AUTENTICACION_MS)
            }
            if (reto == null || offset > reto.size) {
                servidor?.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset, null)
                return
            }
            servidor?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, reto.copyOfRange(offset, reto.size))
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice, requestId: Int, c: BluetoothGattCharacteristic,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?,
        ) {
            val v = value ?: ByteArray(0)
            if (preparedWrite) { // escritura larga (MTU pequeño): se junta hasta onExecuteWrite
                val k = device.address to c.uuid
                val previo = escriturasLargas[k] ?: ByteArray(0)
                if (offset != previo.size || previo.size + v.size > Protocolo.MAX_BYTES) {
                    escriturasLargas.remove(k)
                    responder(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset, null, responseNeeded)
                    return
                }
                escriturasLargas[k] = previo + v
                responder(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, v, responseNeeded)
                return
            }
            responder(device, requestId, procesarEscritura(device, c.uuid, v), offset, null, responseNeeded)
        }

        override fun onExecuteWrite(device: BluetoothDevice, requestId: Int, execute: Boolean) {
            val propias = escriturasLargas.keys.filter { it.first == device.address }
            var estado = BluetoothGatt.GATT_SUCCESS
            for (k in propias) {
                val datos = escriturasLargas.remove(k) ?: continue
                if (execute) estado = procesarEscritura(device, k.second, datos)
            }
            servidor?.sendResponse(device, requestId, estado, 0, null)
        }

        override fun onDescriptorReadRequest(device: BluetoothDevice, requestId: Int, offset: Int, d: BluetoothGattDescriptor) {
            val rol = Rol.deCaracteristica(d.characteristic.uuid)
            val activo = rol != null && Clave(device.address, rol) in suscritos
            val valor = if (activo) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            servidor?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, valor)
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int, d: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?,
        ) {
            val rol = Rol.deCaracteristica(d.characteristic.uuid)
            if (rol == null || rol !in roles || d.uuid != Protocolo.CCCD) {
                responder(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null, responseNeeded)
                return
            }
            val clave = Clave(device.address, rol)
            if (clave !in autenticados) {
                oyente.registro("Suscripción rechazada: central no autenticado")
                responder(device, requestId, Protocolo.GATT_SIN_AUTORIZACION, offset, null, responseNeeded)
                return
            }
            if (value != null && value.contentEquals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) suscritos.remove(clave)
            else suscritos.add(clave)
            responder(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value, responseNeeded)
            oyente.alCambiar()
        }
    }

    companion object {
        const val TAG = "CeosmosCompanion"
        const val ERROR_OCUPADO = 201 // BluetoothStatusCodes.ERROR_GATT_WRITE_REQUEST_BUSY
        const val MAX_INTENTOS_NOTIFICACION = 6
        const val REINTENTO_MS = 40L
        const val ESPERA_CONFIRMACION_MS = 1_000L
        fun log(texto: String) = Log.i(TAG, texto)
    }
}
