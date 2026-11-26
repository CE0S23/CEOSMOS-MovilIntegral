package com.ceosmos.practicas.p05

import com.ceosmos.practicas.SinEspacios
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// [CEOSMOS] Antes: class MainActivity : FlutterActivity(). El mismo código se registra
// sobre el motor de CEOSMOS desde su MainActivity; el canal conserva su nombre.
class AccesoSeguroChannel {
    companion object {
        private const val CHANNEL = "acceso_seguro/login"
        private const val MAX_USER = 18
        private const val MAX_PASSWORD = 64
        private const val MIN_PASSWORD = 8

        // Datos FICTICIOS para esta práctica local. En producción, autentica un servidor.
        private const val DEMO_USER = "alumno"
        private const val DEMO_PASSWORD = "ClaveDemo2026"
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "validateLogin") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val user = call.argument<String>("username") ?: ""
                val password = call.argument<String>("password") ?: ""
                result.success(validateLogin(user, password))
            }
    }

    // Regla pura (sin canal) para probarla con JUnit.
    internal fun validateLogin(user: String, password: String): Map<String, Any> {
        // Ambos campos son obligatorios.
        if (user.isEmpty() || password.isEmpty()) {
            return answer(false, "Completa usuario y contraseña.")
        }

        // Flutter bloquea espacios al escribir y pegar. Kotlin los rechaza también
        // para que una llamada directa al canal no omita esta regla.
        if (SinEspacios.tieneEspacios(user)) {
            return answer(false, "El usuario no puede contener espacios.")
        }
        // 1.4.0: la contraseña tampoco admite espacios.
        if (SinEspacios.tieneEspacios(password)) {
            return answer(false, "La contraseña no puede contener espacios.")
        }

        // El usuario admite hasta 18 caracteres y la contraseña hasta 64.
        // El canal rechaza entradas largas aunque intenten omitir el límite visual.
        if (user.length > MAX_USER || password.length > MAX_PASSWORD) {
            return answer(false, "La entrada supera la longitud permitida.")
        }

        // Se exige un mínimo de ocho caracteres para la contraseña.
        if (password.length < MIN_PASSWORD) {
            return answer(false, "La contraseña debe tener al menos 8 caracteres.")
        }

        // El error no revela cuál credencial falló. Nunca se escriben datos en Logcat.
        if (user != DEMO_USER || password != DEMO_PASSWORD) {
            return answer(false, "No se pudo iniciar sesión. Verifica tus datos.")
        }
        return answer(true, "Acceso simulado correcto. Bienvenido.")
    }

    private fun answer(ok: Boolean, message: String): Map<String, Any> =
        mapOf("ok" to ok, "message" to message)
}
