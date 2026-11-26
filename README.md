# CEOSMOS · Móvil Integral

App Flutter de CEOSMOS (concentración, relajación e inspiración) conectada a la
API real de CEOSMOS (NestJS + Prisma + PostgreSQL), con wearable por TCP/IP y
funciones derivadas de las prácticas del curso (Soporte, Mensajería entre equipos,
Seguridad de la cuenta, Directorio, Citas), cada una con su propia base de datos.

## Requisitos

- Flutter 3.41.9 / Dart 3.11.5, Android SDK (API 34), Java 17, Node 22.
- API de CEOSMOS: `WEBANGULAR/ceosmos-api` (rama `movil-integral`).
- Base de datos: PostgreSQL (Neon en producción o la base local de desarrollo).

## Ejecutar en el emulador

```powershell
# 1. Emulador
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_6 -memory 3072

# 2. Backend (PostgreSQL local 5433 + API 8081 + MediConnect 3443 + adb reverse)
powershell -ExecutionPolicy Bypass -File scripts\dev_backend.ps1

# 3. App (la API se toma de http://10.0.2.2:8081/api)
flutter pub get
flutter run -d emulator-5554
```

Otra API: `flutter run --dart-define=CEOSMOS_API_URL=https://mi-api/api`.

Para probar el wearable sin hardware: `node scripts/banda_tcp_prueba.js 5050` y
vincular `10.0.2.2:5050` en la pestaña **Equipos** (es una herramienta de prueba
del protocolo, no parte de la app).

## Funciones

- Registro con verificación de correo, inicio/cierre de sesión con JWT (token en
  almacenamiento seguro), recuperación de contraseña y restauración de sesión.
- Feeds incluidos (3 audios propios, 3 paisajes) con búsqueda, filtros y favoritos
  guardados en la cuenta.
- Sesiones de enfoque (5–60 min) con pausa, historial persistido y reintento sin red.
- Biblioteca personal (imágenes/YouTube) con caché LRU de 150 MB.
- Wearable por TCP/IP: métricas en vivo y resumen guardado en cada sesión.
- Perfil: nombre, preferencias, sesiones activas, caché, eliminar cuenta.
- Administración para cuentas ADMIN: usuarios, estado, rol y bitácora.
- **Soporte**: tickets y chat interno por rol, incidencias sin conexión y reportes e
  incidencias compartidos (Flutter y nativo). **Equipos**: mensajería entre equipos.
  **Perfil › Cuenta y herramientas**: seguridad de la cuenta, directorio de alumnos y
  citas de bienestar. Mapa completo en `memoria/12 - Mapa de funciones.md`; el botón ⓘ
  se apaga con `mostrarReferenciasAcademicas` en `lib/core/referencias_academicas.dart`.

## Verificar

```powershell
flutter analyze
flutter test
flutter test integration_test/critical_flow_test.dart -d emulator-5554 `
  --dart-define=E2E_EMAIL=<correo> --dart-define=E2E_PASSWORD=<contraseña>
```

## PWA (aplicación web instalable)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\construir_pwa.ps1 -Servir          # API de producción
powershell -ExecutionPolicy Bypass -File scripts\construir_pwa.ps1 -Local -Servir   # API local (8081)
```

- Abre `http://localhost:4200` en Chrome o Edge y pulsa **Instalar**. El puerto 4200 ya está
  admitido por la lista CORS de la API y `localhost` es contexto seguro (service worker y Web Bluetooth).
  En el teléfono: `adb reverse tcp:4200 tcp:4200` y la misma dirección en Chrome.
- `web/sw.js` es el service worker propio (el de Flutter 3.41 se desregistra solo): precarga el app shell
  (lista y versión las escribe `scripts/pwa_precache.py`), red primero para navegar y **nunca** guarda la API.
- Modo sin conexión (app y PWA): perfil y sesiones pendientes en el equipo (`lib/data/cache_sin_conexion.dart`);
  al volver la red se envían solas, sin duplicar.
- Matriz de la rúbrica y guion de demostración: `evidencias/rubrica/`.

## Reloj y TV por Bluetooth LE

- Apps compañeras en `companion/` (Kotlin + Compose): `cd companion && ./gradlew assembleRelojDebug assembleTvDebug`
  e instalar `app/build/outputs/apk/{reloj,tv}/debug/*.apk` en la tablet. Cada una muestra su PIN.
- En CEOSMOS: pestaña **Equipos › Reloj y TV por Bluetooth › Conectar** y escribir el PIN (solo la primera vez).
- UUID y protocolo: `lib/core/ble/ble_protocolo.dart` y `companion/app/src/main/java/com/ceosmos/companion/ble/Protocolo.kt`.

## Memoria y evidencias

Memoria del proyecto (Obsidian): `memoria/00 - Índice CEOSMOS.md`. Evidencias de la revisión
del 18/11/2026 en `evidencias/`; capturas anteriores en `capturas/`.
