---
tags: [ceosmos, ble, wearable, tv]
estado: vigente
actualizado: 2026-11-18
---

# BLE: Reloj y TV

## Arquitectura
- **CEOSMOS (S24) = central** (`lib/core/ble/`): `ble_protocolo.dart` (UUID, HMAC, validación), `ecosistema_ble.dart` (estado, PIN, reconexión), `ble_transporte_fbp.dart` (radio real), `lib/ui/ble_section.dart` (pestaña Equipos).
- **Periféricos** (`companion/`, Kotlin + Compose): `ServidorGatt.kt` (servidor GATT + anuncio), `Protocolo.kt`, `Nucleo.kt` (PIN/id, simulación de lecturas, servicio en primer plano `connectedDevice`).
- Sabores: `com.ceosmos.companion.reloj` (UI circular), `com.ceosmos.companion.tv` (horizontal, D-pad), `com.ceosmos.companion` (ambos servicios en un servidor, alternativa).
- **TV nativa, no PWA**: las indicaciones del profesor no exigen PWA para la TV y Web Bluetooth no puede ser periférico (ver [[09 - Decisiones técnicas]]).

## UUID fijos (base `-9b1a-4c5e-8a10-ce05a0b1e000`)
| Rol | Servicio | AUTH (read/write) | A_DISP (write) | DE_DISP (notify) |
| --- | --- | --- | --- | --- |
| Reloj | `6c3e1000-…` | `6c3e1001-…` | `6c3e1002-…` | `6c3e1003-…` |
| TV | `6c3e2000-…` | `6c3e2001-…` | `6c3e2002-…` | `6c3e2003-…` |

Anuncio: UUID del servicio; respuesta de escaneo con datos de fabricante `0xFFFF` = `[rol, id de 4 bytes]`.
En la API se guarda como `CE:05:` + id (la MAC del periférico rota por privacidad).

## Protocolo (JSON ≤ 180 bytes)
- CEOSMOS → periférico: `hello`, `bye`, `session` (estado, título, modo, restante, total, hr, usuario), `notif` (solo reloj).
- Reloj → CEOSMOS: `hr` (30–230 bpm, pasos), `btn` (`toggle`/`stop`), `hello`. TV → CEOSMOS: `cmd` (`toggle`/`stop`/`next`/`prev`).

## 1.4.0 (26/11/2026): simulación de actividades, alertas y robustez
- **Lecturas** `{"t":"hr","hr":72,"steps":120,"act":"caminando"}` cada 1 s. `act` ∈ reposo, durmiendo, caminando, trotando, corriendo; opcional y compatible hacia atrás (un CEOSMOS 1.3 lo ignora; un `act` desconocido se ignora sin descartar la lectura). Vector común en `SimuladorTest.kt` y `test/ble/alertas_actividad_test.dart`.
- **Alerta** CEOSMOS → Reloj y TV: `{"t":"alert","lvl":"aviso|urgente","msg":"…"}` (≤ 120 caracteres). El Reloj vibra (patrón) y la muestra con «Entendido»; la TV la muestra en grande.
- **Modos del Reloj** (`Simulador.kt`): Reposo 60–75, Durmiendo 48–60 sin pasos, Caminando 85–105 (~100 pasos/min), Trotando 120–145 (~150), Corriendo 150–175 (~170), Frecuencia alta 150–190 y baja 35–45 (en reposo), Automático (ciclo de 30 s por etapa). Transición ≤ 4 bpm/s, ruido ±1, siempre 30–230. Rótulo «Pulso simulado: no es una medición médica». «Sensor real» solo para pasos: contador → detector → acelerómetro.
- **Reglas** (`lib/core/alertas_salud.dart`): alto sostenido 10 s en reposo >100, durmiendo >90, caminando >130; muy alto ≥185 (3 s, urgente); bajo ≤45 despierto (10 s). Correr con su pulso no alerta. Enfriamiento 60 s por tipo, tope 5 por sesión. Entrega: notificación (canal «Alertas de salud»), aviso en la app, Reloj, TV y `metadata.wearable` (`activitySeconds`, `alerts`, `maxHeartRate`, `simulated`). Interruptor en Perfil › Cuenta y herramientas.
- **Robustez**: (1) el periférico notificaba sin esperar `onNotificationSent` → con una lectura en vuelo el botón recibía «ocupado» y se perdía; ahora `ColaNotificaciones` (una en vuelo, botones primero, lecturas sin atraso, reintento). (2) `BotonTv` tenía `onKeyEvent` + `.focusable()` además del clic del botón → una tecla del D-pad disparaba dos «toggle» (no cambiaba nada) y había dos paradas de foco por botón. (3) Rebote de 350 ms por tecla. (4) Central: una operación GATT a la vez por enlace (Reloj+TV comparten enlace), un reintento ante fallo transitorio y una sola reautenticación aunque fallen varias escrituras en cola. Feedback en pantalla: «Enviando…», «recibido por CEOSMOS», «No llegó…».

## Seguridad
- [x] PIN de 6 dígitos en el periférico; CEOSMOS responde **HMAC-SHA256(PIN, reto‖rol)** al reto aleatorio (el PIN nunca viaja).
- [x] Sin autenticar: escrituras y suscripciones rechazadas con GATT_INSUFFICIENT_AUTHORIZATION (8); 3 fallos → desconexión y bloqueo de 60 s; reto de un solo uso con límite de 30 s.
- [x] Validación de cada mensaje y límite de 20 mensajes/s; PIN guardado en almacenamiento seguro; «Nuevo PIN» revoca el acceso.
- [ ] Cifrado del enlace (bonding LE Secure Connections) como mejora → [[08 - Pendientes]].

## Pruebas reales S24 ↔ Tab S9 (18/11/2026, evidencias `evidencias/ble_*`)
- [x] Las dos apps anuncian y sirven GATT **a la vez** en la tablet («Varios anuncios a la vez: sí»): no hizo falta la app única.
- [x] Conexión con PIN, lecturas del reloj en vivo, notificación S24 → reloj.
- [x] TV «Siguiente» inicia la sesión en el S24; la TV la proyecta con el pulso del reloj; pausa desde la TV y reanudar desde el botón del reloj.
- [x] Reconexión sin PIN tras reinstalar (PIN y vinculación guardados en la cuenta de Neon).
- [x] App TV cerrada y reabierta → reautenticación automática (defecto encontrado y corregido).
- [x] Bluetooth apagado → «Reconectando…»; al encender, ambos roles reconectan solos (defecto de escaneo simultáneo encontrado y corregido).
- [x] Permiso denegado → mensaje y apertura de Ajustes. CEOSMOS en segundo plano sigue proyectando.

---
Navegación: [[00 - Índice CEOSMOS]] · [[03 - Arquitectura y stack]] · [[07 - Pruebas (Black, White, Red Box)]] · [[09 - Decisiones técnicas]] · [[08 - Pendientes]]
