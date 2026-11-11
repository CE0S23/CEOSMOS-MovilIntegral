package com.ceosmos.practicas.p09

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

// ---------------------------------------------------------------------------
// Bitácora de sincronización
// ---------------------------------------------------------------------------

@Composable
fun PantallaBitacora(vm: IncidenciasViewModel) {
    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Bitácora de ${vm.miNombre}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        "Azul: este dispositivo · Verde: llegó de otro dispositivo · Naranja: aviso · Rojo: error",
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
                TextButton(onClick = vm::limpiarBitacora) { Text("Limpiar") }
            }
        }
        if (vm.eventos.isEmpty()) item { Text("Sin eventos todavía.", color = MaterialTheme.colorScheme.onSurfaceVariant) }
        items(vm.eventos) { e ->
            Row(verticalAlignment = Alignment.Top) {
                Box(Modifier.padding(top = 5.dp).size(8.dp).background(colorEvento(e.tipo), CircleShape))
                Spacer(Modifier.width(8.dp))
                Column {
                    Text(horaMs(e.hora), style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace)
                    Text(e.texto, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Conexión: almacenamiento local vs compartido
// ---------------------------------------------------------------------------

@Composable
fun PantallaConexion(vm: IncidenciasViewModel) {
    var nombre by rememberSaveable(vm.miNombre) { mutableStateOf(vm.miNombre) }

    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item {
            Seccion("Base de datos compartida (Cloud Firestore)") {
                Dato("Proyecto", vm.proyecto)
                Dato("App ID", vm.appId)
                Dato("Colección", COLECCION)
                Dato("Red", if (vm.enLinea) "En línea" else "Sin conexión")
                Dato("Origen de los datos", if (vm.desdeCache) "Caché local (sin confirmar con el servidor)" else "Servidor")
                Dato("Última lectura", hora(vm.ultimaLectura))
                Dato("Desfase de reloj", vm.desfaseReloj?.let { "%+.1f s respecto al servidor".format(it / 1000.0) } ?: "sin medir (se mide al guardar)")
                Dato("Documentos", "${vm.incidencias.size} (${vm.pendientes} sin sincronizar)")
                Text(
                    "Los dos dispositivos deben mostrar el mismo proyecto y colección: es una sola base de datos.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                OutlinedButton(onClick = vm::consultar, enabled = !vm.consultando, modifier = Modifier.fillMaxWidth()) {
                    Text("Consultar el servidor ahora")
                }
            }
        }
        item {
            Seccion("Estado actual de la colección") {
                if (vm.incidencias.isEmpty()) Text("Colección vacía (0 documentos).", style = MaterialTheme.typography.bodySmall)
                vm.incidencias.forEach {
                    Text(
                        "${it.titulo} · ${it.estado.texto} · ${it.prioridad.texto} · v${it.version}${if (it.pendiente) " · pendiente" else ""}",
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace,
                    )
                }
            }
        }
        item {
            Seccion("Este dispositivo (almacenamiento local)") {
                Dato("Equipo", vm.modelo)
                OutlinedTextField(nombre, { nombre = it.take(30) }, label = { Text("Nombre del dispositivo") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                Button(onClick = { vm.cambiarNombre(nombre) }, enabled = nombre.trim() != vm.miNombre) { Text("Guardar nombre") }
                HorizontalDivider()
                Text("Política de actualización (Fase 4)", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                Politica.entries.forEach { p ->
                    Row(
                        Modifier.fillMaxWidth().selectable(selected = vm.politica == p, onClick = { vm.cambiarPolitica(p) }),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = vm.politica == p, onClick = null)
                        Spacer(Modifier.width(8.dp))
                        Column {
                            Text(p.titulo, style = MaterialTheme.typography.bodyMedium)
                            Text(p.detalle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
                Text(
                    "El nombre y la política se guardan solo en este teléfono (SharedPreferences); no se comparten.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun Seccion(titulo: String, contenido: @Composable () -> Unit) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(titulo, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
            contenido()
        }
    }
}

@Composable
private fun Dato(nombre: String, valor: String) {
    Row {
        Text(nombre, style = MaterialTheme.typography.bodySmall, modifier = Modifier.width(120.dp), color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(valor, style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
    }
}

// ---------------------------------------------------------------------------
// Matriz de pruebas DB-01 – DB-09 (compartida en Firestore)
// ---------------------------------------------------------------------------

@Composable
fun PantallaMatriz(vm: IncidenciasViewModel) {
    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item {
            Text(
                "Los resultados se guardan en \"$COLECCION_MATRIZ\" y se ven en ambos dispositivos.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
        vm.errorMatriz?.let { e -> item { Text("No se pudo leer la matriz: $e", color = MaterialTheme.colorScheme.error) } }
        items(CASOS_PRUEBA, key = { it.id }) { caso -> TarjetaCaso(vm, caso, vm.matriz[caso.id]) }
    }
}

@Composable
private fun TarjetaCaso(vm: IncidenciasViewModel, caso: CasoPrueba, registro: RegistroMatriz?) {
    // Se reinicia cuando llega un registro nuevo del servidor (por ejemplo, desde el otro dispositivo).
    var resultado by rememberSaveable(registro) { mutableStateOf(registro?.resultado ?: RESULTADOS.first()) }
    var observacion by rememberSaveable(registro) { mutableStateOf(registro?.observacion.orEmpty()) }

    Card {
        Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("${caso.id} · ${caso.nombre}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
            Text("Esperado: ${caso.esperado}", style = MaterialTheme.typography.bodySmall)
            Selector(RESULTADOS, resultado, { it }, { resultado = it })
            OutlinedTextField(observacion, { observacion = it.take(400) }, label = { Text("Observación") }, minLines = 2, modifier = Modifier.fillMaxWidth())
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    registro?.let { "Registrado por ${it.registradoPor} · ${fecha(it.fecha)}" } ?: "Sin registrar",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f),
                )
                Button(onClick = { vm.registrarPrueba(caso, resultado, observacion) }) { Text("Guardar") }
            }
        }
    }
}
