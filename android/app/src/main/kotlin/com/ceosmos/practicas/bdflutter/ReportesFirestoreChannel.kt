package com.ceosmos.practicas.bdflutter

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.ceosmos.practicas.FirebasePracticas
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// [CEOSMOS] Antes: class MainActivity : FlutterActivity(). Mismo canal «reportes/firestore»,
// pero con la app de Firebase con nombre «bd_flutter» en lugar de [DEFAULT].
class ReportesFirestoreChannel(private val context: Context) {
    private var reportes: FirestoreReportes? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "reportes/firestore")
            .setMethodCallHandler { call, result ->
                if (call.method == "initialize") {
                    iniciarSesion(result)
                } else {
                    val repo = reportes
                    if (repo == null) {
                        result.error("AUTH", "Firebase aún no está conectado.", null)
                    } else if (!hayInternet()) {
                        result.error("OFFLINE", "Sin conexión: operación no enviada; los datos no se modificaron.", null)
                    } else {
                        ejecutar(call, result, repo)
                    }
                }
            }
    }

    private fun iniciarSesion(result: MethodChannel.Result) {
        // [CEOSMOS] Configuración en FirebasePracticas (valores de su google-services.json).
        val app = FirebasePracticas.app(context, FirebasePracticas.BD_FLUTTER)
        val auth = FirebaseAuth.getInstance(app)
        val actual = auth.currentUser
        if (actual != null) {
            conectar(actual.uid, result)
        } else {
            auth.signInAnonymously()
                .addOnSuccessListener { task ->
                    val uid = task.user?.uid
                    if (uid == null) result.error("AUTH", "No se obtuvo el UID.", null)
                    else conectar(uid, result)
                }
                .addOnFailureListener { result.error("AUTH", mensajeError(it), null) }
        }
    }

    private fun conectar(uid: String, result: MethodChannel.Result) {
        val app = FirebasePracticas.app(context, FirebasePracticas.BD_FLUTTER) // [CEOSMOS]
        reportes = FirestoreReportes(FirebaseFirestore.getInstance(app), uid)
        result.success(uid)
    }

    private fun ejecutar(call: MethodCall, result: MethodChannel.Result, repo: FirestoreReportes) {
        val id = call.argument<String>("id")?.trim().orEmpty()
        ReporteValidator.validarId(id)?.let { result.error("VALIDATION", it, null); return }

        when (call.method) {
            "create" -> {
                val equipo = call.argument<String>("equipo")?.trim().orEmpty()
                val descripcion = call.argument<String>("descripcion")?.trim().orEmpty()
                val prioridad = call.argument<String>("prioridad")?.trim().orEmpty()
                ReporteValidator.validar(id, equipo, descripcion, prioridad)?.let {
                    result.error("VALIDATION", it, null)
                    return
                }
                repo.crear(Reporte(id, equipo, descripcion, prioridad)) { r ->
                    r.fold({ result.success("Alta confirmada: $id") }, { result.error("FIRESTORE", mensajeError(it), null) })
                }
            }
            "read" -> repo.consultar(id) { r ->
                r.fold({ reporte ->
                    result.success(reporte?.let {
                        mapOf("id" to it.id, "equipo" to it.equipo,
                            "descripcion" to it.descripcion, "prioridad" to it.prioridad)
                    })
                }, { result.error("FIRESTORE", mensajeError(it), null) })
            }
            "update" -> {
                val prioridad = call.argument<String>("prioridad")?.trim().orEmpty()
                if (prioridad !in ReporteValidator.prioridades) {
                    result.error("VALIDATION", "La prioridad debe ser Baja, Media o Alta.", null)
                    return
                }
                repo.actualizarPrioridad(id, prioridad) { r ->
                    r.fold({ result.success("Actualización confirmada: $id · $prioridad") },
                        { result.error("FIRESTORE", mensajeError(it), null) })
                }
            }
            "delete" -> repo.eliminar(id) { r ->
                r.fold({ result.success("Eliminación confirmada: $id") },
                    { result.error("FIRESTORE", mensajeError(it), null) })
            }
            else -> result.notImplemented()
        }
    }

    private fun hayInternet(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val capacidades = cm.getNetworkCapabilities(cm.activeNetwork)
        return capacidades?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
    }

    private fun mensajeError(error: Throwable): String {
        val firestore = generateSequence(error) { it.cause }.filterIsInstance<FirebaseFirestoreException>().firstOrNull()
        return when (firestore?.code) {
            FirebaseFirestoreException.Code.UNAVAILABLE -> "Servidor no disponible o conexión perdida; no hubo confirmación."
            FirebaseFirestoreException.Code.PERMISSION_DENIED -> "Permiso denegado; verifica UID y reglas."
            else -> generateSequence(error) { it.cause }.mapNotNull { it.message }.firstOrNull()
                ?: "Error desconocido."
        }
    }
}
