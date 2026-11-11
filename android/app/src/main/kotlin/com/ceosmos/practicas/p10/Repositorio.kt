package com.ceosmos.practicas.p10

import android.content.Context
import com.google.android.gms.tasks.Task
import com.ceosmos.practicas.FirebasePracticas
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.DocumentChange
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.MetadataChanges
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.Source
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/*
 * Acceso a Firebase Authentication y Cloud Firestore. Colecciones:
 *  - incidencias_p10/{auto}  titulo, descripcion, estado, prioridad, creadoPor (UID),
 *                            creadoPorCorreo, actualizadoPor (UID), asignadoA (UID), asignadoACorreo,
 *                            creadoEn, actualizadoEn, version
 *  - usuarios_p10/{uid}      correo, equipo, incidencias (ids sin asignar; perfil público mínimo)
 *  - matriz_p10/{SEG-01}     paso, evidencia, ejecutadoPor, uid, fecha
 *
 * Las reglas de seguridad (firestore.rules) solo dejan leer y modificar las incidencias cuyo
 * creadoPor es el UID de la sesión, más las que tienen asignadoA = UID de la sesión. Por eso se
 * hacen dos consultas filtradas (propias y asignadas): una consulta sin filtro sería rechazada
 * completa, porque las reglas no filtran resultados.
 */

// Tiempo que se espera la confirmación del servidor antes de dar la escritura por "en cola".
private const val TIEMPO_CONFIRMACION_MS = 8_000L

/** Resultado de una escritura: confirmada por el servidor o guardada localmente en cola. */
enum class Escritura { CONFIRMADA, EN_COLA }

/**
 * Espera a que el servidor confirme la escritura. Si no responde a tiempo (sin conexión),
 * la escritura sigue en la cola local de Firestore y se informa como EN_COLA, nunca como éxito.
 * Si el servidor la rechaza (reglas), se lanza FirebaseFirestoreException PERMISSION_DENIED.
 */
suspend fun Task<*>.confirmar(): Escritura =
    if (withTimeoutOrNull(TIEMPO_CONFIRMACION_MS) { await(); true } != null) Escritura.CONFIRMADA else Escritura.EN_COLA

/** Fotografía de las incidencias del usuario recibida por el listener. */
data class Instantanea(val incidencias: List<Incidencia>, val desdeCache: Boolean, val cambios: List<Cambio>)

data class Cambio(val tipo: DocumentChange.Type, val incidencia: Incidencia)

class Repositorio(private val contexto: Context) {

    // [CEOSMOS] Instancias de la app de Firebase con nombre «p10» (no [DEFAULT]).
    private val firebase = FirebasePracticas.app(contexto, FirebasePracticas.P10)
    private val auth = FirebaseAuth.getInstance(firebase)
    private val db = FirebaseFirestore.getInstance(firebase)
    private val incidencias = db.collection(COLECCION)
    private val usuarios = db.collection(COLECCION_USUARIOS)
    private val matriz = db.collection(COLECCION_MATRIZ)

    val proyecto: String get() = firebase.options.projectId.orEmpty()
    val appId: String get() = firebase.options.applicationId

    // ----- Autenticación -----------------------------------------------------

    val usuario: FirebaseUser? get() = auth.currentUser

    fun escucharSesion(alCambiar: (FirebaseUser?) -> Unit): FirebaseAuth.AuthStateListener =
        FirebaseAuth.AuthStateListener { alCambiar(it.currentUser) }.also { auth.addAuthStateListener(it) }

    fun dejarDeEscucharSesion(l: FirebaseAuth.AuthStateListener) = auth.removeAuthStateListener(l)

    suspend fun iniciarSesion(correo: String, clave: String): FirebaseUser =
        auth.signInWithEmailAndPassword(correo, clave).await().user!!

    suspend fun crearCuenta(correo: String, clave: String): FirebaseUser =
        auth.createUserWithEmailAndPassword(correo, clave).await().user!!

    fun cerrarSesion() = auth.signOut()

    // ----- Sesión única por cuenta ----------------------------------------------

    private val sesiones = db.collection(COLECCION_SESIONES)

    private fun DocumentSnapshot.aSesion() = SesionActiva(
        instalacion = getString("instalacion").orEmpty(),
        equipo = getString("equipo").orEmpty(),
        inicio = getTimestamp("inicio", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
        latido = getTimestamp("latido", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
    )

    /**
     * Toma la sesión de la cuenta para esta instalación. Devuelve la sesión de otra instalación
     * si sigue activa (latido reciente); en ese caso no se escribe nada. Se hace en una
     * transacción para que dos teléfonos que entran a la vez no ganen los dos.
     */
    suspend fun reclamarSesion(uid: String, instalacion: String, equipo: String, vigenciaMs: Long): SesionActiva? =
        db.runTransaction<SesionActiva?> { tx ->
            val ref = sesiones.document(uid)
            val actual = tx.get(ref).takeIf { it.exists() }?.aSesion()
            val ocupada = actual != null && actual.instalacion != instalacion &&
                (actual.latido ?: 0L) > System.currentTimeMillis() - vigenciaMs
            if (ocupada) return@runTransaction actual
            tx.set(ref, mapOf(
                "instalacion" to instalacion,
                "equipo" to equipo,
                "inicio" to FieldValue.serverTimestamp(),
                "latido" to FieldValue.serverTimestamp(),
            ))
            null
        }.await()

    suspend fun latido(uid: String) {
        sesiones.document(uid).update("latido", FieldValue.serverTimestamp()).await()
    }

    /** Libera la sesión solo si la tiene esta instalación. */
    suspend fun liberarSesion(uid: String, instalacion: String) {
        val ref = sesiones.document(uid)
        if (ref.get(Source.SERVER).await().getString("instalacion") == instalacion) ref.delete().await()
    }

    fun escucharSesionActiva(uid: String, alCambiar: (SesionActiva?) -> Unit): ListenerRegistration =
        sesiones.document(uid).addSnapshotListener { d, _ -> if (d != null && !d.metadata.isFromCache) alCambiar(d.takeIf { it.exists() }?.aSesion()) }

    // ----- Incidencias del usuario ---------------------------------------------

    /** Escucha en tiempo real solo las incidencias del propietario (lo que permiten las reglas). */
    fun escuchar(uid: String, alCambiar: (Instantanea) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        escucharDonde("creadoPor", uid, alCambiar, alFallar)

    /** Escucha las incidencias que otros usuarios asignaron a [uid]. */
    fun escucharAsignadas(uid: String, alCambiar: (Instantanea) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        escucharDonde("asignadoA", uid, alCambiar, alFallar)

    private fun escucharDonde(campo: String, uid: String, alCambiar: (Instantanea) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        incidencias.whereEqualTo(campo, uid).addSnapshotListener(MetadataChanges.INCLUDE) { instantanea, error ->
            if (error != null) alFallar(error) else instantanea?.let { alCambiar(it.aInstantanea()) }
        }

    private fun QuerySnapshot.aInstantanea() = Instantanea(
        incidencias = documents.map { it.aIncidencia() }.sortedByDescending { it.creadoEn ?: Long.MAX_VALUE },
        desdeCache = metadata.isFromCache,
        cambios = getDocumentChanges(MetadataChanges.INCLUDE).map { Cambio(it.type, it.document.aIncidencia()) },
    )

    /** ID nuevo generado en el teléfono (no necesita conexión). */
    fun nuevoId(): String = incidencias.document().id

    /** [propietario] es el UID que se escribe en creadoPor; [autor] el UID de la sesión. */
    suspend fun crear(
        id: String, titulo: String, descripcion: String, prioridad: Prioridad, propietario: String, correo: String, autor: String,
        asignado: Usuario? = null, cedidoPor: Usuario? = null,
    ): Escritura =
        incidencias.document(id).set(nuevaIncidencia(titulo, descripcion, prioridad, propietario, correo, autor, asignado, cedidoPor)).confirmar()

    /** Escribe solo los campos indicados más la auditoría (quién, cuándo, versión). */
    suspend fun actualizar(id: String, campos: Map<String, Any>, autor: String): Escritura =
        incidencias.document(id).update(
            campos + mapOf("actualizadoPor" to autor, "actualizadoEn" to FieldValue.serverTimestamp(), "version" to FieldValue.increment(1))
        ).confirmar()

    /** Asigna la incidencia a [destino] (null la deja sin asignar). Solo el propietario puede hacerlo. */
    suspend fun asignar(id: String, destino: Usuario?, autor: String): Escritura =
        actualizar(id, camposAsignacion(destino), autor)

    /** El dueño cede la incidencia a [destino]: pasa a ser su propietario y se quitan asignación y permiso. */
    suspend fun ceder(id: String, destino: Usuario, yo: Usuario): Escritura =
        actualizar(id, camposCesion(destino, yo) + camposAsignacion(null) + mapOf("puedeEditar" to false), yo.uid)

    suspend fun eliminar(id: String): Escritura = incidencias.document(id).delete().confirmar()

    /** Lectura directa de un documento, siempre al servidor (sin caché) para que respondan las reglas. */
    suspend fun leer(id: String): DocumentSnapshot = incidencias.document(id).get(Source.SERVER).await()

    /** Consulta de toda la colección sin filtro de propietario (las reglas deben rechazarla). */
    suspend fun leerTodas(): QuerySnapshot = incidencias.get(Source.SERVER).await()

    // ----- Perfiles públicos ---------------------------------------------------

    /** [incidencias] null deja la lista publicada como está. */
    suspend fun publicarPerfil(uid: String, correo: String, equipo: String, incidencias: List<String>?): Escritura =
        usuarios.document(uid).set(
            buildMap {
                put("correo", correo)
                put("equipo", equipo)
                put("actualizadoEn", FieldValue.serverTimestamp())
                put("incidenciaPrueba", FieldValue.delete())
                incidencias?.let { put("incidencias", it) }
            },
            SetOptions.merge(),
        ).confirmar()

    fun escucharUsuarios(alCambiar: (List<Usuario>) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        usuarios.addSnapshotListener { instantanea, error ->
            if (error != null) alFallar(error)
            instantanea?.let {
                alCambiar(it.documents.map { d ->
                    Usuario(
                        d.id, d.getString("correo").orEmpty(), d.getString("equipo").orEmpty(),
                        (d.get("incidencias") as? List<*>)?.filterIsInstance<String>().orEmpty(),
                    )
                })
            }
        }

    // ----- Matriz de pruebas ---------------------------------------------------

    fun escucharMatriz(alCambiar: (Map<String, ResultadoSeguridad>) -> Unit, alFallar: (Exception) -> Unit): ListenerRegistration =
        matriz.addSnapshotListener { instantanea, error ->
            if (error != null) alFallar(error)
            instantanea?.let {
                alCambiar(it.documents.associate { d ->
                    d.id to ResultadoSeguridad(
                        caso = d.id,
                        paso = d.getBoolean("paso") ?: false,
                        evidencia = d.getString("evidencia").orEmpty(),
                        ejecutadoPor = d.getString("ejecutadoPor").orEmpty(),
                        fecha = d.getTimestamp("fecha", DocumentSnapshot.ServerTimestampBehavior.ESTIMATE)?.aMillis(),
                    )
                })
            }
        }

    suspend fun registrarResultado(r: ResultadoSeguridad, uid: String): Escritura =
        matriz.document(r.caso).set(
            mapOf(
                "paso" to r.paso,
                "resultado" to if (r.paso) "Pasó" else "Falló",
                "evidencia" to r.evidencia,
                "ejecutadoPor" to r.ejecutadoPor,
                "uid" to uid,
                "fecha" to FieldValue.serverTimestamp(),
            )
        ).confirmar()
}

fun camposAsignacion(destino: Usuario?): Map<String, Any> =
    mapOf("asignadoA" to destino?.uid.orEmpty(), "asignadoACorreo" to destino?.correo.orEmpty())

/** Cambio de propietario registrado: [destino] pasa a ser el dueño y [yo] queda como quien la cedió. */
fun camposCesion(destino: Usuario, yo: Usuario): Map<String, Any> = mapOf(
    "creadoPor" to destino.uid, "creadoPorCorreo" to destino.correo,
    "cedidoPor" to yo.uid, "cedidoPorCorreo" to yo.correo,
)
