package com.ceosmos.practicas.p09

import com.ceosmos.practicas.CeosmosTema

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Incidencias – Práctica 9: conexiones y pruebas de base de datos entre dispositivos.
 *
 * La misma app se instala en dos teléfonos (Dispositivo A y Dispositivo B) que usan el mismo
 * proyecto de Firebase y la misma colección "incidencias" de Cloud Firestore.
 *
 * Pestañas:
 *  - Incidencias: alta, consulta (tiempo real o manual), edición con política de conflictos
 *    y eliminación. Cada operación muestra si el servidor la confirmó o quedó en cola.
 *  - Bitácora: qué cambios llegaron de otro dispositivo, cuándo y cuánto tardaron.
 *  - Conexión: proyecto, colección, red y origen de los datos; almacenamiento local vs nube.
 *  - Matriz: casos DB-01 a DB-09 compartidos entre los dos dispositivos.
 */
class MainActivity : ComponentActivity() {

    private val vm: IncidenciasViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { IncidenciasTheme { IncidenciasApp(vm) } }
    }
}

// ---------------------------------------------------------------------------
// Navegación principal
// ---------------------------------------------------------------------------

private enum class Pestana(val titulo: String, val icono: ImageVector) {
    INCIDENCIAS("Incidencias", Icons.Filled.Warning),
    BITACORA("Bitácora", Icons.AutoMirrored.Filled.List),
    CONEXION("Conexión", Icons.Filled.Settings),
    MATRIZ("Matriz", Icons.Filled.CheckCircle),
}

@Composable
fun IncidenciasApp(vm: IncidenciasViewModel) {
    val snackbar = remember { SnackbarHostState() }

    // Notificación visual: cada aviso del ViewModel aparece en la parte inferior.
    LaunchedEffect(Unit) {
        vm.avisos.collect { aviso ->
            snackbar.currentSnackbarData?.dismiss()
            launch { snackbar.showSnackbar(aviso) }
        }
    }
    when {
        !vm.configurado -> PantallaSinFirebase()
        vm.miNombre.isEmpty() -> PantallaNombre(vm, snackbar)
        else -> PantallaPrincipal(vm, snackbar)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PantallaPrincipal(vm: IncidenciasViewModel, snackbar: SnackbarHostState) {
    var seleccion by rememberSaveable { mutableIntStateOf(0) }
    val actual = Pestana.entries[seleccion]

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.size(38.dp).background(colorDispositivo(vm.miNombre), CircleShape),
                            contentAlignment = Alignment.Center,
                        ) { Text(inicial(vm.miNombre), color = Color.White, fontWeight = FontWeight.Bold) }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text(vm.miNombre, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, maxLines = 1)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                PuntoEstado(vm.enLinea)
                                Spacer(Modifier.width(5.dp))
                                Text(
                                    "${if (vm.enLinea) "En línea" else "Sin conexión"} · ${proyectoVisible(vm.proyecto)}",
                                    style = MaterialTheme.typography.bodySmall,
                                    maxLines = 1,
                                )
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            )
        },
        snackbarHost = { SnackbarHost(snackbar) },
        bottomBar = {
            NavigationBar {
                Pestana.entries.forEachIndexed { i, p ->
                    NavigationBarItem(
                        selected = i == seleccion,
                        onClick = { seleccion = i },
                        icon = { Icon(p.icono, contentDescription = null) },
                        label = { Text(p.titulo) },
                    )
                }
            }
        },
    ) { relleno ->
        Box(Modifier.padding(relleno).fillMaxSize().imePadding()) {
            when (actual) {
                Pestana.INCIDENCIAS -> PantallaIncidencias(vm)
                Pestana.BITACORA -> PantallaBitacora(vm)
                Pestana.CONEXION -> PantallaConexion(vm)
                Pestana.MATRIZ -> PantallaMatriz(vm)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Pantallas de inicio
// ---------------------------------------------------------------------------

@Composable
private fun PantallaSinFirebase() {
    Column(
        Modifier.fillMaxSize().padding(28.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.Info, contentDescription = null, modifier = Modifier.size(48.dp), tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.height(12.dp))
        Text("Falta configurar Firebase", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text(
            "Copia google-services.json en app/ y vuelve a compilar. Los dos dispositivos deben usar el mismo archivo (mismo proyecto).",
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun PantallaNombre(vm: IncidenciasViewModel, snackbar: SnackbarHostState) {
    var nombre by rememberSaveable { mutableStateOf("") }
    Scaffold(snackbarHost = { SnackbarHost(snackbar) }) { relleno ->
        Column(
            Modifier.padding(relleno).fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Spacer(Modifier.height(24.dp))
            Text("Incidencias técnicas", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text("Identifica este teléfono. El nombre se guarda solo en este dispositivo (almacenamiento local); las incidencias se guardan en la nube y las ven todos.")
            Text("Proyecto de Firebase: ${proyectoVisible(vm.proyecto)}", fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                listOf("Dispositivo A", "Dispositivo B").forEach {
                    Button(onClick = { vm.cambiarNombre(it) }, modifier = Modifier.weight(1f).height(56.dp)) { Text(it) }
                }
            }
            Text("u otro nombre:", style = MaterialTheme.typography.bodySmall)
            OutlinedTextField(nombre, { nombre = it.take(30) }, label = { Text("Nombre del dispositivo") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedButton(onClick = { vm.cambiarNombre(nombre) }, modifier = Modifier.fillMaxWidth()) { Text("Continuar") }
        }
    }
}

// ---------------------------------------------------------------------------
// Componentes compartidos
// ---------------------------------------------------------------------------

private val formatoHora = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
private val formatoHoraMs = SimpleDateFormat("HH:mm:ss.SSS", Locale.getDefault())
private val formatoFecha = SimpleDateFormat("dd/MM HH:mm:ss", Locale.getDefault())

fun hora(ms: Long?): String = ms?.let { formatoHora.format(Date(it)) } ?: "—"
fun horaMs(ms: Long): String = formatoHoraMs.format(Date(ms))
fun fecha(ms: Long?): String = ms?.let { formatoFecha.format(Date(it)) } ?: "—"

fun inicial(nombre: String): String = nombre.trim().split(" ").last().take(1).uppercase()

/** A en azul, B en verde; cualquier otro nombre en gris. */
fun colorDispositivo(nombre: String): Color = when (inicial(nombre)) {
    "A" -> Color(0xFF08708F)
    "B" -> Color(0xFF17805A)
    else -> Color(0xFF6B5A60)
}

fun colorEstado(estado: Estado): Color = when (estado) {
    Estado.PENDIENTE -> Color(0xFF9A5800)
    Estado.EN_PROCESO -> Color(0xFF08708F)
    Estado.RESUELTA -> Color(0xFF17805A)
}

fun colorPrioridad(prioridad: Prioridad): Color = when (prioridad) {
    Prioridad.BAJA -> Color(0xFF6B5A60)
    Prioridad.MEDIA -> Color(0xFF0A7FA3)
    Prioridad.ALTA -> Color(0xFF9A5800)
    Prioridad.CRITICA -> Color(0xFFC42A3F)
}

fun colorEvento(tipo: TipoEvento): Color = when (tipo) {
    TipoEvento.LOCAL -> Color(0xFF08708F)
    TipoEvento.REMOTO -> Color(0xFF17805A)
    TipoEvento.AVISO -> Color(0xFF9A5800)
    TipoEvento.ERROR -> Color(0xFFC42A3F)
}

/** Punto verde (en línea) o gris (sin conexión). */
@Composable
fun PuntoEstado(enLinea: Boolean) {
    Box(Modifier.size(8.dp).background(if (enLinea) Color(0xFF17805A) else Color(0xFF8C7880), CircleShape))
}

@Composable
fun Etiqueta(texto: String, fondo: Color, contenido: Color = Color.White) {
    Surface(color = fondo, contentColor = contenido, shape = RoundedCornerShape(50)) {
        Text(texto, style = MaterialTheme.typography.labelSmall, modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp), maxLines = 1)
    }
}

@Composable
fun Progreso() = CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)

// ---------------------------------------------------------------------------
// Tema
// ---------------------------------------------------------------------------

@Composable
fun IncidenciasTheme(content: @Composable () -> Unit) {
    // [CEOSMOS] Paleta, fuentes y escala del sistema de diseño compartido.
    val esquema = if (isSystemInDarkTheme()) CeosmosTema.oscuro else CeosmosTema.claro
    MaterialTheme(colorScheme = esquema, typography = CeosmosTema.tipografia, content = content)
}
