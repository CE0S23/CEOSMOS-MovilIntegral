---
tags: [ceosmos, requerimientos]
estado: vigente
actualizado: 2026-11-18
---

# Requerimientos

Fuente: *Reporte de avances* (3 parciales) y memorias anteriores. Estado comprobado en el código.

## Primer parcial — Arquitectura base y fusión de interfaces
- [x] Proyecto Flutter unificado (Android/iOS/Web/Windows; `lib/`).
- [x] UI de feeds (concentración, relajación, inspiración) con búsqueda sin acentos, filtros y favoritos (`lib/ui/explore_screen.dart`).
- [x] Conexión a la API REST NestJS + Prisma (`lib/data/api_client.dart`, JWT Bearer).
- [x] Registro con verificación de correo (Resend), login, recuperación de contraseña, logout que revoca en el servidor, restauración de sesión (token en `flutter_secure_storage`, espacio `ceosmos_secure_storage`).
- [ ] Passkeys WebAuthn en móvil (requiere `assetlinks.json` en el dominio) → [[08 - Pendientes]].
- [x] Modelos unificados: usuario, sesión, sesión de enfoque, contenido, dispositivo; JSONB `metadata`/`configuration`.

## Segundo parcial — Hardware
- [x] Wearable por TCP/IP (línea JSON `{"hr","steps"}`) con métricas en vivo y resumen en el historial.
- [x] Wearable y TV por **BLE** (central en CEOSMOS; periféricos Reloj/TV), métricas en vivo, comandos y proyección (ver [[06 - BLE Wearable y TV]]).
- [x] Métricas sincronizadas con el historial (`FocusSession.metadata.wearable`, `transport` TCP o BLE).
- [x] Dispositivos vinculados guardados en la cuenta (`/devices`, tipo WEARABLE/TV, transporte TCP/BLE).

## Tercer parcial — Multimedia y rendimiento
- [x] PostgreSQL (Neon) en producción vía API en Vercel.
- [x] Audio en segundo plano (probado en el S24).
- [x] Carga diferida de imágenes y caché LRU en disco de 150 MB (JPEG/WebP ≤ 2 MB).
- [x] Profiling y pruebas de estrés (ver [[Práctica 12 - Optimización, estrés y resiliencia]]).
- [x] E2E de autenticación, feeds y wearable (`integration_test/critical_flow_test.dart`).
- [ ] Servicio en primer plano con notificación para audio muy largo → [[08 - Pendientes]].

## Roles
- [x] USER/ADMIN: panel de administración solo para ADMIN (cliente) y `RolesGuard` (servidor).
- [ ] Cuenta ADMIN en Neon → [[08 - Pendientes]].

## Prácticas con BD propia
- [x] Cada práctica usa su almacenamiento: SQLite `p03_04_usuarios.db`, SharedPreferences `examen1.*`, `p09_local`, `p10_local`, apps Firebase con nombre (`practica7`, `bd_flutter`, `bd_nativo`, `p09`, `p10`), API propia de MediConnect y almacén seguro separado. CEOSMOS no crea la app Firebase `[DEFAULT]`.

---
Navegación: [[00 - Índice CEOSMOS]] · [[01 - Visión general]] · [[04 - Módulos de la app]] · [[06 - BLE Wearable y TV]] · [[08 - Pendientes]]
