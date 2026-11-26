package com.ceosmos.ceosmos_movil_integral

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Notificaciones locales de las alertas de salud (1.4.0), canal del sistema
 * «Alertas de salud». En Android 13+ pide POST_NOTIFICATIONS; la explicación previa la
 * muestra Flutter (Perfil › Cuenta y herramientas) y, si se niega, Flutter indica la ruta
 * en Ajustes. El pulso del Reloj es simulado: el texto lo dice.
 */
class AlertasSalud(private val actividad: Activity) {
    private var pendiente: MethodChannel.Result? = null

    fun registrar(messenger: BinaryMessenger) {
        crearCanal()
        MethodChannel(messenger, "ceosmos/alertas").setMethodCallHandler { call, result ->
            when (call.method) {
                "pedirPermiso" -> pedirPermiso(result)
                "mostrar" -> {
                    mostrar(
                        call.argument<String>("titulo").orEmpty().take(60),
                        call.argument<String>("texto").orEmpty().take(240),
                        call.argument<String>("tipo").orEmpty(),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun permitido(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            actividad.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun pedirPermiso(result: MethodChannel.Result) {
        if (permitido()) {
            result.success(NotificationManagerCompat.from(actividad).areNotificationsEnabled())
            return
        }
        pendiente?.success(false)
        pendiente = result
        actividad.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), CODIGO_PERMISO)
    }

    /** Lo llama MainActivity.onRequestPermissionsResult. */
    fun alResponder(codigo: Int, concedidos: IntArray): Boolean {
        if (codigo != CODIGO_PERMISO) return false
        pendiente?.success(concedidos.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        pendiente = null
        return true
    }

    private fun crearCanal() {
        if (Build.VERSION.SDK_INT < 26) return // antes de Android 8 no hay canales
        val canal = NotificationChannel(CANAL, "Alertas de salud", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Avisos por pulso alto o bajo del Reloj CEOSMOS (pulso simulado)."
            enableVibration(true)
        }
        actividad.getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }

    @android.annotation.SuppressLint("MissingPermission") // se comprueba con permitido()
    private fun mostrar(titulo: String, texto: String, tipo: String) {
        if (!permitido()) return
        val abrir = PendingIntent.getActivity(
            actividad, 0,
            Intent(actividad, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(actividad, CANAL)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(titulo)
            .setContentText(texto)
            .setStyle(NotificationCompat.BigTextStyle().bigText(texto))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(abrir)
            .build()
        // Un id por tipo: una alerta nueva del mismo tipo sustituye a la anterior.
        runCatching { NotificationManagerCompat.from(actividad).notify(ID_BASE + tipo.hashCode() % 100, n) }
    }

    companion object {
        const val CANAL = "alertas_salud"
        const val CODIGO_PERMISO = 4101
        const val ID_BASE = 7300
    }
}
