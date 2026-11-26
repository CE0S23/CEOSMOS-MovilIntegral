package com.ceosmos.companion.ble

import com.ceosmos.companion.ble.Protocolo.Rol

/**
 * Cola de notificaciones del servidor GATT (1.4.0), sin dependencias de Android para
 * probarla con JUnit.
 *
 * Causa raíz de «los botones fallan a veces»: Android admite UNA notificación en vuelo
 * por servidor; hasta `onNotificationSent` la siguiente devuelve
 * ERROR_GATT_WRITE_REQUEST_BUSY. Antes se notificaba sin esperar, así que un botón
 * pulsado mientras salía una lectura del Reloj (una por segundo) se perdía en silencio.
 *
 * Reglas: una sola en vuelo; botones y teclas (con etiqueta) antes que las lecturas;
 * de las lecturas solo se guarda la más reciente por central (sin atraso); si el envío
 * devuelve «ocupado» se reintenta en el mismo lugar hasta [maxIntentos].
 */
class ColaNotificaciones(private val maxIntentos: Int = 6) {
    class Pendiente(val direccion: String, val rol: Rol, val bytes: ByteArray, val etiqueta: String?) {
        var intentos = 0
            internal set
    }

    private val prioritaria = ArrayDeque<Pendiente>()
    private val lecturas = ArrayDeque<Pendiente>()
    var enVuelo: Pendiente? = null
        private set

    val tamano: Int get() = prioritaria.size + lecturas.size + (if (enVuelo != null) 1 else 0)

    fun encolar(p: Pendiente) {
        if (p.etiqueta != null) {
            prioritaria.addLast(p)
        } else {
            lecturas.removeAll { it.direccion == p.direccion && it.rol == p.rol }
            lecturas.addLast(p)
        }
    }

    /** Siguiente a enviar, o null si hay una en vuelo o no queda nada. Cuenta el intento. */
    fun tomar(): Pendiente? {
        if (enVuelo != null) return null
        val p = prioritaria.removeFirstOrNull() ?: lecturas.removeFirstOrNull() ?: return null
        p.intentos++
        return p
    }

    /** El sistema aceptó la notificación: queda en vuelo hasta [confirmar]. */
    fun enviada(p: Pendiente) {
        enVuelo = p
    }

    /**
     * El sistema respondió «ocupado» (o la confirmación trajo error). Devuelve true si se
     * reintentará (vuelve al frente de su cola) y false si se descarta.
     */
    fun reintentar(p: Pendiente): Boolean {
        if (enVuelo === p) enVuelo = null
        if (p.intentos >= maxIntentos) return false
        (if (p.etiqueta != null) prioritaria else lecturas).addFirst(p)
        return true
    }

    /** Llegó `onNotificationSent` (o venció la espera). Devuelve la que estaba en vuelo. */
    fun confirmar(): Pendiente? {
        val p = enVuelo
        enVuelo = null
        return p
    }

    /** Vacía todo (o lo de una dirección) y devuelve las que llevaban etiqueta. */
    fun vaciar(direccion: String? = null): List<Pendiente> {
        val todas = (prioritaria + lecturas + listOfNotNull(enVuelo)).filter { direccion == null || it.direccion == direccion }
        prioritaria.removeAll { it in todas }
        lecturas.removeAll { it in todas }
        if (enVuelo in todas) enVuelo = null
        return todas.filter { it.etiqueta != null }
    }
}

/** Rebote de pulsaciones: la misma tecla repetida en menos de [ms] se ignora. */
class Rebote(private val ms: Long) {
    private val ultimo = mutableMapOf<String, Long>()

    fun permitir(clave: String, ahora: Long): Boolean {
        val previo = ultimo[clave]
        if (previo != null && ahora - previo < ms) return false
        ultimo[clave] = ahora
        return true
    }
}
