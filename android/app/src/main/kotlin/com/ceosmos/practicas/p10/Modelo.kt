package com.ceosmos.practicas.p10

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue

/*
 * Modelo de datos. Los valores de estado y prioridad se guardan con su texto
 * ("En proceso", "Crítica") para que se lean igual en la app y en Firebase Console.
 *
 * El propietario de cada incidencia es el UID de Firebase Authentication de quien la creó
 * (campo creadoPor). Las reglas de Firestore lo comparan con request.auth.uid.
 *
 * El propietario puede asignar (enviar) la incidencia a otro usuario (campo asignadoA). El
 * asignado puede verla y cambiar su estado (y la prioridad si el dueño le da permiso de editar),
 * pero no reasignarla ni borrarla.
 *
 * Ceder: el dueño pasa la incidencia a otro usuario y deja de verla; la cesión queda registrada en
 * cedidoPor (UID de quien la cedió, que las reglas comparan con la sesión). Poner el UID de otro
 * como propietario sin registrar la cesión se rechaza (SEG-04, SEG-09).
 */

const val COLECCION = "incidencias_p10"
const val COLECCION_USUARIOS = "usuarios_p10"
const val COLECCION_MATRIZ = "matriz_p10"
const val COLECCION_SESIONES = "sesiones_p10"

// [CEOSMOS] Nombres que se MUESTRAN en pantalla (sin el sufijo interno de la práctica).
// Las consultas a Firestore siguen usando las constantes reales de arriba.
const val COLECCION_VISIBLE = "incidencias"
const val MATRIZ_VISIBLE = "matriz de pruebas"
fun proyectoVisible(id: String): String = id.replace(Regex("-p\\d+$"), "")

/** Una cuenta solo puede tener una sesión activa: la instalación que la tiene y su último latido. */
data class SesionActiva(val instalacion: String, val equipo: String, val inicio: Long?, val latido: Long?)

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

data class Incidencia(
    val id: String,
    val titulo: String,
    val descripcion: String,
    val estado: Estado,
    val prioridad: Prioridad,
    /** UID del propietario. */
    val creadoPor: String,
    /** Correo del propietario, solo para mostrarlo; la seguridad se basa en el UID. */
    val creadoPorCorreo: String,
    val actualizadoPor: String,
    /** UID del usuario al que se asignó ("" si no está asignada). */
    val asignadoA: String,
    val asignadoACorreo: String,
    /** El dueño permite que el asignado cambie también la prioridad. */
    val puedeEditar: Boolean,
    /** UID de quien cedió la incidencia al propietario actual ("" si nunca se cedió). */
    val cedidoPor: String,
    val cedidoPorCorreo: String,
    val creadoEn: Long?,
    val actualizadoEn: Long?,
    val version: Long,
    /** true mientras la escritura local no ha sido confirmada por el servidor. */
    val pendiente: Boolean = false,
) {
    val asignada get() = asignadoA.isNotEmpty()
    val cedida get() = cedidoPor.isNotEmpty()
}

fun DocumentSnapshot.aIncidencia(): Incidencia = Incidencia(
    id = id,
    titulo = getString("titulo").orEmpty(),
    descripcion = getString("descripcion").orEmpty(),
    estado = Estado.de(getString("estado")),
    prioridad = Prioridad.de(getString("prioridad")),
    creadoPor = getString("creadoPor").orEmpty(),
    creadoPorCorreo = getString("creadoPorCorreo").orEmpty(),
    actualizadoPor = getString("actualizadoPor").orEmpty(),
    asignadoA = getString("asignadoA").orEmpty(),
    asignadoACorreo = getString("asignadoACorreo").orEmpty(),
    puedeEditar = getBoolean("puedeEditar") ?: false,
    cedidoPor = getString("cedidoPor").orEmpty(),
    cedidoPorCorreo = getString("cedidoPorCorreo").orEmpty(),
    // ESTIMATE: mientras la escritura está en cola, la marca de tiempo del servidor aún no existe.
    creadoEn = getTimestamp("creadoEn", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
    actualizadoEn = getTimestamp("actualizadoEn", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
    version = getLong("version") ?: 1L,
    pendiente = metadata.hasPendingWrites(),
)

fun Timestamp.aMillis(): Long = seconds * 1000 + nanoseconds / 1_000_000

/**
 * Documento completo de una incidencia nueva. [propietario] normalmente es el UID de la sesión;
 * la prueba SEG-04 pasa el UID de otro usuario para comprobar que Firestore lo rechaza.
 * [asignado] es el usuario al que se envía la incidencia (null: sin asignar). [cedidoPor] es quien
 * la crea para cedérsela a [propietario] (null: la crea para sí mismo).
 */
fun nuevaIncidencia(
    titulo: String, descripcion: String, prioridad: Prioridad, propietario: String, correo: String, autor: String,
    asignado: Usuario? = null,
    cedidoPor: Usuario? = null,
): Map<String, Any> = mapOf(
    "titulo" to titulo,
    "descripcion" to descripcion,
    "estado" to Estado.PENDIENTE.texto,
    "prioridad" to prioridad.texto,
    "creadoPor" to propietario,
    "creadoPorCorreo" to correo,
    "actualizadoPor" to autor,
    "asignadoA" to asignado?.uid.orEmpty(),
    "asignadoACorreo" to asignado?.correo.orEmpty(),
    "puedeEditar" to false,
    "cedidoPor" to cedidoPor?.uid.orEmpty(),
    "cedidoPorCorreo" to cedidoPor?.correo.orEmpty(),
    "creadoEn" to FieldValue.serverTimestamp(),
    "actualizadoEn" to FieldValue.serverTimestamp(),
    "version" to 1L,
)

/**
 * Perfil público mínimo (usuarios_p10/{uid}). [incidencias] son solo los id de sus incidencias sin
 * asignar: el otro usuario los usa para intentar leerlas, modificarlas o borrarlas (SEG-05/06/07).
 * Conocer el id no da acceso: las reglas comparan el propietario con la sesión.
 */
data class Usuario(val uid: String, val correo: String, val equipo: String, val incidencias: List<String>)

/** Incidencia de otro usuario de la que solo se conoce el id. */
data class IncidenciaAjena(val id: String, val propietario: Usuario)

// ---------------------------------------------------------------------------
// Matriz de pruebas de seguridad
// ---------------------------------------------------------------------------

/**
 * [permitida]: lo que debe responder Firestore (o Authentication) para que la prueba pase.
 * Las pruebas se hacen a mano desde la app; [comoProbar] explica dónde.
 */
data class CasoSeguridad(val id: String, val nombre: String, val accion: String, val esperado: String, val permitida: Boolean, val comoProbar: String)

val CASOS_SEGURIDAD = listOf(
    CasoSeguridad("SEG-01", "Inicio de sesión válido", "Ingresar con la cuenta del usuario.", "Autenticación exitosa.", true,
        "Cierra sesión y entra con tu correo y tu contraseña correcta."),
    CasoSeguridad("SEG-02", "Inicio de sesión inválido", "Intentar ingresar con una contraseña incorrecta.", "Acceso rechazado.", false,
        "Cierra sesión, escribe tu correo con una contraseña incorrecta y pulsa Iniciar sesión. Se anota al volver a entrar."),
    CasoSeguridad("SEG-03", "Creación propia", "Registrar una incidencia con el UID propio.", "Documento creado con el propietario correcto.", true,
        "Incidencias → Nueva, deja Propietario = tú y guarda."),
    CasoSeguridad("SEG-04", "Suplantación de propietario", "Crear una incidencia indicando el UID del otro usuario.", "Firestore rechaza la escritura.", false,
        "Incidencias → Nueva, en Propietario elige al otro usuario y guarda."),
    CasoSeguridad("SEG-05", "Lectura de datos ajenos", "Leer directamente una incidencia del otro usuario.", "Lectura denegada.", false,
        "Incidencias → Incidencias de otros usuarios → toca una → Leer."),
    CasoSeguridad("SEG-06", "Actualización de datos ajenos", "Modificar una incidencia del otro usuario.", "Actualización denegada.", false,
        "Incidencias → Incidencias de otros usuarios → toca una → elige un estado → Modificar."),
    CasoSeguridad("SEG-07", "Eliminación de datos ajenos", "Eliminar una incidencia del otro usuario.", "Eliminación denegada.", false,
        "Incidencias → Incidencias de otros usuarios → toca una → Eliminar."),
    CasoSeguridad("SEG-08", "Actualización propia", "Modificar el estado de una incidencia propia.", "Actualización permitida.", true,
        "Abre una de tus incidencias, cambia el Estado y guarda."),
    CasoSeguridad("SEG-09", "Cambio de propietario", "Cambiar el UID de propietario en un documento propio.", "Cambio de propietario rechazado.", false,
        "Abre una de tus incidencias, en Propietario elige al otro usuario y guarda."),
    CasoSeguridad("SEG-10", "Acceso sin autenticación", "Sin sesión, intentar leer y escribir.", "Operación rechazada.", false,
        "Cierra sesión y pulsa \"Intentar leer y escribir sin sesión\". Se anota al volver a entrar."),
    CasoSeguridad("SEG-11", "Asignación a otro usuario", "Asignar una incidencia propia al otro usuario.", "Asignación permitida; el propietario no cambia.", true,
        "Abre una de tus incidencias (o crea una), en Asignada a elige al otro usuario y guarda."),
    CasoSeguridad("SEG-12", "Lectura de incidencia asignada", "Leer una incidencia que el otro usuario te asignó.", "Lectura permitida.", true,
        "En el otro dispositivo: Asignadas a mí → toca la incidencia (se lee del servidor)."),
    CasoSeguridad("SEG-13", "Asignado cambia el estado", "Cambiar el estado de una incidencia que te asignaron.", "Actualización permitida.", true,
        "En el otro dispositivo: abre la incidencia asignada, cambia solo el Estado y guarda."),
    CasoSeguridad("SEG-14", "Asignado excede sus permisos", "En una incidencia asignada (sin permiso de editar): cambiar prioridad, reasignarla, apropiársela o eliminarla.", "Operación rechazada.", false,
        "En el otro dispositivo: abre la incidencia asignada y cambia Prioridad (sin permiso), Asignada a o Propietario, o pulsa Eliminar."),
    CasoSeguridad("SEG-15", "Cesión de incidencia", "El dueño cede su incidencia al otro usuario (queda registrado en cedidoPor).", "Cesión permitida: el otro usuario pasa a ser el propietario.", true,
        "Abre una de tus incidencias (o crea una), en Ceder a elige al otro usuario y guarda. Desaparece de tu lista y aparece en la del otro."),
    CasoSeguridad("SEG-16", "Edición con permiso", "El dueño da permiso de editar y el asignado cambia la prioridad.", "Actualización permitida.", true,
        "Asigna una incidencia y marca \"Permitir que edite\"; en el otro dispositivo: ábrela, cambia la Prioridad y guarda."),
)

/** Resultado de ejecutar un caso: qué respondió el servidor y si coincide con lo esperado. */
data class ResultadoSeguridad(
    val caso: String,
    val paso: Boolean,
    val evidencia: String,
    val ejecutadoPor: String,
    val fecha: Long?,
)

/** Evento de la bitácora (operaciones exitosas, rechazadas y avisos). */
data class Evento(val hora: Long, val texto: String, val tipo: TipoEvento)

enum class TipoEvento { LOCAL, REMOTO, AVISO, ERROR }

// ---------------------------------------------------------------------------
// Última sesión del teléfono (copia local para la pantalla de inicio)
// ---------------------------------------------------------------------------

data class TicketResumen(val titulo: String, val estado: String, val prioridad: String, val rol: String)

data class ResumenSesion(val correo: String, val uid: String, val fecha: Long, val tickets: List<TicketResumen>) {
    fun aTexto(): String = org.json.JSONObject()
        .put("correo", correo).put("uid", uid).put("fecha", fecha)
        .put("tickets", org.json.JSONArray(tickets.map {
            org.json.JSONObject().put("titulo", it.titulo).put("estado", it.estado).put("prioridad", it.prioridad).put("rol", it.rol)
        }))
        .toString()

    companion object {
        fun leer(texto: String?): ResumenSesion? = texto?.let {
            runCatching {
                val j = org.json.JSONObject(it)
                val t = j.getJSONArray("tickets")
                ResumenSesion(j.getString("correo"), j.getString("uid"), j.getLong("fecha"), (0 until t.length()).map { i ->
                    val o = t.getJSONObject(i)
                    TicketResumen(o.getString("titulo"), o.getString("estado"), o.getString("prioridad"), o.getString("rol"))
                })
            }.getOrNull()
        }
    }
}
