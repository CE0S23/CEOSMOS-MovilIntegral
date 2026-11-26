package com.ceosmos.companion.ble

import org.json.JSONException
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Protocolo BLE CEOSMOS ↔ Reloj / TV. Debe coincidir con
 * `lib/core/ble/ble_protocolo.dart` de la app CEOSMOS.
 *
 * | Rol   | Servicio                               | AUTH (read/write) | A_DISP (write) | DE_DISP (notify) |
 * |-------|----------------------------------------|-------------------|----------------|------------------|
 * | Reloj | 6c3e1000-9b1a-4c5e-8a10-ce05a0b1e000   | 6c3e1001-…        | 6c3e1002-…     | 6c3e1003-…       |
 * | TV    | 6c3e2000-9b1a-4c5e-8a10-ce05a0b1e000   | 6c3e2001-…        | 6c3e2002-…     | 6c3e2003-…       |
 *
 * AUTH: lectura = reto aleatorio de 16 bytes (uno por conexión e intento);
 * escritura = HMAC-SHA256(PIN, reto ‖ "reloj"|"tv"). Hasta autenticarse se rechazan
 * escrituras y suscripciones con GATT_INSUFFICIENT_AUTHORIZATION (8).
 */
object Protocolo {
    private const val SUFIJO = "-9b1a-4c5e-8a10-ce05a0b1e000"
    val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    /** Identificador de fabricante de prueba (0xFFFF) para el id estable del compañero. */
    const val FABRICANTE = 0xFFFF
    const val MAX_BYTES = 180
    const val GATT_SIN_AUTORIZACION = 8
    const val GATT_ERROR_APLICACION = 0x80
    const val MAX_FALLOS = 3
    const val BLOQUEO_MS = 60_000L
    const val LIMITE_AUTENTICACION_MS = 30_000L

    enum class Rol(val etiqueta: String, val codigo: Int, val prefijo: String, val nombre: String) {
        RELOJ("reloj", 0x01, "6c3e1", "Reloj"),
        TV("tv", 0x02, "6c3e2", "TV");

        val servicio: UUID get() = UUID.fromString("${prefijo}000$SUFIJO")
        val auth: UUID get() = UUID.fromString("${prefijo}001$SUFIJO")
        val aDispositivo: UUID get() = UUID.fromString("${prefijo}002$SUFIJO")
        val deDispositivo: UUID get() = UUID.fromString("${prefijo}003$SUFIJO")

        companion object {
            fun deServicio(u: UUID): Rol? = entries.firstOrNull { it.servicio == u }
            fun deCaracteristica(u: UUID): Rol? =
                entries.firstOrNull { u == it.auth || u == it.aDispositivo || u == it.deDispositivo }
            fun deLista(texto: String): List<Rol> =
                texto.split(',').mapNotNull { t -> entries.firstOrNull { it.etiqueta == t.trim() } }
        }
    }

    fun hmac(pin: String, reto: ByteArray, rol: Rol): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(pin.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        mac.update(reto)
        mac.update(rol.etiqueta.toByteArray(Charsets.UTF_8))
        return mac.doFinal()
    }

    /** Comparación en tiempo constante (no revela cuántos bytes coinciden). */
    fun respuestaValida(pin: String, reto: ByteArray?, respuesta: ByteArray, rol: Rol): Boolean =
        reto != null && reto.size == 16 && MessageDigest.isEqual(hmac(pin, reto, rol), respuesta)

    fun pinValido(pin: String) = Regex("^\\d{6}$").matches(pin)

    /** Datos de fabricante del anuncio: [código del rol, 4 bytes del id]. */
    fun datosFabricante(rol: Rol, id: ByteArray): ByteArray = byteArrayOf(rol.codigo.toByte()) + id

    // ------------------------------------------------------------------
    // Mensajes CEOSMOS → periférico (se validan antes de usarlos)
    // ------------------------------------------------------------------

    sealed class Entrante {
        data class Saludo(val nombre: String) : Entrante()
        data object Adios : Entrante()
        data class Notificacion(val texto: String) : Entrante()

        /** 1.4.0: alerta de salud que CEOSMOS reenvía al Reloj (vibra) y a la TV (mensaje). */
        data class Alerta(val texto: String, val nivel: String) : Entrante()
        data class Sesion(
            val estado: String,
            val titulo: String,
            val modo: String,
            val restante: Int,
            val total: Int,
            val hr: Int?,
            val usuario: String,
        ) : Entrante()
    }

    private val estados = setOf("idle", "running", "paused")
    private val nivelesAlerta = setOf("aviso", "urgente")

    fun decodificar(bytes: ByteArray, rol: Rol): Entrante? {
        if (bytes.isEmpty() || bytes.size > MAX_BYTES) return null
        val j = try {
            JSONObject(String(bytes, Charsets.UTF_8))
        } catch (_: JSONException) {
            return null
        }
        return when (j.optString("t")) {
            "hello" -> j.optString("name").trim().takeIf { it.isNotEmpty() && it.length <= 30 }?.let { Entrante.Saludo(it) }
            "bye" -> Entrante.Adios
            "notif" -> if (rol != Rol.RELOJ) null else
                j.optString("msg").trim().takeIf { it.isNotEmpty() && it.length <= 120 }?.let { Entrante.Notificacion(it) }
            "alert" -> {
                val nivel = j.optString("lvl", "aviso").takeIf { it in nivelesAlerta } ?: return null
                j.optString("msg").trim().takeIf { it.isNotEmpty() && it.length <= 120 }?.let { Entrante.Alerta(it, nivel) }
            }
            "session" -> {
                val estado = j.optString("state")
                val rem = j.optInt("rem", -1)
                val tot = j.optInt("tot", -1)
                if (estado !in estados || rem < 0 || tot < 0 || rem > 4 * 3600 || tot > 4 * 3600) return null
                val hr = if (j.has("hr")) j.optInt("hr", -1).takeIf { it in 30..230 } else null
                Entrante.Sesion(
                    estado,
                    j.optString("title").take(60),
                    j.optString("mode").take(20),
                    rem,
                    tot,
                    hr,
                    j.optString("user").take(30),
                )
            }
            else -> null
        }
    }

    // ------------------------------------------------------------------
    // Mensajes periférico → CEOSMOS
    // ------------------------------------------------------------------

    fun saludo(nombre: String) = JSONObject().put("t", "hello").put("name", nombre.take(30)).toString().toByteArray()
    /** Lectura del Reloj. `act` (1.4.0) es opcional: un CEOSMOS anterior lo ignora. */
    fun lectura(hr: Int, pasos: Int, actividad: String? = null): ByteArray {
        val j = JSONObject().put("t", "hr").put("hr", hr.coerceIn(30, 230)).put("steps", pasos)
        if (actividad != null) j.put("act", actividad)
        return j.toString().toByteArray()
    }
    fun boton(accion: String) = JSONObject().put("t", "btn").put("a", accion).toString().toByteArray()
    fun comando(c: String) = JSONObject().put("t", "cmd").put("c", c).toString().toByteArray()
}
