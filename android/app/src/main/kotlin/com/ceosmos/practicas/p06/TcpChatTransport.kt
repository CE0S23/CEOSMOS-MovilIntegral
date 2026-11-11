package com.ceosmos.practicas.p06

import java.io.BufferedWriter
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket

/** Transporte TCP sin dependencias Android: se prueba con sockets JVM reales. */
class TcpChatTransport {
    interface Callbacks {
        fun onListening(port: Int)
        fun onConnected()
        fun onLine(line: String)
        fun onPeerClosed(stillListening: Boolean)
        fun onFailure(operation: String, error: Exception)
    }

    private val stateLock = Any()
    private val writeLock = Any()
    private var generation = 0
    private var server: ServerSocket? = null
    private var peer: Socket? = null
    private var writer: BufferedWriter? = null
    private var callbacks: Callbacks? = null

    private fun current(id: Int) = synchronized(stateLock) { generation == id }

    fun startHost(address: InetAddress, port: Int, events: Callbacks) {
        disconnect()
        val id = synchronized(stateLock) { callbacks = events; generation }
        Thread({
            val listener = try { ServerSocket() } catch (error: Exception) {
                if (current(id)) events.onFailure("listen", error)
                return@Thread
            }
            try {
                synchronized(stateLock) {
                    if (generation != id) { listener.close(); return@Thread }
                    // Se registra antes de bind para que un reintento pueda cancelarlo.
                    server = listener
                }
                listener.reuseAddress = true
                listener.bind(InetSocketAddress(address, port))
                if (current(id)) events.onListening(listener.localPort)
                // A vuelve a aceptar B después de cualquier desconexión del cliente.
                while (current(id)) {
                    val incoming = listener.accept()
                    if (!current(id)) { incoming.close(); break }
                    readPeer(incoming, id, events, hosting = true)
                }
            } catch (error: Exception) {
                if (current(id)) events.onFailure("listen", error)
            } finally {
                synchronized(stateLock) { if (server === listener) server = null }
                try { listener.close() } catch (_: Exception) { }
            }
        }, "MobileConnect-listener").apply { isDaemon = true }.start()
    }

    fun startClient(
        address: InetAddress,
        port: Int,
        events: Callbacks,
        socketFactory: () -> Socket = { Socket() },
        timeoutMs: Int = 8000
    ) {
        disconnect()
        val id = synchronized(stateLock) { callbacks = events; generation }
        Thread({
            var outgoing: Socket? = null
            try {
                outgoing = socketFactory()
                synchronized(stateLock) {
                    if (generation != id) { outgoing.close(); return@Thread }
                    // También se puede cancelar una conexión que aún no ha terminado.
                    peer = outgoing
                }
                outgoing.connect(InetSocketAddress(address, port), timeoutMs)
                readPeer(outgoing, id, events, hosting = false)
            } catch (error: Exception) {
                if (current(id)) events.onFailure("connect", error)
            } finally {
                synchronized(stateLock) {
                    if (peer === outgoing) { peer = null; writer = null }
                }
                try { outgoing?.close() } catch (_: Exception) { }
            }
        }, "MobileConnect-client").apply { isDaemon = true }.start()
    }

    private fun readPeer(socket: Socket, id: Int, events: Callbacks, hosting: Boolean) {
        try {
            socket.tcpNoDelay = true
            socket.keepAlive = true
            socket.soTimeout = 20000
            val output = BufferedWriter(OutputStreamWriter(socket.getOutputStream(), Charsets.UTF_8))
            synchronized(stateLock) {
                if (generation != id) { socket.close(); return }
                peer = socket
                writer = output
            }
            events.onConnected()
            // La otra app cierra tras 20 s sin datos; compartimos su latido de 5 s.
            Thread({
                try {
                    while (current(id) && !socket.isClosed) {
                        Thread.sleep(5000)
                        if (current(id) && !socket.isClosed && !sendLine("PING")) break
                    }
                } catch (_: InterruptedException) { }
            }, "MobileConnect-heartbeat").apply { isDaemon = true }.start()
            InputStreamReader(socket.getInputStream(), Charsets.UTF_8).buffered().use { input ->
                while (current(id)) {
                    val line = input.readLine() ?: break
                    if (current(id)) events.onLine(line)
                }
            }
        } catch (error: Exception) {
            if (current(id) && !socket.isClosed) events.onFailure("receive", error)
        } finally {
            synchronized(stateLock) {
                if (peer === socket) { peer = null; writer = null }
            }
            try { socket.close() } catch (_: Exception) { }
            if (current(id)) events.onPeerClosed(hosting)
        }
    }

    fun sendLine(line: String): Boolean = synchronized(writeLock) write@ {
        val snapshot = synchronized(stateLock) state@ {
            val output = writer ?: return@state null
            Triple(generation, output, callbacks)
        } ?: return@write false
        try {
            if (!current(snapshot.first)) return@write false
            snapshot.second.write(line)
            snapshot.second.newLine()
            snapshot.second.flush()
            true
        } catch (error: Exception) {
            if (current(snapshot.first)) snapshot.third?.onFailure("send", error)
            false
        }
    }

    fun disconnect() {
        val sockets = synchronized(stateLock) {
            generation++
            val old = Pair(peer, server)
            peer = null
            server = null
            writer = null
            callbacks = null
            old
        }
        // Cerrar el socket desbloquea read/accept/write; nunca esperamos writeLock.
        try { sockets.first?.close() } catch (_: Exception) { }
        try { sockets.second?.close() } catch (_: Exception) { }
    }
}
