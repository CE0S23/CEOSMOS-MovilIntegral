package com.ceosmos.practicas.p09

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue

/*
 * Modelo de datos. Los valores de estado y prioridad se guardan con su texto
 * ("En proceso", "Crítica") para que se lean igual en la app y en Firebase Console.
 */

const val COLECCION = "incidencias"
const val COLECCION_MATRIZ = "matriz_p9"

enum class Estado(val texto: String) {
    PENDIENTE("Pendiente"), EN_PROCESO("En proceso"), RESUELTA("Resuelta");

    companion object {
        fun de(texto: String?) = entries.firstOrNull { it.texto == texto } ?: PENDIENTE
    }
}

enum class Prioridad(val texto: String) {
    BAJA("Baja"), MEDIA("Media"), ALTA("Alta"), CRITICA("Crítica");

    companion object {
        fun de(texto: String?) = entries.firstOrNull { it.texto == texto } ?: MEDIA
    }
}

/**
 * Política de actualización al guardar una incidencia editada (Fase 4, DB-07):
 *  - CAMPOS: solo se escriben los campos que este dispositivo modificó, dentro de una
 *    transacción que compara con el valor que había al abrir el registro. Si otro dispositivo
 *    cambió el mismo campo, se detecta el conflicto y se pregunta antes de sobrescribir.
 *  - ULTIMA_ESCRITURA: se reescribe el documento completo con lo que ve este dispositivo
 *    (sin comparar). Sirve para demostrar la pérdida de cambios del problema original.
 */
enum class Politica(val titulo: String, val detalle: String) {
    CAMPOS("Por campos + detección de conflictos", "Solo se guardan los campos modificados; si otro dispositivo cambió el mismo campo se avisa."),
    ULTIMA_ESCRITURA("Última escritura gana (documento completo)", "Se sobrescribe todo el documento con lo que ve este dispositivo."),
}

data class Incidencia(
    val id: String,
    val titulo: String,
    val descripcion: String,
    val estado: Estado,
    val prioridad: Prioridad,
    val creadoPor: String,
    val actualizadoPor: String,
    val creadoEn: Long?,
    val actualizadoEn: Long?,
    val version: Long,
    /** true mientras la escritura local no ha sido confirmada por el servidor. */
    val pendiente: Boolean = false,
)

fun DocumentSnapshot.aIncidencia(): Incidencia = Incidencia(
    id = id,
    titulo = getString("titulo").orEmpty(),
    descripcion = getString("descripcion").orEmpty(),
    estado = Estado.de(getString("estado")),
    prioridad = Prioridad.de(getString("prioridad")),
    creadoPor = getString("creadoPor").orEmpty(),
    actualizadoPor = getString("actualizadoPor").orEmpty(),
    // ESTIMATE: mientras la escritura está en cola, la marca de tiempo del servidor aún no existe.
    creadoEn = getTimestamp("creadoEn", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
    actualizadoEn = getTimestamp("actualizadoEn", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
    version = getLong("version") ?: 1L,
    pendiente = metadata.hasPendingWrites(),
)

fun Timestamp.aMillis(): Long = seconds * 1000 + nanoseconds / 1_000_000

/** Documento completo de una incidencia nueva. */
fun nuevaIncidencia(titulo: String, descripcion: String, prioridad: Prioridad, dispositivo: String): Map<String, Any> = mapOf(
    "titulo" to titulo,
    "descripcion" to descripcion,
    "estado" to Estado.PENDIENTE.texto,
    "prioridad" to prioridad.texto,
    "creadoPor" to dispositivo,
    "actualizadoPor" to dispositivo,
    "creadoEn" to FieldValue.serverTimestamp(),
    "actualizadoEn" to FieldValue.serverTimestamp(),
    "version" to 1L,
)

/** Casos de la matriz de pruebas de la práctica. */
data class CasoPrueba(val id: String, val nombre: String, val esperado: String)

val CASOS_PRUEBA = listOf(
    CasoPrueba("DB-01", "Conexión compartida", "Ambos dispositivos acceden al mismo proyecto y colección."),
    CasoPrueba("DB-02", "Escritura desde A", "La incidencia creada por A aparece en la base remota."),
    CasoPrueba("DB-03", "Lectura desde B", "B puede recuperar la incidencia creada por A."),
    CasoPrueba("DB-04", "Escritura desde B", "La incidencia creada por B se almacena correctamente."),
    CasoPrueba("DB-05", "Lectura desde A", "A puede recuperar la incidencia creada por B."),
    CasoPrueba("DB-06", "Actualización cruzada", "El cambio confirmado es visible en el otro dispositivo."),
    CasoPrueba("DB-07", "Modificación concurrente", "El resultado final cumple la política de actualización definida."),
    CasoPrueba("DB-08", "Persistencia", "Los registros confirmados permanecen tras cerrar y abrir la app."),
    CasoPrueba("DB-09", "Pérdida de conexión", "La aplicación informa o gestiona la operación sin confirmar falsamente el éxito."),
)

val RESULTADOS = listOf("No registrado", "Pasó", "Pasó con observaciones", "Falló")

data class RegistroMatriz(val resultado: String, val observacion: String, val registradoPor: String, val fecha: Long?)

/** Evento de la bitácora de sincronización (lo que este dispositivo vio y cuándo). */
data class Evento(val hora: Long, val texto: String, val tipo: TipoEvento)

enum class TipoEvento { LOCAL, REMOTO, AVISO, ERROR }
