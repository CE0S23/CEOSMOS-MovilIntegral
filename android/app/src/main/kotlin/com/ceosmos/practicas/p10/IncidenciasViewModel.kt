package com.ceosmos.practicas.p10

import android.app.Application
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.ceosmos.practicas.FirebasePracticas
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import java.util.UUID

// Cada minuto se renueva la sesión; si un teléfono deja de latir 3 minutos, otro puede tomarla.
private const val LATIDO_MS = 60_000L
private const val VIGENCIA_SESION_MS = 3 * 60_000L

/**
 * Estado de la app. La identidad ya no es un nombre elegido en el teléfono: es la cuenta de
 * Firebase Authentication. Su UID se guarda como propietario (creadoPor) de cada incidencia y
 * las reglas de Firestore solo dejan leer y modificar las incidencias propias.
 */
class IncidenciasViewModel(app: Application) : AndroidViewModel(app) {

    private val _avisos = MutableSharedFlow<String>(extraBufferCapacity = 8)
    val avisos: SharedFlow<String> = _avisos

    // [CEOSMOS] App de Firebase con nombre «p10» en lugar de [DEFAULT] (google-services.json).
    val configurado = runCatching { FirebasePracticas.app(app, FirebasePracticas.P10) }.isSuccess
    private val repo by lazy { Repositorio(app) }
    val proyecto get() = if (configurado) repo.proyecto else ""
    val appId get() = if (configurado) repo.appId else ""
    val modelo = "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE}"

    // ----- Sesión ----------------------------------------------------------------

    var usuario by mutableStateOf<FirebaseUser?>(null)
        private set
    val uid get() = usuario?.uid.orEmpty()
    val correo get() = usuario?.email.orEmpty()

    var autenticando by mutableStateOf(false)
        private set
    var errorSesion by mutableStateOf<String?>(null)
        private set

    /** Resultado de intentar leer y escribir con la sesión cerrada (pantalla de inicio, SEG-10). */
    var pruebaSinSesion by mutableStateOf<String?>(null)
        private set

    private var escuchaSesion: FirebaseAuth.AuthStateListener? = null
    private var escuchaSesionActiva: ListenerRegistration? = null
    private var latidos: Job? = null

    /** UID cuya sesión se está reclamando (evita reclamarla dos veces). */
    private var validando: String? = null

    /** Identificador de esta instalación de la app (almacenamiento local, no se comparte). */
    private val instalacion: String = app.getSharedPreferences("p10_local", Context.MODE_PRIVATE) /* [CEOSMOS] archivo propio */.let { p ->
        p.getString("instalacion", null) ?: UUID.randomUUID().toString().also { p.edit().putString("instalacion", it).apply() }
    }
    val instalacionCorta get() = instalacion.take(8)

    /**
     * Copia local de los tickets que tenía la última cuenta que usó este teléfono. Se muestra en la
     * pantalla de inicio después de cerrar sesión. No se lee de Firestore (sin sesión las reglas lo
     * impiden, SEG-10): son los datos que este teléfono ya había recibido con la sesión abierta.
     */
    private val preferencias = app.getSharedPreferences("p10_local", Context.MODE_PRIVATE) /* [CEOSMOS] archivo propio */
    var ultimaSesion by mutableStateOf(ResumenSesion.leer(preferencias.getString("ultimaSesion", null)))
        private set

    private fun guardarResumen() {
        val u = usuario ?: return
        val tickets = incidencias.map {
            val rol = listOfNotNull("propia", it.cedidoPorCorreo.takeIf { c -> c.isNotEmpty() }?.let { c -> "cedida por $c" }, it.asignadoACorreo.takeIf { c -> c.isNotEmpty() }?.let { c -> "asignada a $c" })
            TicketResumen(it.titulo, it.estado.texto, it.prioridad.texto, rol.joinToString(" · "))
        } +
            asignadas.map { TicketResumen(it.titulo, it.estado.texto, it.prioridad.texto, "asignada por ${it.creadoPorCorreo}") }
        val r = ResumenSesion(u.email.orEmpty(), u.uid, System.currentTimeMillis(), tickets)
        ultimaSesion = r
        preferencias.edit().putString("ultimaSesion", r.aTexto()).apply()
    }

    fun iniciarSesion(correo: String, clave: String) = autenticar("Inicio de sesión", correo, clave) { c, k -> repo.iniciarSesion(c, k) }

    fun crearCuenta(correo: String, clave: String) = autenticar("Creación de cuenta", correo, clave) { c, k -> repo.crearCuenta(c, k) }

    private fun autenticar(operacion: String, correo: String, clave: String, accion: suspend (String, String) -> FirebaseUser) {
        val c = correo.trim()
        if (c.isEmpty() || clave.isEmpty()) {
            errorSesion = "Escribe el correo y la contraseña"
            return
        }
        autenticando = true
        errorSesion = null
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                val u = accion(c, clave)
                val ms = SystemClock.elapsedRealtime() - inicio
                registrar("✔ $operacion de $c aceptada por Firebase Authentication en $ms ms · UID ${u.uid}", TipoEvento.LOCAL)
                if (operacion == "Inicio de sesión") {
                    anotar("SEG-01", Respuesta.Permitida("signInWithEmailAndPassword($c): aceptado en $ms ms, UID ${u.uid}"), c)
                }
            } catch (e: Exception) {
                errorSesion = mensajeAuth(e)
                registrar("✖ $operacion de $c rechazada: ${mensajeAuth(e)}", TipoEvento.ERROR)
                Log.w(TAG_SEGURIDAD, "$operacion rechazada para $c", e)
                if (operacion == "Inicio de sesión" && e is FirebaseAuthException) {
                    anotar("SEG-02", respuestaDe(e, "signInWithEmailAndPassword($c, contraseña escrita)"), c)
                }
            } finally {
                autenticando = false
            }
        }
    }

    fun cerrarSesion() {
        val u = usuario ?: return
        viewModelScope.launch {
            // Se libera la sesión antes de salir para que la cuenta pueda abrirse en otro teléfono.
            try {
                repo.liberarSesion(u.uid, instalacion)
            } catch (e: Exception) {
                registrar("No se liberó la sesión (vencerá sola): ${mensajeFirestore(e)}", TipoEvento.AVISO)
            }
            guardarResumen()
            registrar("Sesión cerrada: ${u.email}", TipoEvento.LOCAL)
            repo.cerrarSesion()
        }
    }

    /** Con la sesión cerrada, intenta leer la colección y crear un documento con el cliente principal. */
    fun probarSinSesion() {
        if (usuario != null) return
        autenticando = true
        viewModelScope.launch {
            val lectura = try {
                Respuesta.Permitida("Lectura de $COLECCION_VISIBLE sin sesión: PERMITIDA (${repo.leerTodas().size()} documentos)")
            } catch (e: Exception) {
                respuestaDe(e, "Lectura de $COLECCION_VISIBLE sin sesión")
            }
            val escritura = try {
                val r = repo.crear(repo.nuevoId(), "SIN_SESION", "Intento sin iniciar sesión", Prioridad.BAJA, "sin-sesion", "", "sin-sesion")
                if (r == Escritura.CONFIRMADA) Respuesta.Permitida("Escritura sin sesión: PERMITIDA")
                else Respuesta.SinRespuesta("Escritura sin sesión: sin respuesta del servidor")
            } catch (e: Exception) {
                respuestaDe(e, "Escritura en $COLECCION_VISIBLE sin sesión")
            }
            pruebaSinSesion = "${lectura.detalle}\n${escritura.detalle}"
            anotar("SEG-10", combinar(lectura, escritura), "sin sesión")
            autenticando = false
        }
    }

    /**
     * Firebase Authentication permite varias sesiones de la misma cuenta. Antes de aceptar la
     * sesión se reclama en sesiones_p10/{uid}: si otro teléfono la tiene activa, se cierra aquí.
     */
    private fun alCambiarSesion(u: FirebaseUser?) {
        if (u?.uid == usuario?.uid || (u != null && u.uid == validando)) return
        if (u == null) {
            validando = null
            aceptarSesion(null)
            return
        }
        validando = u.uid
        autenticando = true
        viewModelScope.launch {
            val ocupada = try {
                repo.reclamarSesion(u.uid, instalacion, modelo, VIGENCIA_SESION_MS)
            } catch (e: Exception) {
                rechazarSesion(u, "No se pudo verificar la sesión: ${mensajeFirestore(e)}")
                return@launch
            } finally {
                autenticando = false
            }
            if (ocupada != null) {
                rechazarSesion(u, "La cuenta ${u.email} ya tiene una sesión activa en ${ocupada.equipo} (desde las ${hora(ocupada.inicio)}). Cierra sesión en ese dispositivo para entrar aquí.")
            } else {
                validando = null
                aceptarSesion(u)
            }
        }
    }

    private fun rechazarSesion(u: FirebaseUser, motivo: String) {
        validando = null
        errorSesion = motivo
        registrar("✖ Sesión de ${u.email} rechazada: $motivo", TipoEvento.ERROR)
        Log.w(TAG_SEGURIDAD, "Sesión rechazada para ${u.email}: $motivo")
        repo.cerrarSesion()
    }

    private fun aceptarSesion(u: FirebaseUser?) {
        detenerEscuchas()
        usuario = u
        incidencias = emptyList()
        anteriores = null
        asignadas = emptyList()
        asignadasAnteriores = null
        cargando = u != null
        errorLectura = null
        if (u == null) return
        pruebaSinSesion = null
        errorSesion = null
        Log.i(TAG_SEGURIDAD, "Sesión iniciada: ${u.email} · UID ${u.uid} · instalación $instalacion")
        pendientesMatriz.forEach(::guardarEnMatriz)
        pendientesMatriz.clear()
        latidos = viewModelScope.launch {
            while (true) {
                delay(LATIDO_MS)
                runCatching { repo.latido(u.uid) }
            }
        }
        escuchaSesionActiva = repo.escucharSesionActiva(u.uid) { s ->
            // Otra instalación tomó la cuenta (por ejemplo, después de que esta dejó de latir).
            if (s != null && s.instalacion != instalacion && usuario?.uid == u.uid) {
                errorSesion = "Se cerró la sesión: la cuenta se abrió en ${s.equipo}."
                registrar("Sesión cerrada: la cuenta se abrió en ${s.equipo}", TipoEvento.AVISO)
                repo.cerrarSesion()
            }
        }
        escucha = repo.escuchar(
            u.uid,
            alCambiar = { procesar(it) },
            alFallar = { e ->
                errorLectura = mensajeFirestore(e)
                registrar("Error de lectura: ${mensajeFirestore(e)}", TipoEvento.ERROR)
            },
        )
        escuchaAsignadas = repo.escucharAsignadas(
            u.uid,
            alCambiar = { procesarAsignadas(it) },
            alFallar = { e -> registrar("Error al leer las incidencias asignadas: ${mensajeFirestore(e)}", TipoEvento.ERROR) },
        )
        escuchaUsuarios = repo.escucharUsuarios(
            alCambiar = { usuarios = it },
            alFallar = { e -> registrar("Error al leer usuarios: ${mensajeFirestore(e)}", TipoEvento.ERROR) },
        )
        escuchaMatriz = repo.escucharMatriz(
            alCambiar = { matriz = it; errorMatriz = null },
            alFallar = { e -> errorMatriz = mensajeFirestore(e) },
        )
        publicarPerfil(null)
    }

    // ----- Datos ------------------------------------------------------------------

    var incidencias by mutableStateOf<List<Incidencia>>(emptyList())
        private set
    var cargando by mutableStateOf(false)
        private set
    var desdeCache by mutableStateOf(false)
        private set
    var ultimaLectura by mutableStateOf<Long?>(null)
        private set
    var errorLectura by mutableStateOf<String?>(null)
        private set

    /** Incidencias de otros usuarios asignadas a esta cuenta (consulta asignadoA == UID). */
    var asignadas by mutableStateOf<List<Incidencia>>(emptyList())
        private set

    /** Perfiles públicos (UID y correo) de todas las cuentas que han iniciado sesión. */
    var usuarios by mutableStateOf<List<Usuario>>(emptyList())
        private set
    val otro: Usuario? get() = usuarios.firstOrNull { it.uid != uid }
    /** Usuarios a los que se puede asignar una incidencia (todos menos la sesión). */
    val otros: List<Usuario> get() = usuarios.filter { it.uid != uid }
    /** La sesión seguida de los demás usuarios (para elegir propietario). */
    val todos: List<Usuario> get() = listOf(Usuario(uid, correo, modelo, emptyList())) + otros

    var matriz by mutableStateOf<Map<String, ResultadoSeguridad>>(emptyMap())
        private set
    var errorMatriz by mutableStateOf<String?>(null)
        private set

    /** Resultado visible de la última operación de escritura. */
    var ultimaOperacion by mutableStateOf<Evento?>(null)
        private set

    val eventos = mutableStateListOf<Evento>()

    private var escucha: ListenerRegistration? = null
    private var escuchaAsignadas: ListenerRegistration? = null
    private var escuchaUsuarios: ListenerRegistration? = null
    private var escuchaMatriz: ListenerRegistration? = null
    private var anteriores: Map<String, Incidencia>? = null
    private var asignadasAnteriores: Map<String, Incidencia>? = null
    private var incidenciasPublicadas: List<String>? = null

    private fun detenerEscuchas() {
        listOf(escucha, escuchaAsignadas, escuchaUsuarios, escuchaMatriz, escuchaSesionActiva).forEach { it?.remove() }
        escucha = null; escuchaAsignadas = null; escuchaUsuarios = null; escuchaMatriz = null; escuchaSesionActiva = null
        latidos?.cancel()
        latidos = null
        usuarios = emptyList()
        matriz = emptyMap()
        incidenciasPublicadas = null
    }

    // ----- Red -----------------------------------------------------------------

    var enLinea by mutableStateOf(true)
        private set
    private val red = app.getSystemService(ConnectivityManager::class.java)
    private val vigilanteRed = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = actualizarRed()
        override fun onLost(network: Network) = actualizarRed()
        override fun onCapabilitiesChanged(network: Network, capacidades: NetworkCapabilities) = actualizarRed()
    }

    private fun actualizarRed() {
        viewModelScope.launch { enLinea = hayInternet() }
    }

    private fun hayInternet(): Boolean =
        red.getNetworkCapabilities(red.activeNetwork)?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true

    init {
        enLinea = hayInternet()
        runCatching { red.registerDefaultNetworkCallback(vigilanteRed) }
        if (configurado) escuchaSesion = repo.escucharSesion { viewModelScope.launch { alCambiarSesion(it) } }
    }

    private fun procesar(instantanea: Instantanea) {
        val nuevas = instantanea.incidencias
        val previas = anteriores
        incidencias = nuevas
        desdeCache = instantanea.desdeCache
        ultimaLectura = System.currentTimeMillis()
        cargando = false
        errorLectura = null
        anteriores = nuevas.associateBy { it.id }
        if (previas == null) {
            registrar("Incidencias de $correo: ${nuevas.size} (consulta filtrada por creadoPor = UID)", TipoEvento.LOCAL)
        } else {
            nuevas.filter { previas[it.id]?.pendiente == true && !it.pendiente }
                .forEach { registrar("Escritura confirmada por el servidor: ${it.titulo} (v${it.version})", TipoEvento.LOCAL) }
            // Cambios hechos por el usuario asignado (solo puede tocar el estado).
            nuevas.filter { n -> previas[n.id]?.let { it.version != n.version } == true && n.actualizadoPor != uid && !n.pendiente }.forEach {
                registrar("${it.asignadoACorreo.ifEmpty { it.actualizadoPor }} cambió el estado de ${it.titulo} a ${it.estado.texto}", TipoEvento.REMOTO)
                _avisos.tryEmit("${it.titulo}: ${it.estado.texto}")
            }
            // Incidencia que llega ya siendo mía porque otro usuario me la cedió.
            nuevas.filter { it.id !in previas && it.cedida && it.cedidoPor != uid }.forEach {
                registrar("📦 ${it.cedidoPorCorreo} te cedió la incidencia ${it.titulo}: ahora eres su propietario", TipoEvento.REMOTO)
                _avisos.tryEmit("${it.cedidoPorCorreo} te cedió: ${it.titulo}")
            }
        }
        // Los id de las incidencias propias sin asignar se publican para que el otro usuario intente
        // leerlas, modificarlas o borrarlas (SEG-05/06/07). Las asignadas no: el asignado sí puede leerlas.
        val publicables = nuevas.filter { !it.pendiente && !it.asignada }.sortedBy { it.creadoEn ?: Long.MAX_VALUE }.map { it.id }.take(10)
        if (publicables != incidenciasPublicadas) publicarPerfil(publicables)
        guardarResumen()
    }

    /** Avisa cuando otro usuario asigna (o retira) una incidencia a esta cuenta. */
    private fun procesarAsignadas(instantanea: Instantanea) {
        val nuevas = instantanea.incidencias
        val previas = asignadasAnteriores
        asignadas = nuevas
        asignadasAnteriores = nuevas.associateBy { it.id }
        if (previas == null) {
            registrar("Incidencias asignadas a $correo: ${nuevas.size} (consulta filtrada por asignadoA = UID)", TipoEvento.LOCAL)
            return
        }
        nuevas.filter { it.id !in previas }.forEach {
            registrar("📥 ${it.creadoPorCorreo} te asignó la incidencia ${it.titulo} (${it.prioridad.texto})", TipoEvento.REMOTO)
            _avisos.tryEmit("${it.creadoPorCorreo} te asignó: ${it.titulo}")
        }
        previas.values.filter { p -> nuevas.none { it.id == p.id } }.forEach {
            registrar("Ya no tienes asignada la incidencia ${it.titulo} de ${it.creadoPorCorreo}", TipoEvento.AVISO)
        }
        nuevas.filter { n -> previas[n.id]?.let { it.prioridad != n.prioridad && !n.pendiente } == true }.forEach {
            registrar("${it.creadoPorCorreo} cambió la prioridad de ${it.titulo} a ${it.prioridad.texto}", TipoEvento.REMOTO)
        }
        nuevas.filter { n -> previas[n.id]?.let { !it.puedeEditar && n.puedeEditar } == true }.forEach {
            registrar("${it.creadoPorCorreo} te dio permiso de editar ${it.titulo}", TipoEvento.REMOTO)
            _avisos.tryEmit("Ya puedes editar ${it.titulo}")
        }
        guardarResumen()
    }

    /** [ids] null publica el perfil sin tocar la lista de incidencias. */
    private fun publicarPerfil(ids: List<String>?) {
        val u = usuario ?: return
        if (ids != null) incidenciasPublicadas = ids
        viewModelScope.launch {
            try {
                repo.publicarPerfil(u.uid, u.email.orEmpty(), modelo, ids)
            } catch (e: Exception) {
                registrar("No se publicó el perfil: ${mensajeFirestore(e)}", TipoEvento.ERROR)
            }
        }
    }

    // ----- Alta, edición y eliminación -------------------------------------------
    // La interfaz no bloquea las operaciones no autorizadas: las envía y es Firestore quien las
    // rechaza. Cada intento se anota en la matriz con el caso SEG que le corresponde.

    var guardando by mutableStateOf(false)
        private set

    /** Los diálogos tapan el snackbar: las validaciones se muestran como resultado dentro del diálogo. */
    private fun avisoEnDialogo(texto: String) {
        ultimaOperacion = Evento(System.currentTimeMillis(), "⚠ $texto", TipoEvento.AVISO)
        _avisos.tryEmit(texto)
    }

    /** Inicia una prueba nueva: el resultado que muestran los diálogos es solo el de esa prueba. */
    fun limpiarOperacion() {
        ultimaOperacion = null
    }

    /** [propietario] es el UID que se escribe en creadoPor: elegir el del otro usuario es la prueba SEG-04. */
    /**
     * [propietario] distinto de la sesión sin [cedido] es la prueba SEG-04 (debe rechazarse). Con
     * [cedido] la incidencia se crea directamente para el otro usuario con la cesión registrada.
     */
    fun crear(titulo: String, descripcion: String, prioridad: Prioridad, propietario: Usuario, asignado: Usuario?, cedido: Usuario?, alTerminar: (Boolean) -> Unit) {
        if (usuario == null) return
        val t = titulo.trim()
        val invalido = when {
            t.isEmpty() -> "El título es obligatorio"
            t.length > 60 -> "El título admite máximo 60 caracteres"
            incidencias.any { it.titulo.equals(t, ignoreCase = true) } -> "Ya tienes una incidencia con el título $t"
            else -> null
        }
        if (invalido != null) {
            avisoEnDialogo(invalido)
            alTerminar(false)
            return
        }
        val casos = when {
            cedido != null -> listOf("SEG-15")
            propietario.uid != uid -> listOf("SEG-04")
            asignado != null -> listOf("SEG-03", "SEG-11")
            else -> listOf("SEG-03")
        }
        val id = repo.nuevoId()
        val extra = asignado?.let { ", asignadoA = ${it.correo}" }.orEmpty()
        val yo = Usuario(uid, correo, modelo, emptyList())
        val duenio = cedido ?: propietario
        val nombre = if (cedido != null) "Alta de $t cedida a ${cedido.correo} (creadoPor = ${cedido.correo}, cedidoPor = $correo, id $id)"
            else "Alta de $t (creadoPor = ${propietario.correo}$extra, id $id)"
        operacion(nombre, casos, alTerminar) {
            repo.crear(id, t, descripcion.trim(), prioridad, duenio.uid, duenio.correo, uid, asignado.takeIf { cedido == null }, yo.takeIf { cedido != null })
        }
    }

    var editando by mutableStateOf<Incidencia?>(null)
        private set
    var estadoEditado by mutableStateOf(Estado.PENDIENTE)
    var prioridadEditada by mutableStateOf(Prioridad.MEDIA)
    /** UID del usuario asignado en el editor ("" = sin asignar). */
    var asignadoEditado by mutableStateOf("")
    /** UID del propietario en el editor: cambiarlo es la prueba SEG-09 (o SEG-14 si eres el asignado). */
    var propietarioEditado by mutableStateOf("")
    /** UID al que se cede al guardar ("" = no ceder). */
    var cedidoEditado by mutableStateOf("")
    var puedeEditarEditado by mutableStateOf(false)

    /** El propietario edita estado, prioridad y asignación; el asignado solo el estado (lo exigen las reglas). */
    val editandoPropia get() = editando?.creadoPor == uid

    fun abrir(incidencia: Incidencia) {
        ultimaOperacion = null
        editando = incidencia
        estadoEditado = incidencia.estado
        prioridadEditada = incidencia.prioridad
        asignadoEditado = incidencia.asignadoA
        propietarioEditado = incidencia.creadoPor
        cedidoEditado = ""
        puedeEditarEditado = incidencia.puedeEditar
        // SEG-12: al abrir una incidencia asignada se lee directamente del servidor.
        if (incidencia.creadoPor != uid) {
            viewModelScope.launch {
                val op = "get $COLECCION_VISIBLE/${incidencia.id} (propietario ${incidencia.creadoPorCorreo}, asignada a ti)"
                anotar("SEG-12", try {
                    repo.leer(incidencia.id)
                    Respuesta.Permitida("$op: leída del servidor")
                } catch (e: Exception) {
                    respuestaDe(e, op)
                })
            }
        }
    }

    fun cerrarEditor() {
        editando = null
    }

    fun guardarEdicion() {
        val original = editando ?: return
        val campos = buildMap<String, Any> {
            if (estadoEditado != original.estado) put("estado", estadoEditado.texto)
            if (prioridadEditada != original.prioridad) put("prioridad", prioridadEditada.texto)
            if (asignadoEditado != original.asignadoA) {
                putAll(camposAsignacion(asignadoEditado.takeIf { it.isNotEmpty() }?.let { usuarioPor(it, original.asignadoACorreo) }))
            }
            if (puedeEditarEditado != original.puedeEditar) put("puedeEditar", puedeEditarEditado)
            if (propietarioEditado != original.creadoPor) {
                put("creadoPor", propietarioEditado)
                put("creadoPorCorreo", usuarioPor(propietarioEditado, original.creadoPorCorreo).correo)
            }
        }
        if (cedidoEditado.isNotEmpty() && editandoPropia) {
            ceder(original, usuarioPor(cedidoEditado, ""))
            return
        }
        if (campos.isEmpty()) {
            avisoEnDialogo("No modificaste ningún campo")
            return
        }
        val caso = when {
            !editandoPropia -> when {
                campos.keys == setOf("estado") -> "SEG-13"
                original.puedeEditar && "prioridad" in campos && campos.keys.all { it == "estado" || it == "prioridad" } -> "SEG-16"
                else -> "SEG-14"
            }
            "creadoPor" in campos -> "SEG-09"
            (campos["asignadoA"] as? String)?.isNotEmpty() == true -> "SEG-11"
            "estado" in campos -> "SEG-08"
            else -> null
        }
        val descripcion = campos.entries.filter { it.key !in setOf("asignadoA", "creadoPor") }.joinToString {
            when (it.key) {
                "asignadoACorreo" -> "asignadoA → ${(it.value as String).ifEmpty { "nadie" }}"
                "creadoPorCorreo" -> "creadoPor → ${it.value}"
                else -> "${it.key} → ${it.value}"
            }
        }
        operacion("Actualización de ${original.titulo}: $descripcion", listOfNotNull(caso), { if (it) cerrarEditor() }) {
            repo.actualizar(original.id, campos, uid)
        }
    }

    fun eliminar(incidencia: Incidencia) {
        val casos = if (incidencia.creadoPor == uid) emptyList() else listOf("SEG-14")
        operacion("Eliminación de ${incidencia.titulo} (propietario ${incidencia.creadoPorCorreo})", casos, { if (it) cerrarEditor() }) {
            repo.eliminar(incidencia.id)
        }
    }

    /** Cede la incidencia: [destino] pasa a ser el propietario y desaparece de esta cuenta (SEG-15). */
    private fun ceder(original: Incidencia, destino: Usuario) =
        operacion("Cesión de ${original.titulo} a ${destino.correo} (creadoPor → ${destino.correo}, cedidoPor = $correo)", listOf("SEG-15"), { if (it) cerrarEditor() }) {
            repo.ceder(original.id, destino, Usuario(uid, correo, modelo, emptyList()))
        }

    /** Perfil conocido de [uid]; si no se ha cargado se arma con el correo que guarda la incidencia. */
    private fun usuarioPor(uid: String, correoConocido: String): Usuario =
        todos.firstOrNull { it.uid == uid } ?: Usuario(uid, correoConocido, "", emptyList())

    // ----- Incidencias de otros usuarios (SEG-05, SEG-06, SEG-07) ------------------------

    /** Incidencias del otro usuario de las que solo se conoce el id publicado en su perfil. */
    val ajenas: List<IncidenciaAjena>
        get() = otros.flatMap { u -> u.incidencias.map { IncidenciaAjena(it, u) } }
            .filter { a -> asignadas.none { it.id == a.id } }

    var ajena by mutableStateOf<IncidenciaAjena?>(null)
        private set

    fun abrirAjena(a: IncidenciaAjena) {
        ultimaOperacion = null
        ajena = a
    }

    fun cerrarAjena() {
        ajena = null
    }

    fun leerAjena() {
        val a = ajena ?: return
        val op = "Lectura de $COLECCION_VISIBLE/${a.id} (propietario ${a.propietario.correo})"
        guardando = true
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            val respuesta = try {
                val d = repo.leer(a.id)
                Respuesta.Permitida("$op: confirmada por el servidor (título ${d.getString("titulo")})")
            } catch (e: Exception) {
                respuestaDe(e, op)
            }
            val ms = SystemClock.elapsedRealtime() - inicio
            ultimaOperacion = when (respuesta) {
                is Respuesta.Permitida -> registrar("✔ ${respuesta.detalle} en $ms ms", TipoEvento.LOCAL)
                else -> registrar("✖ $op — rechazada en $ms ms: ${respuesta.detalle.substringAfter(": ")}", TipoEvento.ERROR)
            }
            anotar("SEG-05", respuesta)
            guardando = false
        }
    }

    fun modificarAjena(estado: Estado) {
        val a = ajena ?: return
        operacion("Actualización de $COLECCION_VISIBLE/${a.id} (propietario ${a.propietario.correo}): estado → ${estado.texto}", listOf("SEG-06"), {}) {
            repo.actualizar(a.id, mapOf("estado" to estado.texto), uid)
        }
    }

    fun eliminarAjena() {
        val a = ajena ?: return
        operacion("Eliminación de $COLECCION_VISIBLE/${a.id} (propietario ${a.propietario.correo})", listOf("SEG-07"), {}) {
            repo.eliminar(a.id)
        }
    }

    /**
     * Ejecuta una escritura, deja en la bitácora si fue confirmada, quedó en cola o fue rechazada,
     * y anota el resultado en los [casos] de la matriz a los que corresponde.
     */
    private fun operacion(nombre: String, casos: List<String>, alTerminar: (Boolean) -> Unit, accion: suspend () -> Escritura) {
        guardando = true
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                val escritura = accion()
                val ms = SystemClock.elapsedRealtime() - inicio
                if (escritura == Escritura.CONFIRMADA) {
                    ultimaOperacion = registrar("✔ $nombre — confirmada por el servidor en $ms ms", TipoEvento.LOCAL)
                    casos.forEach { anotar(it, Respuesta.Permitida("$nombre: confirmada por el servidor en $ms ms")) }
                    _avisos.tryEmit("Guardado en Firestore ($ms ms)")
                } else {
                    // Sin respuesta del servidor no hay evidencia: no se anota en la matriz.
                    ultimaOperacion = registrar("⚠ $nombre — SIN confirmar: quedó en la cola local", TipoEvento.AVISO)
                    _avisos.tryEmit("Sin conexión: pendiente de sincronizar")
                }
                alTerminar(true)
            } catch (e: Exception) {
                val ms = SystemClock.elapsedRealtime() - inicio
                ultimaOperacion = registrar("✖ $nombre — rechazada en $ms ms: ${mensajeFirestore(e)}", TipoEvento.ERROR)
                Log.w(TAG_SEGURIDAD, "$nombre rechazada", e)
                val respuesta = respuestaDe(e, "$nombre (${ms} ms)")
                casos.forEach { anotar(it, respuesta) }
                _avisos.tryEmit("Rechazada: ${mensajeFirestore(e)}")
                alTerminar(false)
            } finally {
                guardando = false
            }
        }
    }

    // ----- Matriz de pruebas (se llena con las pruebas manuales) ---------------------

    /** Resultados de este dispositivo en esta sesión (la matriz compartida guarda el último de cada caso). */
    var resultados by mutableStateOf<Map<String, ResultadoSeguridad>>(emptyMap())
        private set

    /** Resultados obtenidos sin sesión (SEG-01, SEG-02, SEG-10): se guardan en la matriz al iniciar sesión. */
    private val pendientesMatriz = mutableListOf<ResultadoSeguridad>()

    private fun anotar(casoId: String, respuesta: Respuesta, actor: String = correo) {
        val caso = CASOS_SEGURIDAD.first { it.id == casoId }
        val r = evaluar(caso, respuesta, actor)
        resultados = resultados + (casoId to r)
        Log.i(TAG_SEGURIDAD, "$casoId ${if (r.paso) "PASÓ" else "FALLÓ"} · ${r.evidencia}")
        registrar("$casoId ${if (r.paso) "PASÓ" else "FALLÓ"} · ${r.evidencia}", if (r.paso) TipoEvento.REMOTO else TipoEvento.ERROR)
        if (usuario == null) pendientesMatriz += r else guardarEnMatriz(r)
    }

    private fun guardarEnMatriz(r: ResultadoSeguridad) {
        viewModelScope.launch {
            try {
                repo.registrarResultado(r, uid)
            } catch (e: Exception) {
                registrar("No se guardó ${r.caso} en la matriz: ${mensajeFirestore(e)}", TipoEvento.ERROR)
            }
        }
    }

    // ----- Bitácora -----------------------------------------------------------------

    private fun registrar(texto: String, tipo: TipoEvento): Evento {
        val evento = Evento(System.currentTimeMillis(), texto, tipo)
        eventos.add(0, evento)
        if (eventos.size > 300) eventos.removeAt(eventos.lastIndex)
        return evento
    }

    fun limpiarBitacora() = eventos.clear()

    override fun onCleared() {
        detenerEscuchas()
        escuchaSesion?.let { repo.dejarDeEscucharSesion(it) }
        runCatching { red.unregisterNetworkCallback(vigilanteRed) }
    }
}
