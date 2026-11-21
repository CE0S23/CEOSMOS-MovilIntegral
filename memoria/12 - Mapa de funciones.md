---
tags: [ceosmos, funciones, navegacion]
estado: vigente
actualizado: 2026-11-21
---

# 12 · Mapa de funciones

Desde el 21/11/2026 las prácticas ya no viven en una ventana «Prácticas»: son **funciones de CEOSMOS** con nombre
funcional, cada una en su sección. Ningún texto visible dice «Práctica», «P#», «Examen» ni «Eval.»; solo el botón
ⓘ «Referencia académica» de cada función nombra su práctica de origen (ver *Botón ⓘ* abajo).
Los nombres internos (carpetas `lib/practicas/p07`, ids `p09`, claves, apps Firebase con nombre) no cambiaron.

| Función | Dónde está en la app | Rol | Práctica de origen | Código | BD / almacenamiento |
|---|---|---|---|---|---|
| Tickets y chat interno | Soporte › Tickets y chat interno | Usuario: crear ticket e historial · Agente: tickets asignados · Admin: asignados, todos, dispositivos, reasignar, limpiar historial | [[Práctica 07 - Roles y mensajería (Sistema de tickets)]] | `lib/practicas/p07/` | Firebase `practica7-8-941cb` (app «practica7») |
| Incidencias sin conexión | Soporte › Incidencias sin conexión | Todos | [[Examen 1 - Incidencias de soporte]] | `lib/practicas/examen1/` | SharedPreferences `examen1.incidencias` |
| Reportes compartidos | Soporte › Reportes e incidencias | Todos | [[Práctica BD - Reportes Firestore]] | `lib/practicas/bd_flutter/` | Firebase `reportes-movil-20261019` (app «bd_flutter») |
| Reportes compartidos (Android) | Soporte › Reportes e incidencias | Todos | [[Práctica BD - Reportes Firestore]] | `android/.../practicas/bdnativo/` | Firebase `reportes-movil-20261019` (app «bd_nativo») |
| Incidencias en tiempo real | Soporte › Reportes e incidencias | Todos (dos equipos) | [[Práctica 09 - Base de datos compartida entre dispositivos]] | `android/.../practicas/p09/` | Firebase `mesaayuda-p7` (app «p09») |
| Mis incidencias y acceso | Soporte › Reportes e incidencias | Cada cuenta ve lo suyo / asignado | [[Práctica 10 - Seguridad y control de acceso]] | `android/.../practicas/p10/` | Firebase `mesaayuda-p7` (app «p10») + reglas |
| Mensajería entre equipos | Equipos (debajo de Reloj, TV y wearable) | Todos | [[Práctica 06 - Interacción entre dispositivos (MobileConnect)]] | `lib/practicas/p06/` | Sin BD (memoria) |
| Seguridad de la cuenta | Perfil › Cuenta y herramientas | Todos | [[Práctica 05 - Código seguro (AccesoSeguro)]] | `lib/practicas/p05/` + `AccesoSeguroChannel.kt` | Sin BD |
| Directorio de alumnos | Perfil › Cuenta y herramientas | Todos | [[Práctica 03 - Consumo de servicio web]] · [[Práctica 04 - Almacenamiento estructurado]] | `lib/practicas/p03_04/` | SQLite `p03_04_usuarios.db` (Floor) |
| Citas de bienestar | Perfil › Cuenta y herramientas | Todos (requiere servidor local) | [[Evaluación 2 - MediConnect]] | `lib/practicas/eval2/` | API propia `https://localhost:3443` + almacén seguro propio |
| Aviso «Sin conexión» y sincronización | Dentro de Soporte y Reportes (sin menú) | — | [[Práctica 12 - Optimización, estrés y resiliencia]] | `p07/widgets/banner_conexion.dart`, P9/P10 | — |
| Calidad y pruebas (sin pantalla) | — | — | [[Práctica 08 - Pruebas de caja negra]] · [[Práctica 11 - Pruebas White Box]] · [[Práctica 13-14 - Automatización de pruebas y CI]] | `test/`, `integration_test/`, `.github/workflows/` | — |

El registro único está en `lib/practicas/registro_practicas.dart` (título, sección, ruta visible e ícono de cada función).
Pestañas: Inicio · Explorar · Mi sesión · Equipos · **Soporte** (antes «Prácticas») · Perfil.
La sección **Administración** de Perfil sigue siendo solo para cuentas ADMIN de CEOSMOS.

## Decisiones (distintas o no previstas en la propuesta)
- **Soporte** reemplaza a la pestaña «Prácticas» en la barra inferior, porque reúne tickets, incidencias locales y reportes. «Reportes e incidencias» es un grupo dentro de Soporte, no otra pestaña.
- **Mis incidencias y acceso** sigue siendo su propia pantalla nativa, porque usa otra app Firebase con cuentas y reglas propias. Fusionarla con *Incidencias en tiempo real* cambiaría la lógica.
- **Examen 1 → Incidencias sin conexión**, en Soporte: es una bitácora local de fallas.
- **Evaluación 2 → Citas de bienestar**, en Perfil › Cuenta y herramientas: son citas con especialista, encaja con el bienestar.
- **Directorio de alumnos** queda en Perfil › Cuenta y herramientas, visible para todos: no era exclusivo de un rol.
- Se conservan la barra superior de cada función, renombrada a «← Soporte / Equipos / Perfil · nombre · ⓘ», y la barra de sesión en curso, que sigue siendo útil.
- El botón Atrás de Android vuelve a la sección: se conserva `PracticaHost` y `atrasManejadoPorCeosmos`.

## Botón ⓘ «Referencia académica»
- Textos centralizados en `lib/core/referencias_academicas.dart` (mapa id → práctica + «Cómo se integró en CEOSMOS»).
- En las pantallas nativas el texto llega por el canal `ceosmos/practicas` (`referencia`) y se muestra en un diálogo de Android.
- **Para apagarlo antes de la entrega:** en `lib/core/referencias_academicas.dart` cambia
  `const bool mostrarReferenciasAcademicas = true;` a `false`, compila e instala. Desaparecen todos los ⓘ (Flutter y nativos).
  La prueba `test/navegacion_funciones_test.dart` se adapta sola al valor.

## Verificación (21/11/2026)
- [x] `flutter analyze` sin issues · `flutter test` 216/216 (nueva `test/navegacion_funciones_test.dart`) · companion `./gradlew test lint` verde · APK debug compila.
- [x] Capturas en `evidencias/reestructura/` (menús, admin y cada función Flutter con su ⓘ abierto).
- [ ] Recorrido en S24 + Tab S9 (4 roles de Soporte, Reportes entre equipos, mensajería, Directorio, Seguridad, Reloj y TV, claro/oscuro): no había equipos en `adb devices`. → [[08 - Pendientes]]

---
Navegación: [[00 - Índice CEOSMOS]] · [[04 - Módulos de la app]] · [[11 - Sistema de diseño]]
