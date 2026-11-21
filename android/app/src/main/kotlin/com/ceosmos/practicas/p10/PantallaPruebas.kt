package com.ceosmos.practicas.p10

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

// ---------------------------------------------------------------------------
// Seguridad: matriz SEG-01 … SEG-14 (se llena con las pruebas manuales)
// ---------------------------------------------------------------------------

@Composable
fun PantallaSeguridad(vm: IncidenciasViewModel) {
    val otro = vm.otro
    val pasaron = CASOS_SEGURIDAD.count { (vm.resultados[it.id] ?: vm.matriz[it.id])?.paso == true }
    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item {
            Seccion("Matriz de pruebas · $pasaron/${CASOS_SEGURIDAD.size} pasaron") {
                Text(
                    "Las pruebas se hacen a mano desde la app (cada caso dice dónde). La interfaz no bloquea las operaciones " +
                        "no autorizadas: las envía al servidor, y el resultado se anota aquí según lo que respondió Firestore " +
                        "o Authentication. Pasa cuando la respuesta coincide con lo esperado.",
                    style = MaterialTheme.typography.bodySmall,
                )
                Dato("Sesión", vm.correo)
                Dato("UID", vm.uid)
                Dato("Otro usuario", otro?.correo ?: "— (inicia sesión con la otra cuenta)")
                Dato("UID ajeno", otro?.uid ?: "—")
                Dato("Ids ajenos", "${vm.ajenas.size} conocidos")
                Dato("Asignadas a mí", "${vm.asignadas.size}")
            }
        }
        vm.errorMatriz?.let { e -> item { Text("No se pudo leer la matriz compartida: $e", color = MaterialTheme.colorScheme.error) } }
        items(CASOS_SEGURIDAD, key = { it.id }) { caso ->
            TarjetaCaso(caso, vm.resultados[caso.id], vm.matriz[caso.id])
        }
    }
}

@Composable
private fun TarjetaCaso(caso: CasoSeguridad, propio: ResultadoSeguridad?, compartido: ResultadoSeguridad?) {
    val r = propio ?: compartido
    Card {
        Column(Modifier.fillMaxWidth().padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("${caso.id} · ${caso.nombre}", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                when {
                    r == null -> Etiqueta("Sin ejecutar", Color(0xFF6B5A60))
                    r.paso -> Etiqueta("Pasó", Color(0xFF17805A))
                    else -> Etiqueta("Falló", Color(0xFFC42A3F))
                }
            }
            Text("Acción: ${caso.accion}", style = MaterialTheme.typography.bodySmall)
            Text("Esperado: ${caso.esperado}", style = MaterialTheme.typography.bodySmall)
            Text("Cómo probarlo: ${caso.comoProbar}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
            r?.let {
                Text(
                    it.evidencia,
                    style = MaterialTheme.typography.bodySmall,
                    fontFamily = FontFamily.Monospace,
                    color = if (it.paso) Color(0xFF17805A) else Color(0xFFC42A3F),
                )
                Text("Realizada por ${it.ejecutadoPor} · ${fecha(it.fecha)}", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Bitácora de operaciones
// ---------------------------------------------------------------------------

@Composable
fun PantallaBitacora(vm: IncidenciasViewModel) {
    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Bitácora de ${vm.correo}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        "Azul: operación propia · Verde: prueba que pasó · Naranja: aviso · Rojo: rechazo o error. " +
                            "También se escribe en Logcat con la etiqueta $TAG_SEGURIDAD.",
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
// Cuenta: identidad del usuario autenticado
// ---------------------------------------------------------------------------

@Composable
fun PantallaCuenta(vm: IncidenciasViewModel) {
    LazyColumn(contentPadding = PaddingValues(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item {
            Seccion("Usuario autenticado (Firebase Authentication)") {
                Dato("Correo", vm.correo)
                Dato("UID", vm.uid)
                Dato("Proveedor", vm.usuario?.providerData?.lastOrNull()?.providerId ?: "—")
                Dato("Creada", fecha(vm.usuario?.metadata?.creationTimestamp))
                Dato("Último acceso", fecha(vm.usuario?.metadata?.lastSignInTimestamp))
                Dato("Equipo", vm.modelo)
                Dato("Instalación", "${vm.instalacionCorta}… (sesión única)")
                Text(
                    "El UID lo asigna Firebase al crear la cuenta y no se puede elegir. Es el valor que se guarda en creadoPor " +
                        "y el que comparan las reglas (request.auth.uid). La cuenta solo puede estar abierta en un dispositivo " +
                        "a la vez ($COLECCION_SESIONES).",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                OutlinedButton(onClick = vm::cerrarSesion, modifier = Modifier.fillMaxWidth()) { Text("Cerrar sesión") }
            }
        }
        item {
            Seccion("Base de datos") {
                Dato("Proyecto", vm.proyecto)
                Dato("App ID", vm.appId)
                Dato("Colección", COLECCION)
                Dato("Red", if (vm.enLinea) "En línea" else "Sin conexión")
            }
        }
        item {
            Seccion("Usuarios registrados ($COLECCION_USUARIOS)") {
                if (vm.usuarios.isEmpty()) Text("Ninguno todavía.", style = MaterialTheme.typography.bodySmall)
                vm.usuarios.forEachIndexed { i, u ->
                    if (i > 0) HorizontalDivider()
                    Text(u.correo + if (u.uid == vm.uid) "  (tú)" else "", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                    Text(u.uid, style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
                    Text(u.equipo, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text(
                    "El perfil público solo contiene correo, UID, equipo y los id de tus incidencias sin asignar. " +
                        "Conocer el id no da acceso: las reglas comparan el propietario con la sesión.",
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
        Text(nombre, style = MaterialTheme.typography.bodySmall, modifier = Modifier.width(110.dp), color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(valor, style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace)
    }
}
