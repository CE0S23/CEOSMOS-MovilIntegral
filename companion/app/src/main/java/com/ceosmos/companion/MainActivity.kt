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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.Icon
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
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.ceosmos.companion.ble.Protocolo.Rol

// Colores, fuentes y escala: TemaCeosmos.kt (mismos tokens que la app Flutter).

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
            TemaCeosmos(if (modo == Rol.RELOJ) Formato.RELOJ else Formato.TV) {
                val e by Nucleo.estado.collectAsState()
                Box(Modifier.fillMaxSize().background(LocalPaleta.current.fondo)) {
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
    val p = LocalPaleta.current
    Column(
        Modifier.fillMaxSize().padding(32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(texto, color = p.tinta, style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        Button(onClick = alPulsar) { Text(accion, style = MaterialTheme.typography.labelLarge) }
    }
}

private fun mmss(seg: Int) = "%02d:%02d".format(seg / 60, seg % 60)

/** Cifras de ancho fijo para que el contador no "baile" cada segundo. */
private val Tabulares = "tnum"

@Composable
private fun EstadoConexion(e: Estado, rol: Rol, grande: Boolean = false) {
    val p = LocalPaleta.current
    // Estado con ícono + texto: el error nunca depende solo del color.
    val (texto, color, icono) = when {
        e.error != null && rol !in e.anunciando -> Triple(e.error ?: "Error", p.error, Icons.Filled.Warning)
        rol in e.autenticado && rol in e.suscrito -> Triple("Conectado con ${e.nombreCentral ?: "CEOSMOS"}", p.exito, Icons.Filled.CheckCircle)
        rol in e.autenticado -> Triple("Autenticado", p.exito, Icons.Filled.CheckCircle)
        e.conectados > 0 -> Triple("Central conectado · esperando PIN", p.advertencia, Icons.Filled.Info)
        rol in e.anunciando -> Triple("Anunciando · esperando a CEOSMOS", p.enlace, Icons.Filled.Info)
        else -> Triple("Iniciando…", p.textoSecundario, Icons.Filled.Info)
    }
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(if (grande) 8.dp else 4.dp)) {
        Icon(icono, contentDescription = null, tint = color, modifier = Modifier.size(if (grande) 24.dp else 14.dp))
        Text(
            texto,
            color = color,
            style = if (grande) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier.testTag("estado"),
        )
    }
}

// ---------------------------------------------------------------------------
// Reloj: carátula circular compacta
// ---------------------------------------------------------------------------

@Composable
private fun PantallaReloj(e: Estado, cambiarModo: (() -> Unit)?) {
    val p = LocalPaleta.current
    val t = MaterialTheme.typography
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Box(
            Modifier.size(380.dp).clip(CircleShape).background(p.superficie).border(6.dp, p.marca, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(40.dp)) {
                Text("CEOSMOS", color = p.marca, style = t.titleLarge.copy(letterSpacing = 0.06.em))
                EstadoConexion(e, Rol.RELOJ)
                Spacer(Modifier.height(6.dp))
                val s = e.sesion
                if (s != null && s.estado != "idle") {
                    Text(mmss(s.restante), color = p.tinta, style = t.displayLarge.copy(fontFeatureSettings = Tabulares))
                    Text(
                        (if (s.estado == "paused") "En pausa · " else "") + s.titulo,
                        color = p.textoSecundario, style = t.bodyMedium, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                } else {
                    Text("♥ ${e.hr}", color = p.tinta, style = t.displayLarge.copy(fontFeatureSettings = Tabulares))
                    Text("bpm · ${e.pasos} pasos", color = p.textoSecundario, style = t.bodyMedium)
                }
                if (s != null && s.estado != "idle") Text("♥ ${e.hr} bpm · ${e.pasos} pasos", color = p.exito, style = t.labelMedium)
                Spacer(Modifier.height(8.dp))
                // Primario: guinda con texto blanco (en oscuro, guinda aclarado con texto guinda).
                Button(
                    onClick = { Nucleo.enviarComando(Rol.RELOJ, "toggle") },
                    enabled = Rol.RELOJ in e.suscrito,
                    shape = CircleShape,
                    modifier = Modifier.testTag("accion"),
                ) { Text(if (s?.estado == "running") "Pausar" else "Reanudar", style = t.labelLarge) }
                TextButton(
                    onClick = { Nucleo.enviarComando(Rol.RELOJ, "stop") },
                    enabled = Rol.RELOJ in e.suscrito && s != null && s.estado != "idle",
                    colors = ButtonDefaults.textButtonColors(contentColor = p.enlace),
                ) { Text("Terminar", style = t.labelMedium) }
                e.notificaciones.firstOrNull()?.let {
                    Text(it, color = p.enlace, style = t.labelMedium, textAlign = TextAlign.Center, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        Spacer(Modifier.height(20.dp))
        Text("PIN  ${e.pin}", color = p.marca, style = t.displayMedium.copy(fontSize = 28.sp, fontFeatureSettings = Tabulares), modifier = Modifier.testTag("pin"))
        Text("id ${e.id} · centrales: ${e.conectados}" + if (e.bloqueos > 0) " · bloqueados: ${e.bloqueos}" else "", color = p.textoSecundario, style = t.bodyMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            val terciario = ButtonDefaults.textButtonColors(contentColor = p.enlace)
            TextButton(onClick = Nucleo::alternarSimulacion, colors = terciario) { Text(if (e.simulando) "Pausar lecturas" else "Reanudar lecturas", style = t.labelLarge) }
            TextButton(onClick = Nucleo::regenerarPin, colors = terciario) { Text("Nuevo PIN", style = t.labelLarge) }
            cambiarModo?.let { TextButton(onClick = it, colors = terciario) { Text("Modo TV", style = t.labelLarge) } }
        }
        Registro(e, Modifier.width(520.dp).height(130.dp))
    }
}

@Composable
private fun Registro(e: Estado, modifier: Modifier) {
    val p = LocalPaleta.current
    Column(modifier.padding(top = 8.dp)) {
        e.registro.take(6).forEach { Text(it, color = p.textoSecundario, style = MaterialTheme.typography.bodySmall, maxLines = 1) }
    }
}

// ---------------------------------------------------------------------------
// TV: panel horizontal de pantalla grande, navegable con D-pad
// ---------------------------------------------------------------------------

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PantallaTv(e: Estado, cambiarModo: (() -> Unit)?) {
    val p = LocalPaleta.current
    val t = MaterialTheme.typography
    val primero = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { primero.requestFocus() } }
    Row(Modifier.fillMaxSize().padding(48.dp), horizontalArrangement = Arrangement.spacedBy(40.dp)) {
        Column(Modifier.weight(2f)) {
            Text("CEOSMOS TV", color = p.marca, style = t.headlineSmall.copy(letterSpacing = 0.04.em))
            EstadoConexion(e, Rol.TV, grande = true)
            Spacer(Modifier.height(32.dp))
            val s = e.sesion
            if (s == null || s.estado == "idle") {
                Text("Sin sesión en curso", color = p.tinta, style = t.headlineLarge)
                Text(
                    if (Rol.TV in e.suscrito) "Inicia una sesión en CEOSMOS o pulsa ▶ Siguiente." else "Conecta CEOSMOS desde Equipos › CEOSMOS TV con el PIN.",
                    color = p.textoSecundario, style = t.bodyLarge,
                )
                if (s?.usuario?.isNotEmpty() == true) Text("Cuenta: ${s.usuario}", color = p.textoSecundario, style = t.bodyMedium)
            } else {
                Text(s.titulo, color = p.marca, style = t.displaySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text("${s.modo} · ${if (s.estado == "paused") "en pausa" else "en curso"} · ${s.usuario}", color = p.textoSecundario, style = t.bodyLarge)
                Spacer(Modifier.height(24.dp))
                Text(mmss(s.restante), color = p.tinta, style = t.displayLarge.copy(fontFeatureSettings = Tabulares), modifier = Modifier.testTag("restante"))
                LinearProgressIndicator(
                    progress = { if (s.total == 0) 0f else 1f - s.restante.toFloat() / s.total },
                    modifier = Modifier.fillMaxWidth().height(10.dp).clip(RoundedCornerShape(5.dp)),
                    color = CeosmosColores.Cian,
                    trackColor = p.superficieAlta,
                    drawStopIndicator = {},
                )
                s.hr?.let { Text("♥ $it bpm (reloj)", color = p.exito, style = t.headlineSmall, modifier = Modifier.padding(top = 16.dp)) }
            }
            Spacer(Modifier.height(36.dp))
            // Los botones pasan a otra fila si no caben (tablet en horizontal, escala TV).
            FlowRow(horizontalArrangement = Arrangement.spacedBy(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                val ok = Rol.TV in e.suscrito
                BotonTv("◀ Anterior", ok, Modifier.focusRequester(primero)) { Nucleo.enviarComando(Rol.TV, "prev") }
                BotonTv(if (e.sesion?.estado == "running") "❚❚ Pausar" else "▶ Reanudar", ok) { Nucleo.enviarComando(Rol.TV, "toggle") }
                BotonTv("■ Terminar", ok) { Nucleo.enviarComando(Rol.TV, "stop") }
                BotonTv("Siguiente ▶", ok) { Nucleo.enviarComando(Rol.TV, "next") }
            }
        }
        Column(
            Modifier.weight(1f).clip(RoundedCornerShape(20.dp)).background(p.superficie)
                .border(1.dp, p.borde, RoundedCornerShape(20.dp)).padding(24.dp),
        ) {
            Text("Emparejar", color = p.enlace, style = t.titleMedium)
            Text(e.pin, color = p.marca, style = t.displayMedium.copy(fontFeatureSettings = Tabulares), modifier = Modifier.testTag("pin"))
            Text("id ${e.id} · centrales: ${e.conectados}" + if (e.bloqueos > 0) " · bloqueados: ${e.bloqueos}" else "", color = p.textoSecundario, style = t.labelMedium.copy(fontWeight = FontWeight.Medium))
            Text("Varios anuncios a la vez: ${if (e.multiAnuncio) "sí" else "no"}", color = p.textoSecundario, style = t.bodySmall)
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                BotonTv("Nuevo PIN", true, chico = true) { Nucleo.regenerarPin() }
                cambiarModo?.let { BotonTv("Modo reloj", true, chico = true, alPulsar = it) }
            }
            Spacer(Modifier.height(16.dp))
            Text("Registro", color = p.enlace, style = t.titleMedium.copy(fontSize = 16.sp))
            Registro(e, Modifier.fillMaxWidth())
        }
    }
}

/**
 * Botón enfocable con D-pad: al enfocar, fondo cian con texto guinda y anillo
 * de foco; ENTER / centro del D-pad para pulsar.
 */
@Composable
private fun BotonTv(texto: String, habilitado: Boolean, modifier: Modifier = Modifier, chico: Boolean = false, alPulsar: () -> Unit) {
    val p = LocalPaleta.current
    var enfocado by remember { mutableStateOf(false) }
    val contenido = when {
        !habilitado -> p.tinta.copy(alpha = .38f)
        enfocado -> CeosmosColores.Guinda
        else -> p.tinta
    }
    OutlinedButton(
        onClick = alPulsar,
        enabled = habilitado,
        border = BorderStroke(if (enfocado) 4.dp else 1.dp, if (enfocado) p.foco else p.bordeControl),
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = if (enfocado) CeosmosColores.Cian else Color.Transparent,
            disabledContainerColor = Color.Transparent,
        ),
        modifier = modifier
            .onFocusChanged { enfocado = it.isFocused }
            .onKeyEvent {
                if (it.type == KeyEventType.KeyUp && (it.key == Key.DirectionCenter || it.key == Key.Enter) && habilitado) {
                    alPulsar(); true
                } else false
            }
            .focusable(),
    ) {
        Text(
            texto,
            style = if (chico) MaterialTheme.typography.labelMedium else MaterialTheme.typography.labelLarge,
            color = contenido,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.padding(if (chico) 4.dp else 12.dp),
        )
    }
}
