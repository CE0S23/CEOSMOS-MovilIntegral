# Reporte final · CEOSMOS Móvil Integral

Fecha: 11 de noviembre de 2026. Pruebas en emulador Android **Pixel 6, API 34, x86_64** y, en la segunda parte, en un **Samsung Galaxy S24 (SM-S721B, Android 16, arm64)** conectado por USB contra la base de producción **Neon**.

## 1. Resumen

| Fase | Resultado |
| --- | --- |
| 0. Reconocimiento | `PLAN_INTEGRACION.md`: stack, requisitos, inventario de 10 prácticas con su BD exacta, conflictos y estrategia |
| 1. Ventana Prácticas | Pestaña «Prácticas» con 10 tarjetas; cada práctica abre dentro de CEOSMOS con barra «← Prácticas» y navegador propio |
| 2. BD de las prácticas | Cada práctica usa su propia BD/servicio; lectura **y** escritura probadas en el emulador (salvo P7, ver §5) |
| 3. Análisis | `ANALISIS_FALTANTES.md`: requisitos vs. código e inventario de demo/mock |
| 4. App real | Acceso, datos, wearable, biblioteca, perfil y administración contra la API real; sin modo demo ni datos ficticios |
| 5. Emulador | APK instalado, todos los flujos recorridos, logcat revisado, capturas en `capturas/`, `flutter analyze` limpio, 56/56 pruebas y E2E aprobado |

## 2. Qué se integró y cómo está aislada cada BD

| Práctica | Cómo corre en CEOSMOS | Base de datos / servicio propio | Aislamiento | Prueba en emulador |
| --- | --- | --- | --- | --- |
| P3-4 ConsultaWeb | Ruta Flutter | SQLite `p03_04_usuarios.db` (Floor) + jsonplaceholder | Archivo SQLite propio | Consulta web ✔ · alta y lectura de usuario ✔ |
| P5 AccesoSeguro | Ruta Flutter + canal Kotlin `acceso_seguro/login` | — (validación en Kotlin) | Canal con su nombre original | Validación y acceso ✔ |
| P6 MobileConnect | Ruta Flutter + canales Kotlin `mobile_connect/*` | — (TCP 5000 en memoria) | Canales propios; se libera al cerrar la actividad | Simulación local: envío/recepción ✔ (Wi-Fi: ver §5) |
| Examen 1 Incidencias | Ruta Flutter | SharedPreferences `flutter.examen1.incidencias` | Clave con prefijo | Guardar y listar ✔ (verificado en el XML del dispositivo) |
| P7 Tickets | Ruta Flutter (`Practica7Entrada`) | Firebase **practica7-8-941cb** | App Firebase con nombre `practica7` | Conexión a su Auth ✔ (credencial rechazada por su servidor); recorrido completo: ver §5 |
| Reportes Firestore (Flutter) | Ruta Flutter + canal `reportes/firestore` | Firebase **reportes-movil-20261019**, colección `reportes` | App `bd_flutter`, sesión anónima propia | Alta REP742 + consulta desde servidor ✔ |
| Reportes Firestore (nativo) | Actividad Android | Firebase **reportes-movil-20261019** | App `bd_nativo` (UID anónimo distinto al de `bd_flutter`) | Alta REP743 + consulta ✔ |
| P9 Incidencias compartidas | Actividad Compose | Firebase **mesaayuda-p7**, `incidencias` | App `p09`, preferencias `p09_local` | Lectura en tiempo real ✔ · alta CEOSMOS_P9_001 confirmada en 370 ms ✔ |
| P10 Incidencias seguras | Actividad Compose | Firebase **mesaayuda-p7**, colecciones `*_p10` | App `p10`, preferencias `p10_local` | Cuenta nueva + alta CEOSMOS_P10_001 confirmada en 261 ms ✔ |
| Eval. 2 MediConnect | Ruta Flutter | API Node HTTPS `localhost:3443` (certificado fijado) | Su propio `dio`; almacén seguro por defecto separado del de CEOSMOS | Login, «Mis citas» y alta APT-2042 ✔ |

Evidencia de aislamiento en el dispositivo (`run-as … ls shared_prefs`): archivos de Firebase Auth por app (`…Store.YmRfZmx1dHRlcg…` = `bd_flutter`, `…YmRfbmF0aXZv…` = `bd_nativo`, `…cDEw…` = `p10`), `p09_local.xml`, `p10_local.xml`, `ceosmos_secure_storage.xml` (token de CEOSMOS) y `FlutterSecureStorage.xml` (MediConnect). Prueba explícita: iniciar y cerrar sesión en MediConnect (hace `deleteAll()`) y reiniciar la app → CEOSMOS sigue con su sesión. CEOSMOS no crea la app Firebase `[DEFAULT]`.

**Por qué MediConnect no usa `10.0.2.2`:** su certificado fijado solo es válido para `localhost`/`127.0.0.1`; con `10.0.2.2` la verificación TLS fallaría. Se mantiene `localhost` y el emulador usa `adb reverse tcp:3443 tcp:3443` (lo hace `scripts/dev_backend.ps1`). Backend: `cd "Practica para implementar en la app/Evaluacion2/mediconnect/backend"; node server.js`.

Adaptaciones de código de cada práctica: `lib/practicas/README.md` (todas marcadas con `[CEOSMOS]`).

## 3. Qué faltaba y qué se implementó

| Requisito (memoria / reporte de avances) | Antes | Ahora |
| --- | --- | --- |
| Conexión con la API NestJS/Prisma y PostgreSQL | Falta | `ApiClient` + repositorios; JWT Bearer |
| Registro, verificación de correo, login, recuperación, logout | Demo en memoria | Real (`/api/auth/*`), mensajes del servidor traducidos, bloqueo por intentos del servidor |
| «Explorar demo» / login que acepta cualquiera | Demo | Eliminado |
| Persistencia de sesión | Falta | Token en almacenamiento seguro; `GET /users/me` al abrir; 401 → salida con aviso |
| Favoritos, preferencias, historial | En RAM | `/favorites`, `/users/preferences`, `/focus-sessions` (nuevos en la API) con actualización optimista y cola de reintento |
| Esquema relacional + JSONB | Diseñado | `FocusSession`, `Favorite`, `LinkedDevice` (JSONB `metadata`/`configuration`) + CHECK |
| Wearable TCP/IP y métricas en tiempo real | Simulado, «72 bpm» fijos | Cliente TCP real; métricas en vivo; resumen guardado en el historial |
| Biblioteca multimedia, carga diferida, caché LRU 150–200 MB | Falta | `/api/media` + caché en disco LRU 150 MB, JPEG/WebP ≤ 2 MB, lista perezosa |
| Audio en segundo plano | Se detenía al ocultar la app | Ya no se detiene al pasar a segundo plano (ver §5) |
| Perfil (nombre, sesiones activas, eliminar cuenta) | Falta | Implementado |
| Roles y protección de rutas | Rol fijo USER | Sección Administración solo para ADMIN (cliente) + `RolesGuard` (servidor) |
| Estados de carga/vacío/error | Parcial | En acceso, historial, sesiones, biblioteca, dispositivos y administración |

Cambios en el backend (repo `WEBANGULAR`, rama `movil-integral`, commit `6285ca1`, sin push): módulos nuevos, migración aditiva `20261111170000_movil_integral`, CSRF solo para auth por cookie (los clientes Bearer no son atacables por CSRF), límite general 120/min (auth sigue en 10/min), preferencia mínima de 5 min, `PrismaService` que usa Neon solo con URLs `*.neon.tech`, `prisma/seed-movil.js` (cuenta verificada por variables de entorno) y `prisma/migrate-ws.js` (aplica migraciones por WebSocket cuando el puerto 5432 está bloqueado, como en esta red).

## 4. Pruebas

### Segunda parte: producción (Neon) + Resend + teléfono físico

- **Neon:** migración `20261111170000_movil_integral` aplicada con autorización (vía `prisma/migrate-ws.js --apply`); el API corre contra Neon (`Prisma connected to Neon PostgreSQL`).
- **Resend:** nueva API key «CEOSMOS-MOVIL-INTEGRAL» (solo envío) escrita en el `.env` del API sin mostrarse; remitente `CEOSMOS <noreply@ceosmos.online>` (dominio verificado en Resend).
- **Registro real desde el S24:** cuenta creada → correo de verificación **enviado y entregado** (Resend: Sent → Delivered) → código ingresado → «Correo verificado» → login contra Neon.
- **Datos en Neon desde el teléfono** (comprobados por la API): favorito `orbit`, dispositivo «CEOSMOS Band» con `lastSeenAt`, sesión de enfoque de 130 s con resumen del wearable en JSONB (129 lecturas, 72.1 bpm promedio).
- **Audio en segundo plano (teléfono real):** con la app detenida y el lanzador en primer plano, el reproductor siguió reiniciando su bucle (`Received media started` a las 13:51:20) → sigue sonando en segundo plano.
- **P6 MobileConnect por Wi-Fi real:** sala creada en el S24 (`192.168.100.74:5000`), la PC (`192.168.100.11`) se conectó como B con el protocolo de la práctica: el teléfono recibió «Hola desde la PC por Wi-Fi» y la PC recibió `A	13:53	Respuesta desde el S24` (más los `PING` del protocolo).
- **P9 entre dispositivos:** el S24 muestra `CEOSMOS_P9_001`, la incidencia escrita desde el emulador (base compartida `mesaayuda-p7`).
- **Política de una sesión:** el backend borra las sesiones anteriores en cada login; al iniciar sesión con la misma cuenta desde otro cliente, la app del teléfono recibió 401 y volvió correctamente a la pantalla de acceso.
- Compilación para el teléfono: `flutter build apk --debug --target-platform android-arm64 --dart-define=CEOSMOS_API_URL=http://localhost:8080/api` + `adb reverse tcp:8080 tcp:8080` (y `3443` para MediConnect, `5050` para la banda de prueba).

### Primera parte: emulador

- `flutter analyze`: **No issues found**.
- `flutter test`: **56/56** (unidad, widgets, suite de caja negra de Práctica 8 adaptada, prácticas P3-4/P6/Examen 1/BD). Las pruebas usan un doble HTTP del contrato de la API (`test/support/fake_ceosmos_api.dart`); incluyen una conexión TCP real con un `ServerSocket` local y la caché LRU en disco.
- E2E en el emulador contra la API real (`integration_test/critical_flow_test.dart`): **aprobado**.
- Recorrido manual en el emulador, verificado además con consultas a PostgreSQL: login erróneo/correcto, favorito, biblioteca (alta, error de miniatura, borrado), vincular y conectar wearable (`lastSeenAt`), sesión con métricas guardadas en JSONB, preferencia, restauración tras cerrar la app, logout (sesiones del servidor = 0), registro, código incorrecto, panel ADMIN (desactivar/activar usuario, bitácora).
- Errores encontrados y corregidos durante las pruebas: P7 sin app `[DEFAULT]` (delegado de Firestore), controladores de diálogos liberados antes de cerrar, bloqueo de la caché (`whenComplete` esperándose a sí mismo), recorte LRU concurrente que borraba de más, aviso de sesión vencida consumido por la pantalla saliente y etiqueta de pestaña partida.
- logcat: sin `FATAL`/excepciones de la app. Quedan registros `E FlutterSecureStorage … Falling back to custom ciphers` del sondeo interno de migración del plugin (se maneja solo; ambas sesiones siguen funcionando) y avisos del sistema (`DeadObjectException` de WindowManager al cerrar la app).

## 5. Pendiente y qué se necesita

| Pendiente | Motivo | Qué necesito de ti |
| --- | --- | --- |
| API en Railway | Responde `404 Application not found` | Volver a desplegar la rama `movil-integral` y compilar con `--dart-define=CEOSMOS_API_URL=https://…/api` |
| Cuenta ADMIN en Neon | Crear un ADMIN directamente en producción con el seed fue bloqueado por la política de permisos; el panel ADMIN se probó en la base local | Ejecuta tú `SEED_ROLE=ADMIN … node prisma/seed-movil.js` con el `.env` de Neon, o cambia el rol de tu cuenta desde la web |
| P7: recorrido con sesión | Las contraseñas de `admin/agente/usuario1/usuario2.p7@example.com` «se entregan por separado» y no están en el proyecto | Las contraseñas de prueba (o permiso para crear cuentas nuevas en `practica7-8-941cb`) |
| Passkeys WebAuthn en móvil | Requiere `assetlinks.json` publicado en el dominio RP (`ceosmos-t8ee.vercel.app`) y Credential Manager | Acceso al dominio para publicar `assetlinks.json` con la huella SHA-256 de firma |
| CEOSMOS TV | El código de la PWA TV no está disponible (solo un prototipo Figma) | El repositorio de la app TV |
| Wearable físico y BLE | Sin hardware; el cliente TCP se probó con `scripts/banda_tcp_prueba.js` (herramienta de prueba del protocolo) | La banda o el simulador del cuatrimestre anterior |
| Notificación de audio en segundo plano | Comprobado que sigue sonando en el S24; falta un servicio en primer plano con notificación para que Android no lo detenga en sesiones muy largas | — |
| APK de 3-4, 5, 6 y Examen 1 originales | Se compilaron solo para ARM64 y no corren en el emulador x86_64; se verificaron con sus pruebas y dentro de CEOSMOS | — |
| Pruebas originales de P6 | 11 de 21 ya fallaban en el proyecto entregado (desincronizadas con su código) | — |

Cuenta de prueba creada en **Neon** desde el teléfono: `delivered@resend.dev` (dirección de prueba oficial de Resend, USER); su contraseña está en `.devdb/CUENTAS_DEV.txt`. Cuentas de la **base local de desarrollo** (no existen en producción): `usuario@ceosmos.test` / `Ceosmos#Dev2026` (USER) y `admin@ceosmos.test` / `Admin#Ceosmos2026` (ADMIN). También en `.devdb/CUENTAS_DEV.txt` (ignorado por git).

## 6. Cómo correr el proyecto y el emulador

```powershell
# Emulador
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_6 -memory 3072

# Backend: PostgreSQL local (5433) + API CEOSMOS (8080) + MediConnect (3443) + adb reverse
powershell -ExecutionPolicy Bypass -File scripts\dev_backend.ps1
#   con Neon en lugar de la base local (tras aplicar la migración): ... -Neon

# Cuenta inicial en la base que uses (credenciales por variables de entorno)
cd "C:\Users\cesar\OneDrive\Escritorio\8°\DesarrolloWEB\WEBANGULAR\ceosmos-api"
$env:SEED_EMAIL='tu@correo'; $env:SEED_PASSWORD='Clave#Segura1'; $env:SEED_USERNAME='tu_usuario'; $env:SEED_ROLE='ADMIN'
node prisma\seed-movil.js

# App
cd C:\CESAR10cuatri\CEOSMOS.MovilIntegral
flutter run -d emulator-5554            # o: flutter build apk --debug
node scripts\banda_tcp_prueba.js 5050   # opcional: banda de prueba en 10.0.2.2:5050
```

Variables: `CEOSMOS_API_URL` (dart-define de la app); en la API, las de `ceosmos-api/.env.example` (`DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `FRONTEND_ORIGIN`, `RP_ID`, `RP_NAME`, `RESEND_API_KEY`, `RESEND_FROM_EMAIL`). La app no contiene secretos de CEOSMOS; las configuraciones de Firebase incluidas son las configuraciones públicas de cliente de cada práctica.

## 7. Capturas (`capturas/`)

CEOSMOS: `ceosmos_01_login.png`, `ceosmos_02_login_error_servidor.png`, `ceosmos_03_inicio.png` (menú principal), `ceosmos_04_explorar.png`, `ceosmos_04_explorar_favorito.png`, `ceosmos_05_biblioteca.png`, `ceosmos_06_dispositivos_wearable_tcp.png`, `ceosmos_07_sesion_en_curso.png`, `ceosmos_07b_mi_sesion.png`, `ceosmos_08_perfil.png`, `ceosmos_09_perfil_historial.png`, `ceosmos_10_admin.png`, `ceosmos_11_admin_usuario_desactivado.png`, `ceosmos_12_registro_validacion.png`, `ceosmos_13_verificacion_correo.png`, `ceosmos_14_codigo_incorrecto.png`.

Teléfono S24 (Neon): `celular_01_correo_verificado.png`, `celular_02_inicio_neon.png`, `celular_03_wearable_tcp.png`, `celular_04_sesion_audio.png`, `celular_05_p06_wifi_tcp.png`, `celular_06_p09.png`, `celular_07_p07.png`.

Prácticas: `ventana_practicas.png`, `practica_p03_04_consulta_web.png`, `practica_p03_04_sqlite_usuarios.png`, `practica_p05_acceso_concedido.png`, `practica_p06_mobileconnect.png`, `practica_examen1_incidencia_guardada.png`, `practica_p07_firebase_auth.png`, `practica_bd_flutter_firestore_lectura_escritura.png`, `practica_bd_nativo_firestore.png`, `practica_p09_incidencia_guardada.png`, `practica_p10_incidencia_propia.png`, `practica_eval2_mediconnect_cita.png`.

## 8. Commits

En este repositorio (rama `main`, sin push): línea base → Fase 0 → Fases 1 y 2 → Fase 3 → Fase 4 → Fase 5. En `WEBANGULAR` (rama `movil-integral`, sin push): `6285ca1`.
