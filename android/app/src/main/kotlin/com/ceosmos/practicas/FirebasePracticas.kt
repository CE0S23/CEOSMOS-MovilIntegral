package com.ceosmos.practicas

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions

/**
 * [CEOSMOS] Apps de Firebase con nombre, una por práctica nativa.
 *
 * Las prácticas originales usaban la app [DEFAULT] creada desde su
 * google-services.json. Dentro de CEOSMOS cada una obtiene su propia instancia
 * (FirebaseApp con nombre) para que su sesión de Auth, su caché de Firestore y
 * su proyecto no se mezclen con CEOSMOS ni entre prácticas. CEOSMOS no usa
 * Firebase y no se aplica el plugin google-services, así que no existe [DEFAULT].
 *
 * Los valores son los de cada google-services.json entregado (datos públicos de
 * cliente; la seguridad la aplican las reglas de Firestore de cada proyecto).
 */
object FirebasePracticas {
    const val BD_FLUTTER = "bd_flutter"
    const val BD_NATIVO = "bd_nativo"
    const val P09 = "p09"
    const val P10 = "p10"

    // reportes_flutter/android/app/google-services.json y
    // firestore_reportes_android/app/google-services.json (mismo proyecto).
    private val reportes = FirebaseOptions.Builder()
        .setProjectId("reportes-movil-20261019")
        .setApplicationId("1:460782495529:android:115ef39759a64280a57938")
        .setApiKey("AIzaSyBGYBtb51g45VS2jSRdkRVSnkpIMnP-2oo")
        .setGcmSenderId("460782495529")
        .setStorageBucket("reportes-movil-20261019.firebasestorage.app")
        .build()

    // PRACTICA 9 - DMI/app/google-services.json y PRACTICA 10 - DMI (mismo proyecto).
    private val mesaAyuda = FirebaseOptions.Builder()
        .setProjectId("mesaayuda-p7")
        .setApplicationId("1:245587407150:android:53e0b5342dbd0a570e4abf")
        .setApiKey("AIzaSyBMMwogDVaw9wNqPSyoXlEiJw2_T1oGYZ4")
        .setGcmSenderId("245587407150")
        .setStorageBucket("mesaayuda-p7.firebasestorage.app")
        .build()

    private fun opciones(nombre: String): FirebaseOptions = when (nombre) {
        BD_FLUTTER, BD_NATIVO -> reportes
        P09, P10 -> mesaAyuda
        else -> throw IllegalArgumentException("Práctica sin Firebase: $nombre")
    }

    /** Devuelve (creándola la primera vez) la app de Firebase de la práctica. */
    @Synchronized
    fun app(context: Context, nombre: String): FirebaseApp =
        FirebaseApp.getApps(context).firstOrNull { it.name == nombre }
            ?: FirebaseApp.initializeApp(context.applicationContext, opciones(nombre), nombre)
}
