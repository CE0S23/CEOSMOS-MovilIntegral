# Memoria del proyecto · CEOSMOS Móvil Integral

**Actualizada:** 11 de noviembre de 2026
**Proyecto:** aplicación móvil Flutter para CEOSMOS, en español.

## Estado actual

La app ya no es una demo local. Se conecta a la API real de CEOSMOS (NestJS 11 +
Prisma 5, `WEBANGULAR/ceosmos-api`, rama `movil-integral`) con JWT Bearer. Los
datos del usuario (favoritos, preferencias, historial de sesiones de enfoque,
dispositivos vinculados y biblioteca multimedia) se guardan en PostgreSQL.

- Acceso: registro + verificación de correo, login, recuperación de contraseña,
  logout que revoca en el servidor, restauración de sesión (token en
  `flutter_secure_storage`, espacio `ceosmos_secure_storage`). Sin modo demo.
- Wearable por TCP/IP (protocolo: una línea JSON `{"hr":..,"steps":..}` por
  lectura); el resumen de métricas se guarda en `FocusSession.metadata` (JSONB).
- Biblioteca `/api/media` con caché LRU en disco de 150 MB (JPEG/WebP ≤ 2 MB).
- Panel de administración para cuentas ADMIN.
- Ventana **Prácticas** con 10 prácticas integradas, cada una con su propia BD
  (Firebase con app con nombre, SQLite, SharedPreferences o API propia).

## Hecho (11/11/2026)

### App y prácticas
- Fases 0–5 completas: plan, integración de las 10 prácticas, aislamiento de BD
  y sesiones, análisis de faltantes, implementación contra el backend real y
  pruebas. Commits por fase en `main` (último: `4d68d88`). **Sin push.**
- Cada práctica probada con lectura y escritura en su propia base (P7 solo
  hasta el login: faltan contraseñas, ver pendientes).
- `flutter analyze` limpio; `flutter test` 56/56; E2E
  (`integration_test/critical_flow_test.dart`) aprobado en el emulador.

### Backend y servicios
- Rama `movil-integral` de la API (commit `6285ca1`, **sin push**): módulos
  `/focus-sessions`, `/favorites`, `/devices`; migración aditiva
  `20261111170000_movil_integral`; CSRF solo para autenticación por cookie;
  límite general 120/min (auth 10/min).
- **Neon:** migración aplicada (autorizada). Solo agrega tablas; no modifica las
  existentes. Como el puerto 5432 está bloqueado en esta red, se aplica por
  WebSocket con `node prisma/migrate-ws.js --apply`.
- **Resend:** nueva API key solo de envío ("CEOSMOS-MOVIL-INTEGRAL") en el `.env`
  del API (no versionado); remitente `CEOSMOS <noreply@ceosmos.online>` (dominio
  verificado).
- Base PostgreSQL 16 local de desarrollo en `.devdb` (puerto 5433), levantada
  con `scripts/dev_backend.ps1`. Cuentas de prueba en `.devdb/CUENTAS_DEV.txt`
  (fuera de git).

### Teléfono físico (Samsung S24, Android 16) contra Neon
- APK arm64 con `--dart-define=CEOSMOS_API_URL=http://localhost:8080/api` y
  `adb reverse` de los puertos 8080, 3443 y 5050.
- Registro → correo entregado → verificación → login con
  `delivered@resend.dev` (cuenta de prueba en Neon).
- Favorito, dispositivo, wearable TCP y sesión de enfoque guardados en Neon.
- Audio en segundo plano confirmado; P6 por Wi-Fi real en ambos sentidos; P9
  muestra entre dispositivos lo escrito desde el emulador.
- Capturas en `capturas/celular_*.png`. Detalle en `REPORTE_FINAL.md`.

### Comportamientos que conviene recordar
- El backend permite **una sesión por usuario**: cada login cierra las demás.
  Si se entra con la misma cuenta en otro dispositivo (o con curl), la app
  vuelve a la pantalla de acceso. Es correcto, no es un fallo.
- Los backends en `localhost` se ven desde el emulador como `10.0.2.2`; en el
  teléfono se usa `adb reverse`. MediConnect (Evaluación 2) siempre usa
  `adb reverse` porque su certificado solo vale para `localhost`.
- El aviso de FlutterSecureStorage "Falling back to custom ciphers" es normal.

## Pendiente

| # | Pendiente | Quién | Qué hacer |
|---|-----------|-------|-----------|
| 1 | **Railway** (tokens vencidos, requiere pago de 5 USD) | Usuario → luego Claude | Pagar; desplegar la rama `movil-integral` de la API con las mismas variables del `.env` (DATABASE_URL/DIRECT_URL de Neon, JWT, RESEND_*); compilar la app con `--dart-define=CEOSMOS_API_URL=https://<railway>/api` y repetir el E2E. |
| 2 | **Cuenta ADMIN en Neon** (el sistema de permisos bloqueó crearla en producción) | Usuario | `SEED_ROLE=ADMIN SEED_EMAIL=... SEED_PASSWORD=... SEED_USERNAME=... node prisma/seed-movil.js` con el `.env` de Neon, o cambiar el rol desde la web. El panel ADMIN ya se probó en la base local. |
| 3 | **Contraseñas de prueba de la Práctica 7** (admin/agente/usuario1/usuario2.p7@example.com) | Usuario → luego Claude | Con ellas se prueba el flujo completo de P7 (tickets, roles). |
| 4 | **Push** de `main` (MovilIntegral) y de `movil-integral` (WEBANGULAR) | Usuario decide | No se hace push sin autorización explícita. |
| 5 | Passkeys WebAuthn en móvil | Usuario | Publicar `/.well-known/assetlinks.json` en el dominio del RP con el SHA-256 del certificado de la app. |
| 6 | CEOSMOS TV | Usuario | No hay código en el proyecto; hace falta el repositorio. |
| 7 | BLE y wearable físico | — | Sin hardware; hoy solo existe el protocolo TCP (probado con `scripts/banda_tcp_prueba.js`). |
| 8 | Servicio en primer plano para audio largo | Claude (opcional) | El audio sigue en segundo plano, pero Android puede cortarlo en sesiones largas sin una notificación de primer plano. |
| 9 | Pruebas de caja blanca (cobertura) y de estrés | Claude (opcional) | Ver la sección siguiente. |

## Pruebas de caja blanca y estrés (posibles, aún no hechas)

- **Caja blanca:** `flutter test --coverage` genera `coverage/lcov.info`. Las
  pruebas ya usan un servidor falso (`test/support/fake_ceosmos_api.dart`) que
  permite forzar cada rama de `AppState`, `ApiClient` y la caché. En el backend
  se pueden usar Jest con `--coverage`.
- **Estrés de la API:** usar autocannon o k6 contra la API **local** con la base
  de `.devdb`, nunca contra Neon ni Resend (cuotas y datos reales). Antes hay que
  subir el *throttle* (120/min, auth 10/min) solo en ese entorno y crear varias
  cuentas, porque cada login cierra la sesión anterior.
- **Estrés de la app:** `adb shell monkey -p com.ceosmos.ceosmos_movil_integral
  -v 5000` y perfilado con `flutter run --profile` / DevTools.
