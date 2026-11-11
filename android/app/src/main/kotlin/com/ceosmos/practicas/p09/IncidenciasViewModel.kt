package com.ceosmos.practicas.p09

import android.app.Application
import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.SystemClock
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.ceosmos.practicas.FirebasePracticas
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch

/**
 * Estado de la app. Distingue los dos tipos de almacenamiento de la práctica:
 *  - Local (SharedPreferences): nombre de este dispositivo y política de actualización.
 *    Solo existe en este teléfono.
 *  - Compartido (Cloud Firestore): colección "incidencias" y matriz de pruebas. Es la misma
 *    para todos los dispositivos que usan el mismo proyecto de Firebase.
 */
class IncidenciasViewModel(app: Application) : AndroidViewModel(app) {

    private val preferencias = app.getSharedPreferences("p09_local", Context.MODE_PRIVATE) // [CEOSMOS] archivo propio
    private val _avisos = MutableSharedFlow<String>(extraBufferCapacity = 8)
    val avisos: SharedFlow<String> = _avisos

    // [CEOSMOS] App de Firebase con nombre «p09» en lugar de [DEFAULT] (google-services.json).
    val configurado = runCatching { FirebasePracticas.app(app, FirebasePracticas.P09) }.isSuccess
    private val repo by lazy {
        Repositorio(FirebaseFirestore.getInstance(FirebasePracticas.app(app, FirebasePracticas.P09)))
    }
    val proyecto get() = if (configurado) repo.proyecto else ""
    val appId get() = if (configurado) repo.appId else ""
    val modelo = "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE}"

    // ----- Almacenamiento local ----------------------------------------------

    var miNombre by mutableStateOf(preferencias.getString("nombre", "").orEmpty())
        private set
    var politica by mutableStateOf(Politica.valueOf(preferencias.getString("politica", Politica.CAMPOS.name)!!))
        private set

    fun cambiarNombre(nombre: String) {
        val limpio = nombre.trim()
        if (limpio.isEmpty()) {
            _avisos.tryEmit("Escribe un nombre para este dispositivo")
            return
        }
        miNombre = limpio
        preferencias.edit().putString("nombre", limpio).apply()
        registrar("Este teléfono se identifica como \"$limpio\" (guardado en almacenamiento local)", TipoEvento.LOCAL)
    }

    fun cambiarPolitica(nueva: Politica) {
        politica = nueva
        preferencias.edit().putString("politica", nueva.name).apply()
        registrar("Política de actualización: ${nueva.titulo}", TipoEvento.LOCAL)
    }

    // ----- Datos compartidos -------------------------------------------------

    var incidencias by mutableStateOf<List<Incidencia>>(emptyList())
        private set
    var cargando by mutableStateOf(true)
        private set
    var desdeCache by mutableStateOf(false)
        private set
    var ultimaLectura by mutableStateOf<Long?>(null)
        private set
    var tiempoReal by mutableStateOf(true)
        private set
    var consultando by mutableStateOf(false)
        private set
    var errorLectura by mutableStateOf<String?>(null)
        private set
    val pendientes get() = incidencias.count { it.pendiente }

    var matriz by mutableStateOf<Map<String, RegistroMatriz>>(emptyMap())
        private set
    var errorMatriz by mutableStateOf<String?>(null)
        private set

    /** Resultado visible de la última operación de escritura (Fase 2, paso 2). */
    var ultimaOperacion by mutableStateOf<Evento?>(null)
        private set

    val eventos = mutableStateListOf<Evento>()

    private var escucha: ListenerRegistration? = null
    private var escuchaMatriz: ListenerRegistration? = null
    private var anteriores: Map<String, Incidencia>? = null
    private val eliminadasPorMi = mutableSetOf<String>()

    /** Hora local en que se envió cada escritura propia, para estimar el desfase del reloj. */
    private val envios = mutableMapOf<String, Long>()

    /**
     * Diferencia entre el reloj del servidor y el de este teléfono (ms, positivo = el teléfono va
     * atrasado). Se estima con las escrituras propias: el servidor les pone su hora entre el envío
     * y la confirmación. Sirve para medir sin error de reloj cuánto tarda en llegar un cambio.
     */
    var desfaseReloj by mutableStateOf<Long?>(null)
        private set

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
        viewModelScope.launch {
            val ahora = hayInternet()
            if (ahora == enLinea) return@launch
            enLinea = ahora
            if (ahora) registrar("Conexión restablecida: Firestore envía las escrituras en cola", TipoEvento.AVISO)
            else registrar("Sin conexión: las escrituras quedarán en la cola local", TipoEvento.AVISO)
        }
    }

    private fun hayInternet(): Boolean =
        red.getNetworkCapabilities(red.activeNetwork)?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true

    init {
        enLinea = hayInternet()
        runCatching { red.registerDefaultNetworkCallback(vigilanteRed) }
        if (configurado) {
            cambiarTiempoReal(true)
            escuchaMatriz = repo.escucharMatriz(
                alCambiar = { matriz = it; errorMatriz = null },
                alFallar = { e ->
                    errorMatriz = mensajeError(e)
                    registrar("Error al leer la matriz: ${mensajeError(e)}", TipoEvento.ERROR)
                },
            )
        } else {
            cargando = false
        }
    }

    /** Tiempo real (listener) o consulta manual con el botón Consultar. */
    fun cambiarTiempoReal(activo: Boolean) {
        tiempoReal = activo
        escucha?.remove()
        escucha = null
        if (activo) {
            escucha = repo.escuchar(
                alCambiar = { procesar(it, "tiempo real") },
                alFallar = { e ->
                    errorLectura = mensajeError(e)
                    registrar("Error de lectura: ${mensajeError(e)}", TipoEvento.ERROR)
                },
            )
            registrar("Modo tiempo real activado (listener de Firestore)", TipoEvento.LOCAL)
        } else {
            registrar("Modo manual: la lista solo cambia al pulsar Consultar", TipoEvento.LOCAL)
        }
    }

    fun consultar() {
        if (consultando) return
        consultando = true
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                val instantanea = repo.consultar()
                procesar(instantanea, "consulta manual")
                val origen = if (instantanea.desdeCache) "caché local (sin conexión)" else "servidor"
                registrar("Consulta: ${instantanea.incidencias.size} incidencias desde $origen en ${SystemClock.elapsedRealtime() - inicio} ms", TipoEvento.LOCAL)
                _avisos.tryEmit("Consulta desde $origen: ${instantanea.incidencias.size} incidencias")
            } catch (e: Exception) {
                registrar("Consulta fallida: ${mensajeError(e)}", TipoEvento.ERROR)
                _avisos.tryEmit("No se pudo consultar: ${mensajeError(e)}")
            } finally {
                consultando = false
            }
        }
    }

    /**
     * Compara la nueva lista con la anterior para registrar en la bitácora qué llegó de otro
     * dispositivo, qué escritura local se confirmó y cuánto tardó en propagarse.
     */
    private fun procesar(instantanea: Instantanea, origen: String) {
        val nuevas = instantanea.incidencias
        val previas = anteriores
        if (instantanea.desdeCache != desdeCache && previas != null) {
            registrar(if (instantanea.desdeCache) "Datos servidos desde la caché local (aún sin confirmar con el servidor)" else "Lectura sincronizada con el servidor", TipoEvento.AVISO)
        }
        incidencias = nuevas
        desdeCache = instantanea.desdeCache
        ultimaLectura = System.currentTimeMillis()
        cargando = false
        errorLectura = null
        anteriores = nuevas.associateBy { it.id }

        if (previas == null) {
            val fuente = if (instantanea.desdeCache) "caché" else "servidor"
            registrar("Estado inicial de \"$COLECCION\": ${nuevas.size} documentos ($fuente, $origen)", TipoEvento.LOCAL)
            return
        }
        for (b in nuevas) {
            val a = previas[b.id]
            when {
                a == null && b.pendiente -> Unit // creada aquí; se registra al guardar
                a == null && b.creadoPor == miNombre -> {
                    estimarDesfase(b)
                    registrar("Confirmada en el servidor: ${b.titulo}", TipoEvento.LOCAL)
                }
                a == null -> registrar("Nueva desde ${b.creadoPor}: ${b.titulo} (${origen}${latencia(b.creadoEn)})", TipoEvento.REMOTO)
                a.pendiente && !b.pendiente -> {
                    estimarDesfase(b)
                    registrar("Escritura confirmada por el servidor: ${b.titulo} (v${b.version})", TipoEvento.LOCAL)
                }
                !b.pendiente && b.actualizadoPor != miNombre && diferencias(a, b).isNotEmpty() ->
                    registrar("Cambio desde ${b.actualizadoPor} en ${b.titulo}: ${diferencias(a, b)} (v${b.version}, ${origen}${latencia(b.actualizadoEn)})", TipoEvento.REMOTO)
            }
        }
        val ids = nuevas.map { it.id }.toSet()
        previas.values.filter { it.id !in ids }.forEach {
            if (!eliminadasPorMi.remove(it.id)) registrar("Eliminada en otro dispositivo: ${it.titulo}", TipoEvento.REMOTO)
        }
    }

    private fun diferencias(a: Incidencia, b: Incidencia) = buildList {
        if (a.titulo != b.titulo) add("título → ${b.titulo}")
        if (a.estado != b.estado) add("estado ${a.estado.texto} → ${b.estado.texto}")
        if (a.prioridad != b.prioridad) add("prioridad ${a.prioridad.texto} → ${b.prioridad.texto}")
    }.joinToString(", ")

    private fun estimarDesfase(confirmada: Incidencia) {
        val envio = envios.remove(confirmada.id) ?: return
        val servidor = confirmada.actualizadoEn ?: return
        val estimado = servidor - (envio + System.currentTimeMillis()) / 2
        if (desfaseReloj == null) registrar("Desfase del reloj de este teléfono con el servidor: ${"%+.1f".format(estimado / 1000.0)} s", TipoEvento.LOCAL)
        desfaseReloj = estimado
    }

    /** Tiempo entre la escritura en el servidor y su llegada aquí, corrigiendo el reloj del teléfono. */
    private fun latencia(horaServidor: Long?): String {
        val ms = System.currentTimeMillis() + (desfaseReloj ?: 0L) - (horaServidor ?: return "")
        val nota = if (desfaseReloj == null) ", reloj sin corregir" else ""
        return if (ms in -2_000..600_000) " · llegó ≈ ${"%.1f".format(ms.coerceAtLeast(0) / 1000.0)} s después de guardarse$nota" else ""
    }

    // ----- Alta ----------------------------------------------------------------

    var guardando by mutableStateOf(false)
        private set

    /** [alTerminar] recibe true si la incidencia se envió (confirmada o en cola) para cerrar el formulario. */
    fun crear(titulo: String, descripcion: String, prioridad: Prioridad, alTerminar: (Boolean) -> Unit) {
        val t = titulo.trim()
        val invalido = when {
            t.isEmpty() -> "El título es obligatorio"
            t.length > 60 -> "El título admite máximo 60 caracteres"
            incidencias.any { it.titulo.equals(t, ignoreCase = true) } -> "Ya existe una incidencia con el título $t"
            else -> null
        }
        if (invalido != null) {
            _avisos.tryEmit(invalido)
            alTerminar(false)
            return
        }
        guardando = true
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                val id = repo.nuevoId()
                envios[id] = System.currentTimeMillis()
                val escritura = repo.crear(id, t, descripcion.trim(), prioridad, miNombre)
                informar(escritura, "Alta de $t (id $id)", SystemClock.elapsedRealtime() - inicio)
                alTerminar(true)
            } catch (e: Exception) {
                fallo("Alta de $t", e)
                alTerminar(false)
            } finally {
                guardando = false
            }
        }
    }

    // ----- Edición, conflictos y eliminación -----------------------------------

    /** Registro abierto tal como estaba al abrirlo (base para detectar conflictos). */
    var editando by mutableStateOf<Incidencia?>(null)
        private set
    var estadoEditado by mutableStateOf(Estado.PENDIENTE)
    var prioridadEditada by mutableStateOf(Prioridad.MEDIA)
    var conflicto by mutableStateOf<ResultadoGuardado.Conflicto?>(null)
        private set

    /** Versión actual del registro abierto según la última lectura (puede ser más nueva). */
    val editandoActual get() = editando?.let { e -> incidencias.firstOrNull { it.id == e.id } }

    fun abrir(incidencia: Incidencia) {
        editando = incidencia
        estadoEditado = incidencia.estado
        prioridadEditada = incidencia.prioridad
        conflicto = null
        registrar("Abierta para editar: ${incidencia.titulo} (v${incidencia.version}, ${incidencia.estado.texto}, ${incidencia.prioridad.texto})", TipoEvento.LOCAL)
    }

    fun cerrarEditor() {
        editando = null
        conflicto = null
    }

    fun guardarEdicion(forzar: Boolean = false) {
        val original = editando ?: return
        guardando = true
        conflicto = null
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                envios[original.id] = System.currentTimeMillis()
                when (val r = repo.guardar(original, estadoEditado, prioridadEditada, miNombre, politica, enLinea, forzar)) {
                    is ResultadoGuardado.Guardado -> {
                        // Solo se describen los campos escritos: el resto del documento puede
                        // tener valores de otro dispositivo que no se tocaron.
                        val escritos = r.campos.joinToString { campo ->
                            if (campo == "estado") "estado → ${estadoEditado.texto}" else "prioridad → ${prioridadEditada.texto}"
                        }
                        val modo = when {
                            politica == Politica.ULTIMA_ESCRITURA -> "documento completo sobrescrito (${estadoEditado.texto} / ${prioridadEditada.texto})"
                            r.verificado -> "solo $escritos, sin conflicto${if (forzar) " (forzado)" else ""}"
                            else -> "solo $escritos, sin verificar conflicto (sin conexión)"
                        }
                        informar(r.escritura, "Actualización de ${original.titulo}: $modo", SystemClock.elapsedRealtime() - inicio)
                        cerrarEditor()
                    }
                    is ResultadoGuardado.Conflicto -> {
                        conflicto = r
                        registrar("Conflicto en ${original.titulo}: ${r.remota.actualizadoPor} ya cambió ${r.campos.joinToString()} (v${original.version} → v${r.remota.version})", TipoEvento.AVISO)
                    }
                    ResultadoGuardado.SinCambios -> _avisos.tryEmit("No modificaste ningún campo")
                    ResultadoGuardado.NoExiste -> {
                        registrar("No se guardó ${original.titulo}: fue eliminada en otro dispositivo", TipoEvento.ERROR)
                        _avisos.tryEmit("La incidencia ya no existe: otro dispositivo la eliminó")
                        cerrarEditor()
                    }
                }
            } catch (e: Exception) {
                fallo("Actualización de ${original.titulo}", e)
            } finally {
                guardando = false
            }
        }
    }

    /** Conflicto: se descartan los cambios propios y se recarga el valor remoto. */
    fun aceptarRemoto() {
        val remota = conflicto?.remota ?: return
        registrar("Conflicto resuelto: se conservan los valores de ${remota.actualizadoPor}", TipoEvento.LOCAL)
        abrir(remota)
    }

    fun eliminar(incidencia: Incidencia) {
        guardando = true
        eliminadasPorMi += incidencia.id
        viewModelScope.launch {
            val inicio = SystemClock.elapsedRealtime()
            try {
                informar(repo.eliminar(incidencia.id), "Eliminación de ${incidencia.titulo}", SystemClock.elapsedRealtime() - inicio)
                cerrarEditor()
            } catch (e: Exception) {
                eliminadasPorMi -= incidencia.id
                fallo("Eliminación de ${incidencia.titulo}", e)
            } finally {
                guardando = false
            }
        }
    }

    // ----- Matriz de pruebas -----------------------------------------------------

    fun registrarPrueba(caso: CasoPrueba, resultado: String, observacion: String) {
        viewModelScope.launch {
            try {
                val escritura = repo.registrarPrueba(caso.id, resultado, observacion.trim(), miNombre)
                _avisos.tryEmit(if (escritura == Escritura.CONFIRMADA) "${caso.id} registrado: $resultado" else "${caso.id} en cola: se guardará al reconectar")
            } catch (e: Exception) {
                _avisos.tryEmit("No se registró ${caso.id}: ${mensajeError(e)}")
            }
        }
    }

    // ----- Resultados y bitácora -------------------------------------------------

    private fun informar(escritura: Escritura, operacion: String, ms: Long) {
        val evento = if (escritura == Escritura.CONFIRMADA) {
            registrar("✔ $operacion — confirmada por el servidor en $ms ms", TipoEvento.LOCAL)
        } else {
            registrar("⚠ $operacion — SIN confirmar: quedó en la cola local y se enviará al reconectar", TipoEvento.AVISO)
        }
        ultimaOperacion = evento
        _avisos.tryEmit(if (escritura == Escritura.CONFIRMADA) "Guardado en Firestore ($ms ms)" else "Sin conexión: guardado solo en este teléfono, pendiente de sincronizar")
    }

    private fun fallo(operacion: String, e: Exception) {
        ultimaOperacion = registrar("✖ $operacion — rechazada: ${mensajeError(e)}", TipoEvento.ERROR)
        _avisos.tryEmit("Error: ${mensajeError(e)}")
    }

    private fun registrar(texto: String, tipo: TipoEvento): Evento {
        val evento = Evento(System.currentTimeMillis(), texto, tipo)
        eventos.add(0, evento)
        if (eventos.size > 200) eventos.removeAt(eventos.lastIndex)
        return evento
    }

    fun limpiarBitacora() = eventos.clear()

    private fun mensajeError(e: Exception): String = when ((e as? FirebaseFirestoreException)?.code) {
        FirebaseFirestoreException.Code.PERMISSION_DENIED -> "permiso denegado por las reglas de Firestore"
        FirebaseFirestoreException.Code.UNAVAILABLE -> "servidor no disponible (sin conexión)"
        FirebaseFirestoreException.Code.NOT_FOUND -> "el documento ya no existe"
        else -> e.message ?: e.javaClass.simpleName
    }

    override fun onCleared() {
        escucha?.remove()
        escuchaMatriz?.remove()
        runCatching { red.unregisterNetworkCallback(vigilanteRed) }
    }
}
