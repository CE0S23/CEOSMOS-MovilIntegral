package com.ceosmos.companion

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ceosmos.companion.ble.Protocolo.Rol

private val Fondo = Color(0xFF0B0D18)
private val Superficie = Color(0xFF1C2032)
private val Lavanda = Color(0xFFC2ADFF)
private val Menta = Color(0xFF8AD8BC)
private val Durazno = Color(0xFFEABD9C)
private val Tenue = Color(0xFFA5A9BE)

class MainActivity : ComponentActivity() {
    private var permisosOk by mutableStateOf(false)
    private var btEncendido by mutableStateOf(true)
    private var modo by mutableStateOf(Nucleo.roles.first())

    private val pedirPermisos = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        revisar()
    }
    private val pedirBt = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { revisar() }

    private fun permisosNecesarios(): Array<String> = buildList {
        if (Build.VERSION.SDK_INT >= 31) {
            add(Manifest.permission.BLUETOOTH_ADVERTISE)
            add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
    }.toTypedArray()

    private fun revisar() {
        val faltan = permisosNecesarios().filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED && it != Manifest.permission.POST_NOTIFICATIONS
        }
        permisosOk = faltan.isEmpty()
        btEncendido = getSystemService(BluetoothManager::class.java).adapter?.isEnabled == true
        if (permisosOk) startForegroundService(Intent(this, ServicioCompanion::class.java))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Nucleo.preparar(this)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        aplicarOrientacion()
        setContent {
            MaterialTheme(colorScheme = darkColorScheme(primary = Lavanda, secondary = Menta, background = Fondo, surface = Superficie)) {
                val e by Nucleo.estado.collectAsState()
                Box(Modifier.fillMaxSize().background(Fondo)) {
                    when {
                        !permisosOk -> Bloqueo(
                            "CEOSMOS ${modo.nombre} necesita el permiso «Dispositivos cercanos» para anunciarse por Bluetooth LE.",
                            "Conceder permiso",
                        ) { pedirPermisos.launch(permisosNecesarios()) }
                        !btEncendido -> Bloqueo("El Bluetooth está apagado.", "Encender Bluetooth") {
                            pedirBt.launch(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
                        }
                        modo == Rol.RELOJ -> PantallaReloj(e, alCambiarModo())
                        else -> PantallaTv(e, alCambiarModo())
                    }
                }
            }
        }
    }

    private fun alCambiarModo(): (() -> Unit)? = if (Nucleo.roles.size < 2) null else {
        { modo = if (modo == Rol.RELOJ) Rol.TV else Rol.RELOJ; aplicarOrientacion() }
    }

    private fun aplicarOrientacion() {
        requestedOrientation = if (modo == Rol.TV) ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        else ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }

    override fun onResume() {
        super.onResume()
        revisar()
        if (!permisosOk) pedirPermisos.launch(permisosNecesarios())
    }
}

@Composable
private fun Bloqueo(texto: String, accion: String, alPulsar: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(texto, color = Color.White, fontSize = 20.sp, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        Button(onClick = alPulsar) { Text(accion) }
    }
}

private fun mmss(seg: Int) = "%02d:%02d".format(seg / 60, seg % 60)

@Composable
private fun EstadoConexion(e: Estado, rol: Rol, grande: Boolean = false) {
    val (texto, color) = when {
        e.error != null && rol !in e.anunciando -> (e.error ?: "Error") to Durazno
        rol in e.autenticado && rol in e.suscrito -> "Conectado con ${e.nombreCentral ?: "CEOSMOS"}" to Menta
        rol in e.autenticado -> "Autenticado" to Menta
        e.conectados > 0 -> "Central conectado · esperando PIN" to Durazno
        rol in e.anunciando -> "Anunciando · esperando a CEOSMOS" to Lavanda
        else -> "Iniciando…" to Tenue
    }
    Text(texto, color = color, fontSize = if (grande) 22.sp else 12.sp, textAlign = TextAlign.Center, modifier = Modifier.testTag("estado"))
}

// ---------------------------------------------------------------------------
// Reloj: carátula circular compacta
// ---------------------------------------------------------------------------

@Composable
private fun PantallaReloj(e: Estado, cambiarModo: (() -> Unit)?) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Box(
            Modifier.size(380.dp).clip(CircleShape).background(Color.Black).border(6.dp, Superficie, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(40.dp)) {
                Text("CEOSMOS", color = Lavanda, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                EstadoConexion(e, Rol.RELOJ)
                Spacer(Modifier.height(6.dp))
                val s = e.sesion
                if (s != null && s.estado != "idle") {
                    Text(mmss(s.restante), color = Color.White, fontSize = 46.sp, fontWeight = FontWeight.Light)
                    Text(
                        (if (s.estado == "paused") "En pausa · " else "") + s.titulo,
                        color = Tenue, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                } else {
                    Text("♥ ${e.hr}", color = Color.White, fontSize = 46.sp, fontWeight = FontWeight.Light)
                    Text("bpm · ${e.pasos} pasos", color = Tenue, fontSize = 12.sp)
                }
                if (s != null && s.estado != "idle") Text("♥ ${e.hr} bpm · ${e.pasos} pasos", color = Menta, fontSize = 12.sp)
                Spacer(Modifier.height(8.dp))
                Button(
                    onClick = { Nucleo.enviarComando(Rol.RELOJ, "toggle") },
                    enabled = Rol.RELOJ in e.suscrito,
                    shape = CircleShape,
                    modifier = Modifier.testTag("accion"),
                ) { Text(if (s?.estado == "running") "Pausar" else "Reanudar") }
                TextButton(
                    onClick = { Nucleo.enviarComando(Rol.RELOJ, "stop") },
                    enabled = Rol.RELOJ in e.suscrito && s != null && s.estado != "idle",
                ) { Text("Terminar", fontSize = 12.sp) }
                e.notificaciones.firstOrNull()?.let {
                    Text(it, color = Durazno, fontSize = 12.sp, textAlign = TextAlign.Center, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        Spacer(Modifier.height(20.dp))
        Text("PIN  ${e.pin}", color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold, modifier = Modifier.testTag("pin"))
        Text("id ${e.id} · centrales: ${e.conectados}" + if (e.bloqueos > 0) " · bloqueados: ${e.bloqueos}" else "", color = Tenue, fontSize = 12.sp)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TextButton(onClick = Nucleo::alternarSimulacion) { Text(if (e.simulando) "Pausar lecturas" else "Reanudar lecturas") }
            TextButton(onClick = Nucleo::regenerarPin) { Text("Nuevo PIN") }
            cambiarModo?.let { TextButton(onClick = it) { Text("Modo TV") } }
        }
        Registro(e, Modifier.width(520.dp).height(130.dp))
    }
}

@Composable
private fun Registro(e: Estado, modifier: Modifier) {
    Column(modifier.padding(top = 8.dp)) {
        e.registro.take(6).forEach { Text(it, color = Tenue, fontSize = 11.sp, maxLines = 1) }
    }
}

// ---------------------------------------------------------------------------
// TV: panel horizontal de pantalla grande, navegable con D-pad
// ---------------------------------------------------------------------------

@Composable
private fun PantallaTv(e: Estado, cambiarModo: (() -> Unit)?) {
    val primero = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { primero.requestFocus() } }
    Row(Modifier.fillMaxSize().padding(48.dp), horizontalArrangement = Arrangement.spacedBy(40.dp)) {
        Column(Modifier.weight(2f)) {
            Text("CEOSMOS TV", color = Lavanda, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            EstadoConexion(e, Rol.TV, grande = true)
            Spacer(Modifier.height(32.dp))
            val s = e.sesion
            if (s == null || s.estado == "idle") {
                Text("Sin sesión en curso", color = Color.White, fontSize = 44.sp)
                Text(
                    if (Rol.TV in e.suscrito) "Inicia una sesión en CEOSMOS o pulsa ▶ Siguiente." else "Conecta CEOSMOS desde Equipos › CEOSMOS TV con el PIN.",
                    color = Tenue, fontSize = 22.sp,
                )
                if (s?.usuario?.isNotEmpty() == true) Text("Cuenta: ${s.usuario}", color = Tenue, fontSize = 18.sp)
            } else {
                Text(s.titulo, color = Color.White, fontSize = 52.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text("${s.modo} · ${if (s.estado == "paused") "en pausa" else "en curso"} · ${s.usuario}", color = Tenue, fontSize = 22.sp)
                Spacer(Modifier.height(24.dp))
                Text(mmss(s.restante), color = Color.White, fontSize = 120.sp, fontWeight = FontWeight.Light, modifier = Modifier.testTag("restante"))
                LinearProgressIndicator(
                    progress = { if (s.total == 0) 0f else 1f - s.restante.toFloat() / s.total },
                    modifier = Modifier.fillMaxWidth().height(10.dp),
                    color = Menta,
                    trackColor = Superficie,
                )
                s.hr?.let { Text("♥ $it bpm (reloj)", color = Menta, fontSize = 26.sp, modifier = Modifier.padding(top = 16.dp)) }
            }
            Spacer(Modifier.height(36.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                val ok = Rol.TV in e.suscrito
                BotonTv("◀ Anterior", ok, Modifier.focusRequester(primero)) { Nucleo.enviarComando(Rol.TV, "prev") }
                BotonTv(if (e.sesion?.estado == "running") "❚❚ Pausar" else "▶ Reanudar", ok) { Nucleo.enviarComando(Rol.TV, "toggle") }
                BotonTv("■ Terminar", ok) { Nucleo.enviarComando(Rol.TV, "stop") }
                BotonTv("Siguiente ▶", ok) { Nucleo.enviarComando(Rol.TV, "next") }
            }
        }
        Column(Modifier.weight(1f)) {
            Text("Emparejar", color = Lavanda, fontSize = 20.sp)
            Text(e.pin, color = Color.White, fontSize = 64.sp, fontWeight = FontWeight.Bold, modifier = Modifier.testTag("pin"))
            Text("id ${e.id} · centrales: ${e.conectados}" + if (e.bloqueos > 0) " · bloqueados: ${e.bloqueos}" else "", color = Tenue, fontSize = 16.sp)
            Text("Varios anuncios a la vez: ${if (e.multiAnuncio) "sí" else "no"}", color = Tenue, fontSize = 14.sp)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                BotonTv("Nuevo PIN", true, chico = true) { Nucleo.regenerarPin() }
                cambiarModo?.let { BotonTv("Modo reloj", true, chico = true, alPulsar = it) }
            }
            Spacer(Modifier.height(16.dp))
            Text("Registro", color = Lavanda, fontSize = 16.sp)
            Registro(e, Modifier.fillMaxWidth())
        }
    }
}

/** Botón enfocable con D-pad: borde al enfocar y ENTER / centro del D-pad para pulsar. */
@Composable
private fun BotonTv(texto: String, habilitado: Boolean, modifier: Modifier = Modifier, chico: Boolean = false, alPulsar: () -> Unit) {
    var enfocado by remember { mutableStateOf(false) }
    OutlinedButton(
        onClick = alPulsar,
        enabled = habilitado,
        border = BorderStroke(if (enfocado) 4.dp else 1.dp, if (enfocado) Menta else Tenue),
        shape = RoundedCornerShape(14.dp),
        colors = ButtonDefaults.outlinedButtonColors(containerColor = if (enfocado) Superficie else Color.Transparent),
        modifier = modifier
            .onFocusChanged { enfocado = it.isFocused }
            .onKeyEvent {
                if (it.type == KeyEventType.KeyUp && (it.key == Key.DirectionCenter || it.key == Key.Enter) && habilitado) {
                    alPulsar(); true
                } else false
            }
            .focusable(),
    ) { Text(texto, fontSize = if (chico) 16.sp else 24.sp, color = Color.White, modifier = Modifier.padding(if (chico) 4.dp else 12.dp)) }
}
