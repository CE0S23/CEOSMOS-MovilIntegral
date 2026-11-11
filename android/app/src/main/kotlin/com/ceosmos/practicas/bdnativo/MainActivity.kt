package com.ceosmos.practicas.bdnativo

import android.app.Activity
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.ceosmos.practicas.FirebasePracticas
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException

class MainActivity : Activity() {
    private lateinit var id: EditText
    private lateinit var equipo: EditText
    private lateinit var descripcion: EditText
    private lateinit var prioridad: EditText
    private lateinit var estado: TextView
    private lateinit var usuario: TextView
    private var reportes: FirestoreReportes? = null
    private var operacion = 0
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        crearInterfaz()
        // [CEOSMOS] App de Firebase con nombre «bd_nativo» (valores de su google-services.json).
        val app = FirebasePracticas.app(this, FirebasePracticas.BD_NATIVO)
        val auth = FirebaseAuth.getInstance(app)
        val actual = auth.currentUser
        if (actual != null) {
            conectado(actual.uid)
        } else {
            mostrar("Conectando con Firebase Authentication…")
            auth.signInAnonymously().addOnSuccessListener { conectado(it.user!!.uid) }
                .addOnFailureListener { mostrar("No se pudo iniciar sesión: ${mensajeError(it)}") }
        }
    }

    private fun conectado(uid: String) {
        val app = FirebasePracticas.app(this, FirebasePracticas.BD_NATIVO) // [CEOSMOS]
        reportes = FirestoreReportes(FirebaseFirestore.getInstance(app), uid)
        usuario.text = "UID: $uid"
        mostrar("Conectado. Las consultas y escrituras esperan confirmación del servidor.")
    }

    private fun crearInterfaz() {
        val scroll = ScrollView(this)
        val columna = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 24, 32, 32)
        }
        scroll.addView(columna)
        setContentView(scroll)

        fun texto(valor: String) = TextView(this).also { columna.addView(it); it.text = valor }
        fun entrada(titulo: String, inicial: String): EditText = EditText(this).also {
            it.hint = titulo
            it.setText(inicial)
            it.setSingleLine(titulo != "Descripción")
            columna.addView(it)
        }
        fun boton(titulo: String, accion: () -> Unit) {
            columna.addView(Button(this).apply { text = titulo; setOnClickListener { accion() } })
        }

        texto("Pruebas de reportes · Cloud Firestore").textSize = 22f
        usuario = texto("UID: pendiente")
        id = entrada("ID (REP001)", "REP001")
        equipo = entrada("Equipo", "Bomba 1")
        descripcion = entrada("Descripción", "Fuga visible")
        prioridad = entrada("Prioridad: Baja, Media o Alta", "Media")
        boton("Alta") { alta() }
        boton("Consultar desde servidor") { consultar() }
        boton("Actualizar prioridad") { actualizar() }
        boton("Eliminar") { eliminar() }
        estado = texto("Preparando Firebase…")
        estado.textSize = 16f
    }

    private fun mostrar(mensaje: String) { estado.text = mensaje }

    private fun conectadoYEnLinea(): FirestoreReportes? {
        val repo = reportes ?: run { mostrar("Firebase aún no está conectado."); return null }
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val red = cm.activeNetwork
        val capacidades = cm.getNetworkCapabilities(red)
        if (capacidades?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) != true) {
            mostrar("Sin conexión: operación no enviada; los datos no se modificaron.")
            return null
        }
        return repo
    }

    private fun inicio(nombre: String): Int {
        val token = ++operacion
        mostrar("$nombre: esperando confirmación del servidor…")
        handler.postDelayed({
            if (operacion == token) mostrar("$nombre: aún sin confirmación. Revisa la conexión antes de repetir la operación.")
        }, 10000)
        return token
    }

    private fun terminar(token: Int, mensaje: String) {
        if (operacion == token) {
            ++operacion
            mostrar(mensaje)
        }
    }

    private fun alta() {
        val codigo = id.text.toString().trim()
        val nombre = equipo.text.toString().trim()
        val detalle = descripcion.text.toString().trim()
        val nivel = prioridad.text.toString().trim()
        ReporteValidator.validar(codigo, nombre, detalle, nivel)?.let { mostrar(it); return }
        val repo = conectadoYEnLinea() ?: return
        val token = inicio("Alta")
        repo.crear(Reporte(codigo, nombre, detalle, nivel)) {
            terminar(token, it.fold({ "Alta confirmada: $codigo." }, { e -> "Alta rechazada: ${mensajeError(e)}" }))
        }
    }

    private fun consultar() {
        val codigo = id.text.toString().trim()
        ReporteValidator.validarId(codigo)?.let { mostrar(it); return }
        val repo = conectadoYEnLinea() ?: return
        val token = inicio("Consulta")
        repo.consultar(codigo) { resultado ->
            resultado.fold({ encontrado ->
                if (encontrado == null) {
                    terminar(token, "El reporte $codigo no existe.")
                } else {
                    equipo.setText(encontrado.equipo)
                    descripcion.setText(encontrado.descripcion)
                    prioridad.setText(encontrado.prioridad)
                    terminar(token, "Consulta confirmada: $codigo · ${encontrado.equipo} · ${encontrado.descripcion} · ${encontrado.prioridad}.")
                }
            }, { terminar(token, "Consulta fallida: ${mensajeError(it)}") })
        }
    }

    private fun actualizar() {
        val codigo = id.text.toString().trim()
        val nivel = prioridad.text.toString().trim()
        ReporteValidator.validarId(codigo)?.let { mostrar(it); return }
        if (nivel !in ReporteValidator.prioridades) { mostrar("La prioridad debe ser Baja, Media o Alta."); return }
        val repo = conectadoYEnLinea() ?: return
        val token = inicio("Actualización")
        repo.actualizarPrioridad(codigo, nivel) {
            terminar(token, it.fold({ "Actualización confirmada: $codigo · $nivel." }, { e -> "Actualización rechazada: ${mensajeError(e)}" }))
        }
    }

    private fun eliminar() {
        val codigo = id.text.toString().trim()
        ReporteValidator.validarId(codigo)?.let { mostrar(it); return }
        val repo = conectadoYEnLinea() ?: return
        val token = inicio("Eliminación")
        repo.eliminar(codigo) {
            terminar(token, it.fold({ "Eliminación confirmada: $codigo." }, { e -> "Eliminación rechazada: ${mensajeError(e)}" }))
        }
    }

    private fun mensajeError(error: Throwable): String {
        val firestore = generateSequence(error) { it.cause }.filterIsInstance<FirebaseFirestoreException>().firstOrNull()
        return when (firestore?.code) {
            FirebaseFirestoreException.Code.UNAVAILABLE -> "servidor no disponible o conexión perdida; no hubo confirmación."
            FirebaseFirestoreException.Code.PERMISSION_DENIED -> "permiso denegado; verifica UID y reglas."
            else -> generateSequence(error) { it.cause }.mapNotNull { it.message }.firstOrNull()
                ?: "error desconocido."
        }
    }
}
