package com.ceosmos.practicas.p10

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/*
 * Todas las pruebas de la matriz se hacen a mano desde esta pantalla. La interfaz no esconde las
 * operaciones no autorizadas (elegir otro propietario, tocar incidencias ajenas...): las envía y
 * muestra lo que respondió Firestore.
 */

@Composable
fun PantallaIncidencias(vm: IncidenciasViewModel) {
    var nueva by rememberSaveable { mutableStateOf(false) }

    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            contentPadding = PaddingValues(start = 12.dp, end = 12.dp, top = 10.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item { BarraConsulta(vm) }
            vm.ultimaOperacion?.let { op -> item { TarjetaOperacion(op) } }
            vm.errorLectura?.let { e -> item { Text("Error de lectura: $e", color = MaterialTheme.colorScheme.error) } }
            if (!vm.cargando && vm.incidencias.isEmpty()) item { Vacio("Todavía no tienes incidencias. Registra la primera con el botón Nueva.") }
            items(vm.incidencias, key = { it.id }) { TarjetaIncidencia(it, propia = true, onClick = { vm.abrir(it) }) }
            item {
                Encabezado(
                    "Asignadas a mí (${vm.asignadas.size})",
                    "Consulta: $COLECCION where asignadoA == ${vm.uid}",
                    "Las reglas te dejan verlas y cambiar su estado. Si intentas cambiar otra cosa o eliminarlas, Firestore lo rechaza (SEG-14).",
                )
            }
            if (vm.asignadas.isEmpty()) item { Vacio("Nadie te ha asignado incidencias todavía.") }
            items(vm.asignadas, key = { "asignada-${it.id}" }) { TarjetaIncidencia(it, propia = false, onClick = { vm.abrir(it) }) }

            item {
                Encabezado(
                    "Incidencias de otros usuarios (${vm.ajenas.size})",
                    "Solo conoces su id (perfil público $COLECCION_USUARIOS)",
                    "Toca una para intentar leerla, modificarla o eliminarla. Firestore debe rechazarlo (SEG-05, SEG-06, SEG-07).",
                )
            }
            if (vm.ajenas.isEmpty()) item { Vacio("El otro usuario todavía no tiene incidencias sin asignar: crea una desde su dispositivo.") }
            items(vm.ajenas, key = { "ajena-${it.id}" }) { TarjetaAjena(it, onClick = { vm.abrirAjena(it) }) }
        }
        ExtendedFloatingActionButton(
            onClick = { vm.limpiarOperacion(); nueva = true },
            icon = { Icon(Icons.Filled.Add, contentDescription = null) },
            text = { Text("Nueva") },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
        )
    }

    if (nueva) DialogoNueva(vm, alCerrar = { nueva = false })
    if (vm.editando != null) DialogoEditor(vm)
    if (vm.ajena != null) DialogoAjena(vm)
}

/** Qué consulta se hace y de dónde vienen los datos. */
@Composable
private fun BarraConsulta(vm: IncidenciasViewModel) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp)) {
            Text("Mis incidencias (${vm.incidencias.size})", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Text(
                "Consulta: $COLECCION where creadoPor == ${vm.uid}",
                style = MaterialTheme.typography.labelSmall,
                fontFamily = FontFamily.Monospace,
            )
            Text(
                "Origen: ${if (vm.desdeCache) "caché local" else "servidor"} · última lectura ${hora(vm.ultimaLectura)}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun Encabezado(titulo: String, consulta: String, nota: String) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp)) {
            Text(titulo, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Text(consulta, style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
            Text(nota, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun Vacio(texto: String) {
    Text(
        texto,
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
fun TarjetaOperacion(op: Evento) {
    Surface(color = colorEvento(op.tipo).copy(alpha = 0.12f), shape = MaterialTheme.shapes.medium) {
        Column(Modifier.fillMaxWidth().padding(12.dp)) {
            Text("Resultado de la última operación · ${horaMs(op.hora)}", style = MaterialTheme.typography.labelMedium, color = colorEvento(op.tipo), fontWeight = FontWeight.Bold)
            Text(op.texto, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TarjetaIncidencia(inc: Incidencia, propia: Boolean, onClick: () -> Unit) {
    Card(Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(inc.titulo, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                Text("v${inc.version}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
            }
            FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Etiqueta(inc.estado.texto, colorEstado(inc.estado))
                Etiqueta(inc.prioridad.texto, colorPrioridad(inc.prioridad))
                if (inc.pendiente) Etiqueta("🕓 Pendiente de sincronizar", Color(0xFFFFE0B2), Color(0xFF6D3A00))
                if (propia && inc.asignada) Etiqueta("📤 Asignada a ${inc.asignadoACorreo}", colorUsuario(inc.asignadoACorreo))
                if (inc.asignada && inc.puedeEditar) Etiqueta("✏️ Puede editar", Color(0xFF6A1B9A))
                if (inc.cedida) Etiqueta("📦 Cedida por ${inc.cedidoPorCorreo}", colorUsuario(inc.cedidoPorCorreo))
                if (!propia) Etiqueta("📥 De ${inc.creadoPorCorreo}", colorUsuario(inc.creadoPorCorreo))
            }
            if (inc.descripcion.isNotEmpty()) Text(inc.descripcion, style = MaterialTheme.typography.bodySmall, maxLines = 2)
            Text("Propietario: ${inc.creadoPorCorreo}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("creadoPor ${inc.creadoPor}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun TarjetaAjena(a: IncidenciaAjena, onClick: () -> Unit) {
    Card(
        Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = colorUsuario(a.propietario.correo).copy(alpha = 0.10f)),
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("🔒 Incidencia de ${a.propietario.correo}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
            Text("id ${a.id}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
            Text("Contenido desconocido: no tienes permiso de lectura.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// ---------------------------------------------------------------------------
// Alta (SEG-03, SEG-04, SEG-11)
// ---------------------------------------------------------------------------

/** Siguiente título de prueba según el usuario: PRUEBA_A_001, PRUEBA_B_001... */
private fun sugerirTitulo(vm: IncidenciasViewModel): String {
    val letra = inicialUsuario(vm.correo)
    val usados = vm.incidencias.map { it.titulo }.toSet()
    return (1..999).map { "PRUEBA_${letra}_%03d".format(it) }.first { it !in usados }
}

@Composable
private fun DialogoNueva(vm: IncidenciasViewModel, alCerrar: () -> Unit) {
    var titulo by rememberSaveable { mutableStateOf(sugerirTitulo(vm)) }
    var descripcion by rememberSaveable { mutableStateOf("") }
    var prioridad by rememberSaveable { mutableStateOf(Prioridad.MEDIA) }
    var propietarioUid by rememberSaveable { mutableStateOf(vm.uid) }
    var asignadoUid by rememberSaveable { mutableStateOf("") }
    var cedidoUid by rememberSaveable { mutableStateOf("") }
    val cedido = vm.otros.firstOrNull { it.uid == cedidoUid }
    val propietario = vm.todos.firstOrNull { it.uid == propietarioUid } ?: vm.todos.first()
    val asignado = vm.otros.firstOrNull { it.uid == asignadoUid }

    AlertDialog(
        onDismissRequest = { if (!vm.guardando) alCerrar() },
        title = { Text("Nueva incidencia") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(titulo, { titulo = it.take(60) }, label = { Text("Título") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(
                    descripcion, { descripcion = it.take(300) },
                    label = { Text("Descripción") },
                    supportingText = { Text("${descripcion.length}/300") },
                    minLines = 2, modifier = Modifier.fillMaxWidth(),
                )
                Text("Prioridad", style = MaterialTheme.typography.labelLarge)
                Selector(Prioridad.entries, prioridad, { it.texto }, { prioridad = it })
                Text("Asignar a", style = MaterialTheme.typography.labelLarge)
                SelectorUsuario(vm.otros, asignado, vm.uid, nadie = true) { asignadoUid = it?.uid.orEmpty() }
                Text("Ceder a", style = MaterialTheme.typography.labelLarge)
                SelectorUsuario(vm.otros, cedido, vm.uid, nadie = true) { cedidoUid = it?.uid.orEmpty() }
                if (cedido != null) Aviso("Se crea directamente para ${cedido.correo} (cesión registrada con tu UID): no aparecerá en tu lista.", Color(0xFF6A1B9A))
                Text("Propietario (creadoPor)", style = MaterialTheme.typography.labelLarge)
                SelectorUsuario(vm.todos, propietario, vm.uid, nadie = false) { it?.let { u -> propietarioUid = u.uid } }
                Text("creadoPor = ${propietario.uid}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
                if (propietario.uid != vm.uid) Aviso("Estás indicando el UID de otro usuario (SEG-04): Firestore debe rechazar la escritura.", Color(0xFFE65100))
                vm.ultimaOperacion?.let { TarjetaOperacion(it) }
            }
        },
        confirmButton = {
            Button(onClick = { vm.crear(titulo, descripcion, prioridad, propietario, asignado, cedido) { ok -> if (ok) alCerrar() } }, enabled = !vm.guardando) {
                if (vm.guardando) Progreso() else Text("Guardar")
            }
        },
        dismissButton = { TextButton(onClick = alCerrar, enabled = !vm.guardando) { Text("Cerrar") } },
    )
}

// ---------------------------------------------------------------------------
// Edición y eliminación: propias (SEG-08, SEG-09, SEG-11) y asignadas (SEG-12, SEG-13, SEG-14)
// ---------------------------------------------------------------------------

@Composable
private fun DialogoEditor(vm: IncidenciasViewModel) {
    val original = vm.editando ?: return
    val propia = vm.editandoPropia
    var confirmarEliminar by rememberSaveable { mutableStateOf(false) }
    // Si un usuario de la incidencia no aparece en los perfiles se agrega para no perderlo.
    fun conocido(uid: String, correo: String) = vm.todos.firstOrNull { it.uid == uid } ?: Usuario(uid, correo, "", emptyList())
    val propietarios = (vm.todos + conocido(original.creadoPor, original.creadoPorCorreo)).distinctBy { it.uid }
    val asignables = (vm.todos + listOfNotNull(original.asignada.takeIf { it }?.let { conocido(original.asignadoA, original.asignadoACorreo) }))
        .distinctBy { it.uid }.filter { it.uid != original.creadoPor }

    AlertDialog(
        onDismissRequest = { if (!vm.guardando) vm.cerrarEditor() },
        title = { Text(original.titulo) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "id ${original.id} · v${original.version} · creada ${fecha(original.creadoEn)}",
                    style = MaterialTheme.typography.labelSmall,
                    fontFamily = FontFamily.Monospace,
                )
                if (!propia) {
                    Aviso(
                        if (original.puedeEditar) {
                            "Te la asignó ${original.creadoPorCorreo} con permiso de editar: puedes cambiar el estado y la prioridad (SEG-16). " +
                                "Cambiar la asignación o el propietario, o eliminarla, debe ser rechazado (SEG-14)."
                        } else {
                            "Te la asignó ${original.creadoPorCorreo}. Las reglas solo te dejan cambiar el estado: " +
                                "cambiar la prioridad, la asignación o el propietario, o eliminarla, debe ser rechazado (SEG-14)."
                        },
                        Color(0xFF1E5AA8),
                    )
                }
                if (original.descripcion.isNotEmpty()) Text(original.descripcion, style = MaterialTheme.typography.bodySmall)
                Text("Estado", style = MaterialTheme.typography.labelLarge)
                Selector(Estado.entries, vm.estadoEditado, { it.texto }, { vm.estadoEditado = it })
                Text("Prioridad", style = MaterialTheme.typography.labelLarge)
                Selector(Prioridad.entries, vm.prioridadEditada, { it.texto }, { vm.prioridadEditada = it })
                Text("Asignada a", style = MaterialTheme.typography.labelLarge)
                SelectorUsuario(asignables, asignables.firstOrNull { it.uid == vm.asignadoEditado }, vm.uid, nadie = true) { vm.asignadoEditado = it?.uid.orEmpty() }
                if (propia && vm.asignadoEditado.isNotEmpty()) {
                    FilterChip(
                        selected = vm.puedeEditarEditado,
                        onClick = { vm.puedeEditarEditado = !vm.puedeEditarEditado },
                        label = { Text("Permitir que edite (estado y prioridad)") },
                    )
                }
                if (propia) {
                    Text("Ceder a", style = MaterialTheme.typography.labelLarge)
                    val cedibles = vm.otros
                    SelectorUsuario(cedibles, cedibles.firstOrNull { it.uid == vm.cedidoEditado }, vm.uid, nadie = true) { vm.cedidoEditado = it?.uid.orEmpty() }
                    if (vm.cedidoEditado.isNotEmpty()) {
                        Aviso("Al guardar pasa a ser del otro usuario y desaparece de tu lista (cesión registrada con tu UID).", Color(0xFF6A1B9A))
                    }
                }
                Text("Propietario (creadoPor)", style = MaterialTheme.typography.labelLarge)
                SelectorUsuario(propietarios, propietarios.firstOrNull { it.uid == vm.propietarioEditado }, vm.uid, nadie = false) { it?.let { u -> vm.propietarioEditado = u.uid } }
                if (vm.propietarioEditado != original.creadoPor) {
                    Aviso("Cambiar el propietario debe ser rechazado por Firestore (${if (propia) "SEG-09" else "SEG-14"}).", Color(0xFFE65100))
                }
                vm.ultimaOperacion?.let { TarjetaOperacion(it) }

                if (confirmarEliminar) {
                    Aviso("¿Eliminar ${original.titulo}?", Color(0xFFB71C1C))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { confirmarEliminar = false }) { Text("No") }
                        Button(
                            onClick = { confirmarEliminar = false; vm.eliminar(original) },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFB71C1C)),
                            enabled = !vm.guardando,
                        ) { Text("Sí, eliminar") }
                    }
                } else {
                    TextButton(onClick = { confirmarEliminar = true }) { Text("Eliminar incidencia", color = Color(0xFFB71C1C)) }
                }
            }
        },
        confirmButton = {
            Button(onClick = vm::guardarEdicion, enabled = !vm.guardando) {
                if (vm.guardando) Progreso() else Text("Guardar")
            }
        },
        dismissButton = { TextButton(onClick = vm::cerrarEditor, enabled = !vm.guardando) { Text("Cerrar") } },
    )
}

// ---------------------------------------------------------------------------
// Incidencia de otro usuario (SEG-05, SEG-06, SEG-07)
// ---------------------------------------------------------------------------

@Composable
private fun DialogoAjena(vm: IncidenciasViewModel) {
    val a = vm.ajena ?: return
    var estado by rememberSaveable { mutableStateOf(Estado.RESUELTA) }

    AlertDialog(
        onDismissRequest = { if (!vm.guardando) vm.cerrarAjena() },
        title = { Text("Incidencia de ${a.propietario.correo}") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("id ${a.id}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
                Text("Propietario (creadoPor): ${a.propietario.uid}", style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
                Text(
                    "Intenta operar sobre una incidencia que no es tuya. La petición se envía al servidor y se muestra lo que responde Firestore.",
                    style = MaterialTheme.typography.bodySmall,
                )
                Text("SEG-05 · Lectura directa", style = MaterialTheme.typography.labelLarge)
                OutlinedButton(onClick = vm::leerAjena, enabled = !vm.guardando, modifier = Modifier.fillMaxWidth()) { Text("Leer") }
                Text("SEG-06 · Modificar el estado", style = MaterialTheme.typography.labelLarge)
                Selector(Estado.entries, estado, { it.texto }, { estado = it })
                OutlinedButton(onClick = { vm.modificarAjena(estado) }, enabled = !vm.guardando, modifier = Modifier.fillMaxWidth()) { Text("Modificar") }
                Text("SEG-07 · Eliminar", style = MaterialTheme.typography.labelLarge)
                OutlinedButton(onClick = vm::eliminarAjena, enabled = !vm.guardando, modifier = Modifier.fillMaxWidth()) {
                    Text("Eliminar", color = Color(0xFFB71C1C))
                }
                if (vm.guardando) Progreso()
                vm.ultimaOperacion?.let { TarjetaOperacion(it) }
            }
        },
        confirmButton = { TextButton(onClick = vm::cerrarAjena, enabled = !vm.guardando) { Text("Cerrar") } },
    )
}

@Composable
fun Aviso(texto: String, color: Color) {
    Surface(color = color.copy(alpha = 0.12f), shape = MaterialTheme.shapes.small) {
        Text(texto, color = color, style = MaterialTheme.typography.bodySmall, modifier = Modifier.fillMaxWidth().padding(10.dp))
    }
}

/** Elige un usuario (con la opción "Nadie" si [nadie]); la sesión se marca con "(tú)". */
@Composable
private fun SelectorUsuario(usuarios: List<Usuario>, seleccion: Usuario?, yo: String, nadie: Boolean, alElegir: (Usuario?) -> Unit) {
    if (usuarios.isEmpty()) {
        Text(
            "No hay otros usuarios registrados: inicia sesión con la otra cuenta en el segundo dispositivo.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        return
    }
    val opciones = if (nadie) listOf<Usuario?>(null) + usuarios else usuarios
    Selector(opciones, seleccion, { u -> u?.let { it.correo + if (it.uid == yo) " (tú)" else "" } ?: "Nadie" }, alElegir)
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun <T> Selector(opciones: List<T>, seleccion: T, texto: (T) -> String, alElegir: (T) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        opciones.forEach { o -> FilterChip(selected = o == seleccion, onClick = { alElegir(o) }, label = { Text(texto(o)) }) }
    }
}
