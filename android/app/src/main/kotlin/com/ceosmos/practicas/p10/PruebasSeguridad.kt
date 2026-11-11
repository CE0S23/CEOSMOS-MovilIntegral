package com.ceosmos.practicas.p10

import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.firestore.FirebaseFirestoreException

/*
 * Clasificación de las respuestas del servidor para la matriz SEG-01 … SEG-14. Las pruebas se hacen
 * a mano desde la interfaz (la interfaz no bloquea nada: deja intentar la operación) y cada intento
 * se anota según lo que respondió el servidor:
 *  - Permitida: el servidor confirmó la operación.
 *  - Rechazada: Firestore respondió PERMISSION_DENIED o Authentication rechazó las credenciales.
 *  - SinRespuesta: no se pudo comprobar (sin conexión...).
 * La prueba pasa cuando la respuesta coincide con lo esperado en el caso.
 */

const val TAG_SEGURIDAD = "SEGURIDAD"

sealed interface Respuesta {
    val detalle: String
    data class Permitida(override val detalle: String) : Respuesta
    data class Rechazada(val codigo: String, override val detalle: String) : Respuesta
    data class SinRespuesta(override val detalle: String) : Respuesta
}

/** Respuesta del servidor a partir del error de una [operacion]. */
fun respuestaDe(e: Exception, operacion: String): Respuesta = when {
    e is FirebaseFirestoreException && e.code == FirebaseFirestoreException.Code.PERMISSION_DENIED ->
        Respuesta.Rechazada(e.code.name, "$operacion: Firestore respondió ${e.code.name}")
    e is FirebaseAuthException -> Respuesta.Rechazada(e.errorCode, "$operacion: Authentication respondió ${e.errorCode}")
    else -> Respuesta.SinRespuesta("$operacion: ${mensajeFirestore(e)}")
}

/** Une dos operaciones de un mismo caso: solo cuenta como rechazado si se rechazaron ambas. */
fun combinar(a: Respuesta, b: Respuesta): Respuesta = when {
    a is Respuesta.Rechazada && b is Respuesta.Rechazada -> Respuesta.Rechazada(a.codigo, "${a.detalle} | ${b.detalle}")
    a is Respuesta.Permitida || b is Respuesta.Permitida -> Respuesta.Permitida("${a.detalle} | ${b.detalle}")
    else -> Respuesta.SinRespuesta("${a.detalle} | ${b.detalle}")
}

/** Resultado de un caso: pasa si la respuesta del servidor coincide con lo esperado. */
fun evaluar(caso: CasoSeguridad, respuesta: Respuesta, actor: String): ResultadoSeguridad {
    val paso = when (respuesta) {
        is Respuesta.Permitida -> caso.permitida
        is Respuesta.Rechazada -> !caso.permitida
        is Respuesta.SinRespuesta -> false
    }
    val veredicto = when (respuesta) {
        is Respuesta.Permitida -> "PERMITIDA"
        is Respuesta.Rechazada -> "RECHAZADA (${respuesta.codigo})"
        is Respuesta.SinRespuesta -> "SIN COMPROBAR"
    }
    return ResultadoSeguridad(caso.id, paso, "$veredicto · ${respuesta.detalle}", actor, System.currentTimeMillis())
}

/** Mensaje legible para los errores de Authentication. */
fun mensajeAuth(e: Exception): String = when (e) {
    is FirebaseAuthException -> when (e.errorCode) {
        "ERROR_INVALID_CREDENTIAL", "ERROR_WRONG_PASSWORD" -> "Correo o contraseña incorrectos"
        "ERROR_USER_NOT_FOUND" -> "No existe una cuenta con ese correo"
        "ERROR_INVALID_EMAIL" -> "El correo no tiene un formato válido"
        "ERROR_EMAIL_ALREADY_IN_USE" -> "Ya existe una cuenta con ese correo"
        "ERROR_WEAK_PASSWORD" -> "La contraseña debe tener al menos 6 caracteres"
        "ERROR_TOO_MANY_REQUESTS" -> "Demasiados intentos: espera un momento"
        else -> e.errorCode
    } + " (${e.errorCode})"
    is FirebaseNetworkException -> "Sin conexión con el servidor"
    else -> e.message ?: e.javaClass.simpleName
}

/** Mensaje legible para los errores de Firestore. */
fun mensajeFirestore(e: Exception): String = when ((e as? FirebaseFirestoreException)?.code) {
    FirebaseFirestoreException.Code.PERMISSION_DENIED -> "permiso denegado por las reglas de Firestore (PERMISSION_DENIED)"
    FirebaseFirestoreException.Code.UNAVAILABLE -> "servidor no disponible (sin conexión)"
    FirebaseFirestoreException.Code.NOT_FOUND -> "el documento no existe"
    else -> e.message ?: e.javaClass.simpleName
}
