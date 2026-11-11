package com.ceosmos.practicas.p06

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.InetAddress

// [CEOSMOS] Antes: class MainActivity : FlutterActivity(). Recibe el Context de la
// actividad de CEOSMOS; register() reemplaza configureFlutterEngine y dispose() a onDestroy.
class MobileConnectChannels(private val context: Context) {
    companion object {
        // Servidor A y cliente B comparten el mismo puerto TCP de destino.
        private const val PORT = 5000
        private const val NETWORK_CHANNEL = "mobile_connect/network"
        private const val EVENT_CHANNEL = "mobile_connect/events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val transport = TcpChatTransport()
    @Volatile private var session = 0
    @Volatile private var localDevice: String? = null
    private var eventSink: EventChannel.EventSink? = null
    private val connectivity by lazy {
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }
    private var wifiCallback: ConnectivityManager.NetworkCallback? = null
    @Volatile private var connectionWifi: Network? = null
    @Volatile private var connectionAddress: String? = null

    private data class WifiEndpoint(val network: Network, val address: Inet4Address, val prefix: Int)

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    publishNetworkInfo()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(messenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocalNetwork" -> result.success(localNetworkInfo(wifiEndpoint()))
                    "host" -> {
                        startHost()
                        result.success(null)
                    }
                    "connect" -> {
                        val ip = call.argument<String>("ip")?.trim().orEmpty()
                        if (ip.isEmpty()) result.error("INVALID_IP", "IP requerida", null)
                        else {
                            startClient(ip)
                            result.success(null)
                        }
                    }
                    "sendPacket" -> {
                        val data = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        val line = encodePacket(data)
                        if (localDevice == null || line == null) result.success(false)
                        else Thread {
                            val sent = transport.sendLine(line)
                            mainHandler.post { result.success(sent) }
                        }.start()
                    }
                    "disconnect" -> {
                        disconnect()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        observeWifi()
    }

    @Suppress("DEPRECATION")
    private fun wifiEndpoint(): WifiEndpoint? {
        // Consultamos la interfaz Wi-Fi real. No usamos la IP pública, localhost,
        // datos móviles ni una dirección elegida arbitrariamente entre interfaces.
        return try {
            val networks = connectivity.allNetworks.sortedBy { if (it == connectivity.activeNetwork) 0 else 1 }
            for (network in networks) {
                val caps = connectivity.getNetworkCapabilities(network) ?: continue
                if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) continue
                val links = connectivity.getLinkProperties(network) ?: continue
                for (link in links.linkAddresses) {
                    val address = link.address
                    if (address is Inet4Address && !address.isLoopbackAddress &&
                        !address.isAnyLocalAddress && !address.isMulticastAddress) {
                        return WifiEndpoint(network, address, link.prefixLength)
                    }
                }
            }
            null
        } catch (_: SecurityException) {
            null
        }
    }

    private fun localNetworkInfo(endpoint: WifiEndpoint?): Map<String, Any?> = mapOf(
        "type" to "network_info",
        "ip" to endpoint?.address?.hostAddress,
        "prefixLength" to endpoint?.prefix,
        "message" to if (endpoint != null) "Red Wi-Fi actual"
            else "Conéctate a una red Wi-Fi con dirección IPv4."
    )

    private fun observeWifi() {
        if (wifiCallback != null) return
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) = publishNetworkInfo()
            override fun onLost(network: Network) = publishNetworkInfo()
            override fun onLinkPropertiesChanged(network: Network, links: LinkProperties) = publishNetworkInfo()
            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) = publishNetworkInfo()
        }
        try {
            connectivity.registerNetworkCallback(NetworkRequest.Builder().clearCapabilities()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI).build(), callback)
            wifiCallback = callback
        } catch (_: SecurityException) {
            publishNetworkInfo()
        }
    }

    private fun publishNetworkInfo() {
        mainHandler.post {
            val endpoint = wifiEndpoint()
            // Si cambia la red, se conserva A/B y se solicita reconectar a la IP nueva.
            if (connectionWifi != null && (endpoint == null || connectionWifi != endpoint.network ||
                    connectionAddress != endpoint.address.hostAddress)) {
                disconnect()
                eventSink?.success(status("La red Wi-Fi cambió. Vuelve a conectar.", false))
            }
            eventSink?.success(localNetworkInfo(endpoint))
        }
    }

    private fun peerAddress(value: String): Inet4Address? {
        val parts = value.split('.')
        if (parts.size != 4 || parts.any { !it.matches(Regex("0|[1-9][0-9]{0,2}")) || it.toInt() > 255 }) return null
        if (parts[0].toInt() !in 1..223 || parts[0] == "127") return null
        return InetAddress.getByAddress(parts.map { it.toInt().toByte() }.toByteArray()) as Inet4Address
    }

    private fun startHost() {
        disconnect()
        localDevice = "A"
        val current = session
        val endpoint = wifiEndpoint()
        if (endpoint == null) {
            emit(current, status("Conéctate a una red Wi-Fi con dirección IPv4.", false))
            return
        }
        connectionWifi = endpoint.network
        connectionAddress = endpoint.address.hostAddress
        emit(current, status("Preparando la conversación…", false, connecting = true))
        transport.startHost(endpoint.address, PORT, connectionCallbacks(current))
    }

    private fun startClient(ip: String) {
        disconnect()
        localDevice = "B"
        val current = session
        val endpoint = wifiEndpoint()
        val destination = peerAddress(ip)
        if (endpoint == null || destination == null || destination == endpoint.address) {
            emit(current, status("Verifica tu conexión Wi-Fi y la IP del otro teléfono.", false))
            return
        }
        connectionWifi = endpoint.network
        connectionAddress = endpoint.address.hostAddress
        // El puerto visible permite identificar instalaciones con código nativo antiguo.
        Log.i("MobileConnectTCP", "operation=connect state=starting port=$PORT")
        emit(current, status("Conectando con la sala en el puerto $PORT…", false, connecting = true))
        // El tráfico usa Wi-Fi aunque los datos móviles sean la red predeterminada.
        transport.startClient(destination, PORT, connectionCallbacks(current),
            socketFactory = { endpoint.network.socketFactory.createSocket() })
    }

    private fun connectionCallbacks(current: Int) = object : TcpChatTransport.Callbacks {
        override fun onListening(port: Int) {
            if (current == session) Log.i("MobileConnectTCP", "operation=listen state=ready port=$port")
            emit(current, status("Sala lista. Esperando al compañero en el puerto $port.", false, listening = true))
        }

        override fun onConnected() {
            emit(current, status("Dispositivos conectados", true))
        }

        override fun onLine(line: String) {
            if (line == "PING") return
            if (line == "RESET") {
                emit(current, mapOf("type" to "reset"))
                return
            }
            val parts = line.split('\t', limit = 3)
            if (parts.size != 3 || parts[0] !in listOf("A", "B") || parts[1].length > 16) return
            val text = unescape(parts[2]).trim()
            if (text.isEmpty() || text.length > 200) return
            emit(current, mapOf("type" to "message", "sender" to parts[0],
                "time" to parts[1], "text" to text))
        }

        override fun onPeerClosed(stillListening: Boolean) {
            emit(current, status(if (stillListening)
                "Sala lista en el puerto $PORT. Esperando que el compañero vuelva a conectar."
                else "Conexión cerrada. Puedes volver a conectar.", false, listening = stillListening))
        }

        override fun onFailure(operation: String, error: Exception) {
            val failure = ConnectionFailure.from(error)
            // Solo códigos y clase de excepción; nunca contenidos del chat ni credenciales.
            if (current == session) Log.w("MobileConnectTCP",
                "operation=$operation port=$PORT code=${failure.code} exception=${error.javaClass.simpleName}")
            // El código se ve también en pantalla: no es necesario copiar todo Logcat.
            emit(current, status("${failure.userMessage} [${failure.code}; TCP $PORT]",
                false, errorCode = failure.code))
        }
    }

    // Protocolo compartido con la app del compañero: UTF-8, TAB y fin de línea.
    private fun encodePacket(data: Map<*, *>): String? {
        if (data["type"] == "reset") return "RESET"
        if (data["type"] != "message") return null
        val role = data["sender"] as? String ?: return null
        val time = data["time"] as? String ?: return null
        val text = (data["text"] as? String)?.trim() ?: return null
        if (role !in listOf("A", "B") || time.length > 16 ||
            time.any { it == '\t' || it == '\n' || it == '\r' } ||
            text.isEmpty() || text.length > 200) return null
        return "$role\t$time\t${escape(text)}"
    }

    private fun escape(text: String) = text.replace("\r\n", "\n").replace("\r", "\n")
        .replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

    private fun unescape(text: String): String {
        val output = StringBuilder()
        var index = 0
        while (index < text.length) {
            val character = text[index++]
            if (character == '\\' && index < text.length) {
                output.append(when (val escaped = text[index++]) {
                    'n' -> '\n'
                    't' -> '\t'
                    'r' -> '\r'
                    else -> escaped
                })
            } else output.append(character)
        }
        return output.toString()
    }

    private fun status(message: String, connected: Boolean, listening: Boolean = false,
        connecting: Boolean = false, errorCode: String = ""): Map<String, Any> =
        mapOf("type" to "status", "message" to message, "connected" to connected,
            "listening" to listening, "connecting" to connecting, "errorCode" to errorCode)

    private fun emit(current: Int, event: Map<String, Any>) {
        mainHandler.post { if (current == session) eventSink?.success(event) }
    }

    private fun disconnect() {
        session++
        connectionWifi = null
        connectionAddress = null
        transport.disconnect()
    }

    fun dispose() {
        wifiCallback?.let { connectivity.unregisterNetworkCallback(it) }
        wifiCallback = null
        disconnect()
    }
}
