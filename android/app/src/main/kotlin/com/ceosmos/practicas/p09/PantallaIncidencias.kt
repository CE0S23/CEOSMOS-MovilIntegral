package com.ceosmos.practicas.p09

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
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

@Composable
fun PantallaIncidencias(vm: IncidenciasViewModel) {
    var nueva by rememberSaveable { mutableStateOf(false) }

    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            contentPadding = PaddingValues(start = 12.dp, end = 12.dp, top = 10.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item { BarraSincronizacion(vm) }
            vm.ultimaOperacion?.let { op -> item { TarjetaOperacion(op) } }
            vm.errorLectura?.let { e -> item { Text("Error de lectura: $e", color = MaterialTheme.colorScheme.error) } }
            if (!vm.cargando && vm.incidencias.isEmpty()) {
                item {
                    Text(
                        "La colección \"$COLECCION\" está vacía. Registra la primera incidencia con el botón Nueva.",
                        modifier = Modifier.padding(24.dp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            items(vm.incidencias, key = { it.id }) { TarjetaIncidencia(it, onClick = { vm.abrir(it) }) }
        }
        ExtendedFloatingActionButton(
            onClick = { nueva = true },
            icon = { Icon(Icons.Filled.Add, contentDescription = null) },
            text = { Text("Nueva") },
            modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
        )
    }

    if (nueva) DialogoNueva(vm, alCerrar = { nueva = false })
    if (vm.editando != null) DialogoEditor(vm)
}

/** Modo de lectura, origen de los datos y escrituras pendientes. */
@Composable
private fun BarraSincronizacion(vm: IncidenciasViewModel) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        Column(Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Actualización en tiempo real", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                    Text(
                        if (vm.tiempoReal) "Los cambios de otros dispositivos llegan solos" else "Pulsa Consultar para ver cambios",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                Switch(checked = vm.tiempoReal, onCheckedChange = vm::cambiarTiempoReal)
            }
            HorizontalDivider(Modifier.padding(vertical = 6.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(
                        "${vm.incidencias.size} incidencias · origen: ${if (vm.desdeCache) "caché local" else "servidor"}",
                        style = MaterialTheme.typography.bodySmall,
                    )
                    Text(
                        "Última lectura ${hora(vm.ultimaLectura)}" + if (vm.pendientes > 0) " · ${vm.pendientes} sin sincronizar" else "",
                        style = MaterialTheme.typography.bodySmall,
                        color = if (vm.pendientes > 0) Color(0xFFE65100) else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                TextButton(onClick = vm::consultar, enabled = !vm.consultando) {
                    if (vm.consultando) Progreso() else Icon(Icons.Filled.Refresh, contentDescription = null)
                    Spacer(Modifier.width(6.dp))
                    Text("Consultar")
                }
            }
        }
    }
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
private fun TarjetaIncidencia(inc: Incidencia, onClick: () -> Unit) {
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
            }
            if (inc.descripcion.isNotEmpty()) Text(inc.descripcion, style = MaterialTheme.typography.bodySmall, maxLines = 2)
            Text(
                "Creada por ${inc.creadoPor} · modificada por ${inc.actualizadoPor} a las ${hora(inc.actualizadoEn)}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

// ---------------------------------------------------------------------------
// Alta
// ---------------------------------------------------------------------------

/** Siguiente título de prueba según el dispositivo: PRUEBA_A_001, PRUEBA_B_001... */
private fun sugerirTitulo(vm: IncidenciasViewModel): String {
    val letra = inicial(vm.miNombre).ifEmpty { "X" }
    val usados = vm.incidencias.map { it.titulo }.toSet()
    return (1..999).map { "PRUEBA_${letra}_%03d".format(it) }.first { it !in usados }
}

@Composable
private fun DialogoNueva(vm: IncidenciasViewModel, alCerrar: () -> Unit) {
    var titulo by rememberSaveable { mutableStateOf(sugerirTitulo(vm)) }
    var descripcion by rememberSaveable { mutableStateOf("") }
    var prioridad by rememberSaveable { mutableStateOf(Prioridad.MEDIA) }

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
                Text("Estado inicial: ${Estado.PENDIENTE.texto}", style = MaterialTheme.typography.bodySmall)
            }
        },
        confirmButton = {
            Button(onClick = { vm.crear(titulo, descripcion, prioridad) { ok -> if (ok) alCerrar() } }, enabled = !vm.guardando) {
                if (vm.guardando) Progreso() else Text("Guardar")
            }
        },
        dismissButton = { TextButton(onClick = alCerrar, enabled = !vm.guardando) { Text("Cancelar") } },
    )
}

// ---------------------------------------------------------------------------
// Edición (estado y prioridad), conflictos y eliminación
// ---------------------------------------------------------------------------

@Composable
private fun DialogoEditor(vm: IncidenciasViewModel) {
    val original = vm.editando ?: return
    val actual = vm.editandoActual
    var confirmarEliminar by rememberSaveable { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = { if (!vm.guardando) vm.cerrarEditor() },
        title = { Text(original.titulo) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    "id ${original.id} · abierta en v${original.version} · creada por ${original.creadoPor} (${fecha(original.creadoEn)})",
                    style = MaterialTheme.typography.labelSmall,
                    fontFamily = FontFamily.Monospace,
                )
                if (original.descripcion.isNotEmpty()) Text(original.descripcion, style = MaterialTheme.typography.bodySmall)

                // Aviso en vivo: otro dispositivo modificó o eliminó el registro mientras está abierto.
                when {
                    actual == null && !vm.cargando -> Aviso("Esta incidencia fue eliminada en otro dispositivo.", Color(0xFFB71C1C))
                    actual != null && actual.version != original.version -> Aviso(
                        "${actual.actualizadoPor} la modificó mientras estaba abierta: ahora v${actual.version}, " +
                            "${actual.estado.texto} / ${actual.prioridad.texto}.",
                        Color(0xFFE65100),
                    )
                }

                Text("Estado", style = MaterialTheme.typography.labelLarge)
                Selector(Estado.entries, vm.estadoEditado, { it.texto }, { vm.estadoEditado = it })
                Text("Prioridad", style = MaterialTheme.typography.labelLarge)
                Selector(Prioridad.entries, vm.prioridadEditada, { it.texto }, { vm.prioridadEditada = it })
                Text("Política al guardar: ${vm.politica.titulo}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)

                vm.conflicto?.let { c -> PanelConflicto(vm, c) }

                if (confirmarEliminar) {
                    Aviso("¿Eliminar ${original.titulo} para todos los dispositivos?", Color(0xFFB71C1C))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { confirmarEliminar = false }) { Text("No") }
                        Button(
                            onClick = { vm.eliminar(original) },
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
            Button(onClick = { vm.guardarEdicion() }, enabled = !vm.guardando && vm.conflicto == null) {
                if (vm.guardando) Progreso() else Text("Guardar")
            }
        },
        dismissButton = { TextButton(onClick = vm::cerrarEditor, enabled = !vm.guardando) { Text("Cerrar") } },
    )
}

@Composable
private fun PanelConflicto(vm: IncidenciasViewModel, c: ResultadoGuardado.Conflicto) {
    Surface(color = Color(0xFFE65100).copy(alpha = 0.12f), shape = MaterialTheme.shapes.medium) {
        Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("Conflicto de actualización", fontWeight = FontWeight.Bold, color = Color(0xFFE65100))
            Text(
                "${c.remota.actualizadoPor} cambió ${c.campos.joinToString()} mientras editabas. " +
                    "En el servidor: ${c.remota.estado.texto} / ${c.remota.prioridad.texto} (v${c.remota.version}). " +
                    "Tus valores: ${vm.estadoEditado.texto} / ${vm.prioridadEditada.texto}.",
                style = MaterialTheme.typography.bodySmall,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(onClick = vm::aceptarRemoto) { Text("Usar los del servidor") }
                Button(onClick = { vm.guardarEdicion(forzar = true) }, enabled = !vm.guardando) { Text("Sobrescribir") }
            }
        }
    }
}

@Composable
fun Aviso(texto: String, color: Color) {
    Surface(color = color.copy(alpha = 0.12f), shape = MaterialTheme.shapes.small) {
        Text(texto, color = color, style = MaterialTheme.typography.bodySmall, modifier = Modifier.fillMaxWidth().padding(10.dp))
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun <T> Selector(opciones: List<T>, seleccion: T, texto: (T) -> String, alElegir: (T) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        opciones.forEach { o -> FilterChip(selected = o == seleccion, onClick = { alElegir(o) }, label = { Text(texto(o)) }) }
    }
}
