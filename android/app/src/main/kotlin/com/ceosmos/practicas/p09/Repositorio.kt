package com.ceosmos.practicas.p09

import com.google.android.gms.tasks.Task
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentChange
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.MetadataChanges
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.Source
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/*
 * Acceso a Cloud Firestore (almacenamiento compartido en la nube). Colecciones:
 *  - incidencias/{auto}  titulo, descripcion, estado, prioridad, creadoPor, actualizadoPor,
 *                        creadoEn, actualizadoEn (hora del servidor), version
 *  - matriz_p9/{DB-01}   resultado, observacion, registradoPor, fecha
 *
 * Firestore mantiene además una caché local en el teléfono: sin conexión las escrituras
 * quedan "en cola" y se envían solas al reconectar; las lecturas devuelven lo último guardado.
 */

// Tiempo que se espera la confirmación del servidor antes de dar la escritura por "en cola".
private const val TIEMPO_CONFIRMACION_MS = 6_000L

/** Resultado de una escritura: confirmada por el servidor o guardada localmente en cola. */
enum class Escritura { CONFIRMADA, EN_COLA }

/**
 * Espera a que el servidor confirme la escritura. Si no responde a tiempo (sin conexión),
 * la escritura sigue en la cola local de Firestore y se informa como EN_COLA, nunca como éxito.
 * Si el servidor la rechaza (p. ej. reglas), se lanza la excepción.
 */
private suspend fun Task<*>.confirmar(): Escritura =
    if (withTimeoutOrNull(TIEMPO_CONFIRMACION_MS) { await(); true } != null) Escritura.CONFIRMADA else Escritura.EN_COLA

/** Fotografía de la colección recibida por el listener o por una consulta manual. */
data class Instantanea(
    val incidencias: List<Incidencia>,
    val desdeCache: Boolean,
    val cambios: List<Cambio>,
)

data class Cambio(val tipo: DocumentChange.Type, val incidencia: Incidencia)

sealed interface ResultadoGuardado {
    data class Guardado(val escritura: Escritura, val campos: List<String>, val verificado: Boolean) : ResultadoGuardado
    data class Conflicto(val remota: Incidencia, val campos: List<String>) : ResultadoGuardado
    data object SinCambios : ResultadoGuardado
    data object NoExiste : ResultadoGuardado
}

class Repositorio(private val db: FirebaseFirestore) { // [CEOSMOS] la instancia la entrega el ViewModel

    private val incidencias = db.collection(COLECCION)
    private val matriz = db.collection(COLECCION_MATRIZ)

    /** Proyecto de Firebase al que está conectada esta instalación (evidencia de DB-01). */
    val proyecto: String get() = db.app.options.projectId.orEmpty() // [CEOSMOS] app con nombre
    val appId: String get() = db.app.options.applicationId

    // ----- Lectura -----------------------------------------------------------

    /** Escucha en tiempo real. INCLUDE avisa también cuando una escritura en cola se confirma. */
    fun escuchar(alCambiar: (Instantanea) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        incidencias.addSnapshotListener(MetadataChanges.INCLUDE) { instantanea, error ->
            if (error != null) alFallar(error) else instantanea?.let { alCambiar(it.aInstantanea()) }
        }

    /** Consulta manual: pide los datos al servidor; sin conexión devuelve la caché local. */
    suspend fun consultar(): Instantanea = try {
        incidencias.get(Source.SERVER).await().aInstantanea()
    } catch (e: FirebaseFirestoreException) {
        if (e.code != FirebaseFirestoreException.Code.UNAVAILABLE) throw e
        incidencias.get(Source.CACHE).await().aInstantanea()
    }

    private fun QuerySnapshot.aInstantanea() = Instantanea(
        incidencias = documents.map { it.aIncidencia() }.sortedByDescending { it.creadoEn ?: Long.MAX_VALUE },
        desdeCache = metadata.isFromCache,
        cambios = getDocumentChanges(MetadataChanges.INCLUDE).map { Cambio(it.type, it.document.aIncidencia()) },
    )

    // ----- Escritura ---------------------------------------------------------

    /** ID nuevo generado en el teléfono (no necesita conexión). */
    fun nuevoId(): String = incidencias.document().id

    suspend fun crear(id: String, titulo: String, descripcion: String, prioridad: Prioridad, dispositivo: String): Escritura =
        incidencias.document(id).set(nuevaIncidencia(titulo, descripcion, prioridad, dispositivo)).confirmar()

    /**
     * Guarda la edición de [original] (la versión que se abrió en pantalla) según [politica].
     * [enLinea] = false evita la transacción, que necesita al servidor: la actualización por
     * campos se deja en cola sin poder verificar conflictos.
     */
    suspend fun guardar(
        original: Incidencia,
        estado: Estado,
        prioridad: Prioridad,
        dispositivo: String,
        politica: Politica,
        enLinea: Boolean,
        forzar: Boolean = false,
    ): ResultadoGuardado {
        val nuevos = buildMap {
            if (estado != original.estado) put("estado", estado.texto)
            if (prioridad != original.prioridad) put("prioridad", prioridad.texto)
        }
        if (nuevos.isEmpty()) return ResultadoGuardado.SinCambios
        val documento = incidencias.document(original.id)
        val auditoria = mapOf("actualizadoPor" to dispositivo, "actualizadoEn" to FieldValue.serverTimestamp())

        if (politica == Politica.ULTIMA_ESCRITURA) {
            // Documento completo tal como lo ve este dispositivo: lo que otro cambió se pierde.
            val completo = mapOf(
                "titulo" to original.titulo,
                "descripcion" to original.descripcion,
                "estado" to estado.texto,
                "prioridad" to prioridad.texto,
                "creadoPor" to original.creadoPor,
                "creadoEn" to (original.creadoEn?.let { Timestamp(it / 1000, ((it % 1000) * 1_000_000).toInt()) } ?: FieldValue.serverTimestamp()),
                "version" to original.version + 1,
            ) + auditoria
            return ResultadoGuardado.Guardado(documento.set(completo).confirmar(), nuevos.keys.toList(), verificado = false)
        }

        val cambios = nuevos + auditoria + ("version" to FieldValue.increment(1))
        if (!enLinea) {
            return ResultadoGuardado.Guardado(documento.update(cambios).confirmar(), nuevos.keys.toList(), verificado = false)
        }

        // Transacción: se lee el valor actual en el servidor y solo se escribe si nadie más
        // cambió los mismos campos desde que se abrió el registro.
        val resultado = try {
            withTimeoutOrNull(TIEMPO_CONFIRMACION_MS) { transaccion(documento, original, nuevos, cambios, forzar) }
        } catch (e: FirebaseFirestoreException) {
            if (e.code != FirebaseFirestoreException.Code.UNAVAILABLE) throw e
            null
        }
        // Sin respuesta del servidor: se deja la actualización por campos en la cola local.
        return resultado ?: ResultadoGuardado.Guardado(documento.update(cambios).confirmar(), nuevos.keys.toList(), verificado = false)
    }

    private suspend fun transaccion(
        documento: DocumentReference,
        original: Incidencia,
        nuevos: Map<String, String>,
        cambios: Map<String, Any>,
        forzar: Boolean,
    ): ResultadoGuardado =
            db.runTransaction<ResultadoGuardado> { tx ->
                val actual = tx.get(documento)
                if (!actual.exists()) return@runTransaction ResultadoGuardado.NoExiste
                val remota = actual.aIncidencia()
                val enConflicto = nuevos.keys.filter { campo ->
                    val inicial = valorDe(original, campo)
                    val servidor = valorDe(remota, campo)
                    servidor != inicial && servidor != nuevos[campo]
                }
                if (enConflicto.isNotEmpty() && !forzar) return@runTransaction ResultadoGuardado.Conflicto(remota, enConflicto)
                tx.update(documento, cambios)
                ResultadoGuardado.Guardado(Escritura.CONFIRMADA, nuevos.keys.toList(), verificado = true)
            }.await()

    private fun valorDe(incidencia: Incidencia, campo: String): String = when (campo) {
        "estado" -> incidencia.estado.texto
        "prioridad" -> incidencia.prioridad.texto
        else -> ""
    }

    suspend fun eliminar(id: String): Escritura = incidencias.document(id).delete().confirmar()

    // ----- Matriz de pruebas -------------------------------------------------

    fun escucharMatriz(alCambiar: (Map<String, RegistroMatriz>) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        matriz.addSnapshotListener { instantanea, error ->
            if (error != null) alFallar(error)
            instantanea?.let {
                alCambiar(it.documents.associate { d ->
                    d.id to RegistroMatriz(
                        resultado = d.getString("resultado") ?: RESULTADOS.first(),
                        observacion = d.getString("observacion").orEmpty(),
                        registradoPor = d.getString("registradoPor").orEmpty(),
                        fecha = d.getTimestamp("fecha", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
                    )
                })
            }
        }

    suspend fun registrarPrueba(id: String, resultado: String, observacion: String, dispositivo: String): Escritura =
        matriz.document(id).set(
            mapOf(
                "resultado" to resultado,
                "observacion" to observacion,
                "registradoPor" to dispositivo,
                "fecha" to FieldValue.serverTimestamp(),
            )
        ).confirmar()
}
