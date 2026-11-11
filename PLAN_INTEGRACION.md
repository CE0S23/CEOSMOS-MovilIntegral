# Plan de integración · CEOSMOS Móvil Integral + Prácticas

Fecha: 11 de noviembre de 2026.

## 1. Stack de CEOSMOS (reconocimiento)

| Elemento | Valor encontrado |
| --- | --- |
| Framework | Flutter 3.41.9 / Dart 3.11.5 (`pubspec.yaml`, SDK `^3.11.5`) |
| Gestor de paquetes | `pub` (`pubspec.yaml` / `pubspec.lock`) |
| Android | AGP 8.11.1, Kotlin 2.2.20, Java 17, paquete `com.ceosmos.ceosmos_movil_integral` |
| Navegación | `MaterialApp` con `home` condicionado a sesión; `AppShell` con 5 pestañas (Inicio, Explorar, Mi sesión, Dispositivos, Perfil) por índice, sin rutas nombradas |
| Estado | `AppState` (`ChangeNotifier`) global |
| Autenticación | `MemoryAuthRepository`: cuentas en RAM, botón «Explorar demo» |
| Backend real de CEOSMOS | API **NestJS 11 + Prisma 5** (`C:\Users\cesar\OneDrive\Escritorio\8°\DesarrolloWEB\WEBANGULAR\ceosmos-api`), BD **PostgreSQL en Neon**. El despliegue de Railway (`ceosmosv2-production.up.railway.app`) responde `404 Application not found`: el servicio en la nube está caído. El API sí arranca localmente y se conecta a Neon con su propio `.env`. |
| Base de datos de la app móvil | Ninguna (todo en memoria) |

Fuentes de requisitos leídas: `memoria.md`, `README.md`, `docs/ARQUITECTURA.md`, `docs/PRIMERA_REVISION.md`, `docs/VALIDACION.md`, `docs/PRACTICA_8_BLACK_BOX_TESTING.md`, `Reporte de avances - CEOSMOS revicion.docx` (formato de avances: 3 parciales), `C:\CESAR10cuatri\CEOSMOS_web\memoria.md` y el código de `ceosmos-api`.

### Requisitos extraídos (memoria + reporte de avances)

1. Proyecto Flutter unificado; UI de feeds visuales/auditivos (concentración, relajación, inspiración).
2. Conexión con la API REST existente (NestJS + Prisma) y con PostgreSQL/Neon.
3. Autenticación email/contraseña (registro, verificación de correo, login, logout, recuperación) con JWT y políticas de sesión del servidor; passkeys WebAuthn.
4. Modelos unificados: usuario, sesión de acceso, sesión de enfoque, contenido (MediaItem), dispositivo vinculado; JSONB para configuraciones.
5. Favoritos, preferencias, historial de sesiones y dispositivos persistidos en una API común.
6. Sesiones de enfoque cronometradas (pausa/continuar/fin), reproductor de audio único.
7. Wearable por TCP/IP (primario) y BLE (respaldo); métricas en tiempo real sincronizadas con el historial.
8. Tercer parcial: audio en segundo plano, carga diferida de imágenes, caché local LRU 150–200 MB (WebP/JPEG ≤ 2 MB, MP3/AAC ≤ 10 MB), profiling y pruebas E2E.
9. Roles `USER`/`ADMIN` del backend (panel administrativo, bitácora).

## 2. Inventario de prácticas (`Practica para implementar en la app/`)

| ID integración | Carpeta | Qué hace | Stack | Pantallas | Base de datos / servicio (config exacta) |
| --- | --- | --- | --- | --- | --- |
| `p03_04` | `practica_3_4` (paquete `consultaweb`) | Consulta web de un usuario y registro local de usuarios (CRUD) | Flutter, `http`, `floor` + `sqflite` | Consulta, Usuarios (barra inferior) | **SQLite local** `usuarios.db`, tabla `Usuario` (Floor). API pública `https://jsonplaceholder.typicode.com/users/2` |
| `p05` | `practicas5y6/Practica_5_AccesoSeguro` | Login con validaciones en Kotlin vía `MethodChannel` `acceso_seguro/login` | Flutter + Kotlin | Formulario de acceso / sesión | Ninguna (credencial de práctica `alumno` / `ClaveDemo2026` en Kotlin, documentada como simulada en su README) |
| `p06` | `practicas5y6/Practica_6_MobileConnect` | Chat TCP por Wi-Fi entre dos teléfonos (puerto 5000), simulación local | Flutter + Kotlin (`mobile_connect/network`, `mobile_connect/events`) | Preparación (crear/unirse), conversación | Ninguna (TCP en memoria) |
| `examen1` | `AppExamen1/incidencias_app` | Registro local de incidencias de soporte | Flutter + `shared_preferences` | Formulario + lista | **SharedPreferences**, clave `incidencias` (JSON) |
| `p07` | `practica7` | Sistema de tickets/reportes, chat con adjuntos, roles (admin, agente, usuario1/2) | Flutter + FlutterFire (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`), `provider`, `file_picker`, `connectivity_plus`, `shared_preferences` | Rol/acceso, Home, Reportes, Formulario, Chat, Dispositivos | **Firebase `practica7-8-941cb`**: appId Android `1:987714720406:android:75b0c3c03a8e934490a8b7`, apiKey `AIzaSyDWfa1S8kAuN471DJnrRhxCpRTZObOi0B4`, sender `987714720406`, bucket `practica7-8-941cb.firebasestorage.app`. Auth correo/contraseña (cuentas `admin.p7@example.com`, `agente.p7@…`, `usuario1.p7@…`, `usuario2.p7@…`); Firestore `(default)` us-central1, colecciones `usuarios`, `reportes`, `mensajes`, `dispositivos` |
| `bd_flutter` | `reportes_flutter` (paquete `reportesfirestore`) | CRUD de reportes en Firestore; UI Flutter, lógica Firebase en Kotlin vía `MethodChannel` `reportes/firestore` | Flutter + Kotlin + Firebase Android SDK | Una pantalla CRUD | **Firebase `reportes-movil-20261019`**: appId `1:460782495529:android:115ef39759a64280a57938`, apiKey `AIzaSyBGYBtb51g45VS2jSRdkRVSnkpIMnP-2oo`, sender `460782495529`; Auth anónima; colección `reportes` |
| `bd_nativo` | `firestore_reportes_android` | Misma práctica de reportes, versión Android nativa (Views) | Kotlin + Firebase Android SDK (BoM 34.19.0) | Una actividad | **Firebase `reportes-movil-20261019`** (misma config que `bd_flutter`), Auth anónima, colección `reportes` |
| `p09` | `PRACTICA 9 - DMI.zip` | Incidencias compartidas en tiempo real entre dispositivos A/B, conflictos, bitácora, matriz | Kotlin + Jetpack Compose + Firestore | Identificación, Incidencias, Editor, Bitácora, Conexión, Matriz | **Firebase `mesaayuda-p7`**: appId `1:245587407150:android:53e0b5342dbd0a570e4abf`, apiKey `AIzaSyBMMwogDVaw9wNqPSyoXlEiJw2_T1oGYZ4`, sender `245587407150`; colecciones `incidencias`, `matriz_p9`; SharedPreferences `local` |
| `p10` | `PRACTICA 10 - DMI.zip` | Incidencias seguras: Auth por correo, propietario por UID, asignaciones, pruebas de reglas | Kotlin + Compose + Firestore + Firebase Auth | Login/registro, Incidencias, Editor, Pruebas de seguridad | **Firebase `mesaayuda-p7`** (misma config que p09); colecciones `*_p10`; SharedPreferences `local` |
| `eval2` | `Evaluacion2/mediconnect` | Citas médicas: login JWT RS256, mis citas, agendar con Idempotency-Key, pinning TLS, modo laboratorio | Flutter (`dio`, `flutter_secure_storage`, `uuid`, `intl`) + API Node/Express (`backend/server.js`) | Login, Mis citas, Agendar, Detalle, Laboratorio | **API REST propia** `https://localhost:3443/api/v1` (HTTPS con certificado fijado, CN/SAN `localhost`/`127.0.0.1`), datos en memoria del servidor; tokens en `flutter_secure_storage` (`access_token`, `refresh_token`) |

La Práctica 8 (caja negra y red) es del propio CEOSMOS (`docs/PRACTICA_8_BLACK_BOX_TESTING.md`); no es una app separada.

### Verificación de cada práctica tal como se entregó

- Se instalaron en el emulador (Pixel 6, API 34, x86_64) los APK entregados. P7, `bd_nativo`, P9, P10 y MediConnect abren correctamente su pantalla inicial.
- Los APK de 3-4, 5, 6 y Examen 1 se compilaron solo para `arm64-v8a` (teléfono físico); el emulador x86_64 no puede cargar `libflutter.so` (`dlopen failed … EM_AARCH64`). No es un defecto de su lógica. Para ellas se ejecutaron sus pruebas automatizadas originales (`flutter test`) y se verifican funcionando dentro de CEOSMOS en el emulador.
- `reportes_flutter` no tenía APK; se valida con su prueba original y en el emulador integrado.

## 3. Conflictos detectados

| Tipo | Conflicto | Resolución |
| --- | --- | --- |
| Versiones | `intl`: MediConnect pide `^0.20.3`; `flutter_localizations` (usado por CEOSMOS) fija `0.20.2` | Se unifica en `intl: ^0.20.2` (solo se usa `DateFormat`, disponible igual) |
| Versiones | Firebase BoM: P9/P10 `33.7.0`, reportes `34.19.0`, FlutterFire 4.x usa BoM 34.x | Una sola BoM 34.x en el módulo `app`; las APIs usadas (`FirebaseApp`, `FirebaseFirestore`, `FirebaseAuth`, `Source`, `MetadataChanges`) existen en ambas |
| Versiones | Compose (P9/P10) requiere el plugin `org.jetbrains.kotlin.plugin.compose` | Se agrega con la misma versión de Kotlin del host (2.2.20) |
| Nombres | P9 y P10 usan el mismo paquete `com.dmi.incidencias` y clases idénticas (`MainActivity`, `Repositorio`, `Modelo`…) | Paquetes `com.ceosmos.practicas.p09` y `com.ceosmos.practicas.p10` |
| Nombres | `bd_flutter` y `bd_nativo` comparten `com.example.reportesfirestore` (`FirestoreReportes`, `Reporte`, `ReporteValidator`) | Paquetes `com.ceosmos.practicas.bdflutter` y `com.ceosmos.practicas.bdnativo` |
| Nombres | Las prácticas Flutter con código nativo (`p05`, `p06`, `bd_flutter`) tenían su lógica en su propio `MainActivity` | Su código pasa a clases registradoras de canal (`…Channels`) llamadas desde el `MainActivity` de CEOSMOS; nombres de canal originales sin cambios (no colisionan) |
| Almacenamiento | P9 y P10 usan el mismo archivo SharedPreferences `local` | `p09_local` y `p10_local` |
| Almacenamiento | Examen 1 usa la clave genérica `incidencias` en el SharedPreferences común de Flutter | Clave `examen1.incidencias` |
| Almacenamiento | P3-4 usa la BD `usuarios.db` | `p03_04_usuarios.db` |
| Almacenamiento | MediConnect usa `flutter_secure_storage` con `deleteAll()` en el almacén por defecto | CEOSMOS usa su propio almacén (`sharedPreferencesName` distinto), por lo que el `deleteAll()` de MediConnect nunca borra el token de CEOSMOS |
| Firebase | Todas las prácticas Firebase usan la app `[DEFAULT]` (`Firebase.initializeApp()` / `getInstance()` / `google-services.json`) | Cada una se inicializa como app con nombre: `practica7`, `bd_flutter`, `bd_nativo`, `p09`, `p10`, con `FirebaseOptions` en su propio archivo de configuración. CEOSMOS no usa Firebase y no se aplica el plugin `google-services` (no existe `[DEFAULT]`) |
| Red | MediConnect apunta a `https://localhost:3443`; su certificado fijado solo es válido para `localhost`/`127.0.0.1` | Cambiar a `10.0.2.2` rompería la verificación TLS del pinning (nombre no incluido en el certificado). Se mantiene `localhost` y el emulador redirige el puerto con `adb reverse tcp:3443 tcp:3443` (documentado). El backend se levanta desde su carpeta |
| Red | CEOSMOS debe hablar con su API local (`http://10.0.2.2:8080/api`) | `network_security_config` que permite texto claro solo para `10.0.2.2`/`localhost`; la URL es configurable con `--dart-define=CEOSMOS_API_URL` |
| Navegación | Cada práctica Flutter trae su propio `MaterialApp` | Se monta dentro de una ruta de CEOSMOS con su propio `MaterialApp` (Navigator, tema y `MediaQuery` propios) bajo una barra «← Prácticas» |
| Gradle | `gradle.properties` de CEOSMOS reserva `-Xmx8G` en un equipo de 7.8 GB | Se reduce a 4 GB para poder compilar con el emulador abierto |
| Backend | La API de CEOSMOS exige CSRF (cookie + cabecera) también a clientes con `Bearer`, límite global de 10 peticiones/minuto, preferencias con mínimo de 15 minutos | Se ajusta el backend (rama propia): CSRF solo para autenticación por cookie, límite estricto solo en `/auth`, mínimo de 5 minutos; se agregan los módulos faltantes (sesiones de enfoque, favoritos, dispositivos) con migración aditiva |

## 4. Estrategia de integración

1. **Prácticas Flutter** → `lib/practicas/<id>/`, copiando su `lib/` original. Solo se ajustan imports, el punto de entrada (`main()` → widget raíz exportado), la inicialización de Firebase con nombre y los nombres de almacenamiento. Cada adaptación se marca con el comentario `// [CEOSMOS]` y se lista en `lib/practicas/README.md`.
2. **Prácticas Kotlin/Compose** → `android/app/src/main/kotlin/com/ceosmos/practicas/<id>/` como `Activity` declaradas en el `AndroidManifest` de CEOSMOS (sin `LAUNCHER`). CEOSMOS las abre por el canal `ceosmos/practicas`; al abrirse se les agrega la barra «← Prácticas» y el botón Atrás regresa a la lista.
3. **Ventana Prácticas** → nueva entrada del menú principal con tarjetas (número, nombre, descripción, stack y BD).
4. **Bases de datos** → un cliente por práctica: `FirebaseApp` con nombre por práctica (Dart y Kotlin), SQLite con archivo propio, SharedPreferences con prefijo, almacén seguro separado, API de MediConnect con su propio `dio`.
5. **CEOSMOS real** → cliente HTTP propio contra `ceosmos-api` (JWT Bearer en almacenamiento seguro), repositorios de autenticación, perfil, preferencias, favoritos, sesiones de enfoque, dispositivos, biblioteca multimedia y administración.
6. **Pruebas** → emulador Pixel 6 API 34: `flutter build apk --debug`, instalación, recorrido de cada flujo, `adb logcat` y capturas en `capturas/`.
