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
