package com.ceosmos.ceosmos_movil_integral

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.os.Bundle
import com.ceosmos.practicas.BarraPracticas
import com.ceosmos.practicas.bdflutter.ReportesFirestoreChannel
import com.ceosmos.practicas.p05.AccesoSeguroChannel
import com.ceosmos.practicas.p06.MobileConnectChannels
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal de CEOSMOS.
 *
 * Además de CEOSMOS registra los canales nativos de las prácticas Flutter que
 * tenían código Kotlin (P5, P6 y Reportes Firestore) con sus nombres originales,
 * y abre las prácticas 100 % nativas (Kotlin/Compose) como actividades propias.
 */
class MainActivity : FlutterActivity() {
    private var mobileConnect: MobileConnectChannels? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        BarraPracticas.instalar(application)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        AccesoSeguroChannel().register(messenger)
        mobileConnect = MobileConnectChannels(this).also { it.register(messenger) }
        ReportesFirestoreChannel(applicationContext).register(messenger)

        // Permiso de Bluetooth denegado de forma permanente: abre los ajustes de la app.
        MethodChannel(messenger, "ceosmos/sistema").setMethodCallHandler { call, result ->
            if (call.method == "abrirAjustesApp") {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                )
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, "ceosmos/practicas").setMethodCallHandler { call, result ->
            when (call.method) {
                "abrirNativa" -> {
                    val id = call.argument<String>("id").orEmpty()
                    val titulo = call.argument<String>("titulo").orEmpty()
                    val destino = BarraPracticas.actividades[id]
                    if (destino == null) {
                        result.error("PRACTICA_DESCONOCIDA", "No existe la práctica nativa $id", null)
                    } else {
                        startActivity(
                            Intent(this, destino).putExtra(BarraPracticas.EXTRA_TITULO, titulo)
                        )
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        mobileConnect?.dispose()
        mobileConnect = null
        super.onDestroy()
    }
}
