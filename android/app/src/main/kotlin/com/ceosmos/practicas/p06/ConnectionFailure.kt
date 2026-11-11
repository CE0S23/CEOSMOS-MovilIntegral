package com.ceosmos.practicas.p06

import java.net.BindException
import java.net.NoRouteToHostException
import java.net.SocketTimeoutException

enum class ConnectionFailure(val code: String, val userMessage: String) {
    REFUSED("CONNECTION_REFUSED", "El otro teléfono rechazó la conexión. Quien crea la sala debe pulsar Crear conversación y esperar el aviso de que está lista."),
    TIMEOUT("CONNECTION_TIMEOUT", "El otro teléfono no respondió. Verifica que la sala esté lista y que la red permita conexiones entre ambos teléfonos."),
    UNREACHABLE("NETWORK_UNREACHABLE", "No hay una ruta disponible al otro teléfono. Verifica la IP y la conexión Wi-Fi."),
    DENIED("NETWORK_PERMISSION_DENIED", "Android no permitió la conexión de red. Revisa los permisos de red de la aplicación."),
    IN_USE("PORT_IN_USE", "El puerto de MobileConnect está ocupado. Cierra otras instancias e intenta crear la conversación de nuevo."),
    ADDRESS_CHANGED("ADDRESS_UNAVAILABLE", "La dirección Wi-Fi ya no está disponible. Actualiza la IP y vuelve a conectar."),
    OTHER("CONNECTION_FAILED", "No se pudo establecer la conexión. Verifica que la sala esté lista y vuelve a intentarlo.");

    companion object {
        fun from(error: Throwable): ConnectionFailure {
            val causes = generateSequence(error) { it.cause }.take(8).toList()
            val description = causes.joinToString(" ") { it.message.orEmpty() }.uppercase()
            return when {
                causes.any { it is SecurityException } || "EACCES" in description || "EPERM" in description -> DENIED
                causes.any { it is SocketTimeoutException } || "ETIMEDOUT" in description || "TIMED OUT" in description -> TIMEOUT
                "ECONNREFUSED" in description || "CONNECTION REFUSED" in description -> REFUSED
                causes.any { it is NoRouteToHostException } || "EHOSTUNREACH" in description || "ENETUNREACH" in description -> UNREACHABLE
                "EADDRNOTAVAIL" in description || "CANNOT ASSIGN REQUESTED ADDRESS" in description -> ADDRESS_CHANGED
                causes.any { it is BindException } || "EADDRINUSE" in description || "ADDRESS ALREADY IN USE" in description -> IN_USE
                else -> OTHER
            }
        }
    }
}
