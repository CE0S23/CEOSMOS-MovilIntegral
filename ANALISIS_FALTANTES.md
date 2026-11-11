# Análisis de faltantes · CEOSMOS Móvil Integral

Fecha: 11 de noviembre de 2026. Compara lo que piden `memoria.md`, el *Reporte de avances* (3 parciales), `docs/ARQUITECTURA.md` y `docs/PRIMERA_REVISION.md` contra el código de `lib/` antes de la Fase 4 (commit `7417fdf`).

## 1. Requisitos contra implementación

| Requisito | Estado | Archivo(s) | Qué falta |
| --- | --- | --- | --- |
| Proyecto Flutter unificado (Android/iOS/Web/Windows) | Completo | `lib/`, `android/`, `ios/`, `web/`, `windows/` | — |
| Feeds de concentración/relajación/inspiración, búsqueda y filtros | Completo (contenido incluido en la app) | `lib/data/catalog.dart`, `lib/ui/explore_screen.dart` | El texto lo presenta como «Colección de demostración» |
| Conexión con la API REST NestJS + Prisma | **Falta** | — | No existe cliente HTTP; ninguna pantalla consulta la API |
| Conexión con PostgreSQL (Neon) | **Falta** | — | Se logra a través de la API |
| Registro email/contraseña | **Es demo** | `lib/data/auth_repository.dart` (`MemoryAuthRepository`) | Cuentas en RAM; no usa `POST /api/auth/register` |
| Verificación de correo | **Falta** | — | `POST /api/auth/verify-email` y reenvío |
| Inicio de sesión con JWT y políticas del servidor (bloqueo, cuenta inactiva) | **Es demo** | `auth_repository.dart`, `auth_screen.dart` | Login local; no hay token ni mensajes del servidor |
| Botón «Explorar demo» (acepta entrar sin cuenta) | **Es demo** | `auth_screen.dart:163`, `auth_repository.dart:81` | Debe eliminarse |
| Recuperación de contraseña | **Falta** | — | `forgot-password` / `reset-password` |
| Cierre de sesión en el servidor | **Parcial** | `app_state.dart:signOut` | No revoca la sesión (`POST /api/auth/logout`) |
| Persistencia de sesión al reiniciar | **Falta** | — | Token en almacenamiento seguro y restauración con `GET /api/users/me` |
| Caducidad de sesión | **Es demo** | `auth_repository.dart` (2 h locales) | Debe venir del servidor (401 → salir) |
| Passkeys WebAuthn | **Es placeholder** | `auth_screen.dart:194-208` | Requiere Credential Manager, `assetlinks.json` en el dominio RP y RP_ID móvil |
| Modelos unificados (usuario, sesión, sesión de enfoque, contenido, dispositivo) | Parcial | `lib/domain/models.dart` | `AppUser` sin rol; `FocusSession`/`LinkedDevice` marcados `local-demo`/`simulation`; sin `fromJson` |
| Esquema relacional + JSONB para sesiones de enfoque, favoritos y dispositivos | **Falta** | `ceosmos-api/prisma/schema.prisma` | No existen las tablas en el backend |
| Favoritos por usuario persistidos | **Es demo** | `app_state.dart:toggleFavorite` | En RAM |
| Preferencias (duración) persistidas | **Es demo** | `app_state.dart:setPreferredMinutes` | En RAM; el backend tiene `PATCH /api/users/preferences` (mínimo 15 min, la app usa 5) |
| Historial de sesiones de enfoque | **Es demo** | `app_state.dart:finishSession` | En RAM; ids generados localmente |
| Temporizador (pausa, continuar, fin) | Completo | `app_state.dart` | — |
| Reproductor de audio único | Completo | `lib/core/sound_controller.dart` | — |
| Audio en segundo plano (3er parcial) | **Falta** | `app.dart:didChangeAppLifecycleState` | Se detiene al ocultar la app |
| Perfil: editar nombre, sesiones activas, eliminar cuenta | **Falta** | `lib/ui/profile_screen.dart` | Endpoints existen en la API |
| Biblioteca multimedia del usuario (`MediaItem` YOUTUBE/IMAGE) | **Falta** | — | `GET/POST/DELETE /api/media` |
| Carga diferida de imágenes y caché LRU 150–200 MB (3er parcial) | **Falta** | — | — |
| Vinculación de wearable (TCP/IP primario, BLE respaldo) | **Es demo** | `lib/ui/devices_screen.dart`, `app_state.dart:toggleDevice` | «Simular vinculación», id `demo-…` |
| Métricas de salud en tiempo real | **Es mock** | `devices_screen.dart:165-178` | «72 bpm» y «1,240 pasos» fijos con etiqueta DATOS FICTICIOS |
| Sincronizar métricas con el historial | **Falta** | — | — |
| CEOSMOS TV (vista previa de sesión) | **Es demo** | `devices_screen.dart:141` | «TV simulada»; el código de la PWA TV no está disponible |
| Roles y protección de rutas (USER/ADMIN) | **Falta** | `models.dart` (rol fijo `USER`) | Panel de administración (usuarios, roles, estado, bitácora) solo para ADMIN |
| Estados de carga, vacío y error | Parcial | pantallas | Solo existen para la demo local |
| Pruebas | Parcial | `test/`, `integration_test/` | Las pruebas validan el repositorio en memoria |
| Prácticas de laboratorio dentro de la app | Falta (Fase 1) | — | Ventana «Prácticas» |

## 2. Inventario de demo / mock / placeholder

| Ubicación | Hallazgo | Tipo |
| --- | --- | --- |
| `lib/data/auth_repository.dart:20-84` | `MemoryAuthRepository`, usuario fijo `demo@ceosmos.local` | Login que acepta cualquiera (modo demo) |
| `lib/ui/auth_screen.dart:163-185` | Botón «Explorar demo» y aviso «Demostración local · Sin conexión a servidores» | Demo |
| `lib/ui/auth_screen.dart:194-208` | Tarjeta «Passkeys en la siguiente integración» | Placeholder |
| `lib/core/app_state.dart:11` | Repositorio por defecto en memoria | Mock |
| `lib/core/app_state.dart:116-129` | `toggleDevice` crea `LinkedDevice(id: 'demo-…')` | Simulación |
| `lib/core/app_state.dart:94` | Id de sesión de enfoque generado con el reloj local | Datos locales |
| `lib/domain/models.dart:88,108` | `'source': 'local-demo'`, `'transport': 'simulation'` | Marcadores demo |
| `lib/ui/devices_screen.dart:30-36,112,129,141` | «Simulación de dispositivos», «Demo activa», «Simular vinculación», «TV simulada» | Demo |
| `lib/ui/devices_screen.dart:165-178` | Métricas fijas «72 bpm», «1,240 pasos», «DATOS FICTICIOS» | Datos falsos |
| `lib/ui/explore_screen.dart:174` | «Colección de demostración» | Texto |
| `lib/app.dart:303` | Etiqueta «PRIMER PARCIAL» en la cabecera | Texto de entrega |
| `README.md` | «No hay base de datos, Firebase ni llamadas a servidores» | Documentación demo |

No se encontraron `Lorem ipsum`, `setTimeout`/`Future.delayed` simulando peticiones ni `TODO` en `lib/` de CEOSMOS. `catalog.dart` contiene contenido real incluido en la app (tres MP3 propios y tres paisajes dibujados), no datos de usuario falsos.

## 3. Hallazgos del backend real (`ceosmos-api`)

| Hallazgo | Impacto en la app móvil |
| --- | --- |
| Railway responde `404 Application not found` | La app debe apuntar a la API levantada localmente (`http://10.0.2.2:8080/api` en el emulador) hasta que se vuelva a desplegar |
| CSRF obligatorio en POST/PATCH/DELETE aunque se use `Authorization: Bearer` | Un cliente móvil no tiene cookies de navegador; CSRF solo protege la autenticación por cookie |
| Límite global de 10 peticiones por minuto | Una sola apertura de la app hace ~6 peticiones |
| `flowTimeDefault` con mínimo de 15 | La app ofrece 5 minutos |
| Sin tablas de sesiones de enfoque, favoritos ni dispositivos | Necesarias para persistir los datos del usuario |
| Verificación de correo vía Resend | Si `RESEND_API_KEY` no es válida el registro se crea pero el código no llega |
