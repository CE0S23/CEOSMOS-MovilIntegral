# Práctica 11 · Pruebas White Box de CEOSMOS Móvil Integral

**Proyecto:** CEOSMOS Móvil Integral (app Flutter + API NestJS/Prisma + PostgreSQL)
**Fecha de ejecución:** 11 de noviembre de 2026, 18:30 – 19:25 (hora del centro de México)
**Alcance:** aplicación móvil, sitio web/API REST y base de datos, más la comunicación entre ellos.
**Correcciones:** los 8 defectos encontrados se corrigieron y se volvió a medir (11/11/2026, 19:40 – 20:30). Cada uno, con su solución real y su verificación, está en §8. Los resultados previos a la corrección se conservan con el prefijo `antes_` en `evidencias/`.

## 1. Identificación del entorno y de la versión evaluada

| Elemento | Valor |
| --- | --- |
| Código de la app | Repositorio `CEOSMOS.MovilIntegral`, rama `main`, commit base `5df9f6c` + archivos de prueba de esta práctica (`test/whitebox/`, `integration_test/p11_*`, `test_driver/`) + correcciones de §8 (`lib/domain/models.dart`, `lib/core/app_state.dart`, `lib/data/api_client.dart`) |
| Código de la API | Repositorio `WEBANGULAR/ceosmos-api`, rama `movil-integral`, commit base `6285ca1` + 4 archivos `*.spec.ts`, la variable `THROTTLE_LIMIT` en `src/app.module.ts`, las correcciones de §8 y 2 migraciones nuevas |
| Versión de la app | `ceosmos_movil_integral 1.1.0+2` |
| Dispositivo móvil | Samsung Galaxy S24 (SM-S721B), Android 16 (compilación BP4A.251205.006.S721BXXSEDZI1), pantalla a 120 Hz, Wi-Fi `10.13.40.246/18` |
| Equipo servidor/cliente | Laptop Intel Core i3-10110U (2 núcleos / 4 hilos, 2.1 GHz), 7.8 GB RAM, Windows 11 Home 10.0.26100, Wi-Fi `10.13.40.197` (misma red que el teléfono) |
| Herramientas | Flutter 3.41.9 / Dart 3.11.5, Node 22.22.0, NestJS 11, Prisma 5.22, Jest 30, PostgreSQL 16.11, adb, Chrome (puppeteer-core) para los grafos |
| Servidor evaluado | API CEOSMOS local (`node dist/main.js`, puerto 8080) sobre PostgreSQL 16 local (`127.0.0.1:5433`, base `ceosmos_dev`). **No se usaron Neon ni Resend** para las pruebas de escritura y de carga |
| Enlace teléfono → API | USB con `adb reverse tcp:8080 tcp:8080` (ver justificación en §6.1) |
| Enlace teléfono → sitio web | Wi-Fi institucional + Internet hacia `https://ceosmos-t8ee.vercel.app` (frontend Angular de CEOSMOS) |

Todas las salidas originales están en `p11yp12/p11/evidencias/` y todos los scripts en `p11yp12/p11/scripts/`. Las cuentas de prueba (`p11_wb`, `p11_wb2`, `p11_vu01…10`) existen solo en la base local.

## 2. Arquitectura evaluada

```
 Samsung S24 (app Flutter)                 Laptop (equipo servidor)
 ┌──────────────────────────┐   HTTP/JSON   ┌────────────────────────┐  Prisma (TCP)  ┌──────────────────┐
 │ UI → AppState            │──(USB, adb───►│ API NestJS :8080       │───────────────►│ PostgreSQL 16    │
 │   → Ceosmos/AuthRepository│   reverse)    │ JwtAuthGuard → Ctrl →  │                │ ceosmos_dev      │
 │   → ApiClient._send      │◄──────────────│ Service → PrismaClient │◄───────────────│ (.devdb :5433)   │
 │ WearableClient (TCP)     │               └────────────────────────┘                └──────────────────┘
 └──────────────────────────┘── Wi-Fi + Internet ──► Sitio web CEOSMOS (Vercel, HTTPS)
```

Módulos principales identificados (Fase 1, actividad 1):

| Componente | Módulo | Responsabilidad |
| --- | --- | --- |
| App | `lib/core/app_state.dart` | Estado global: sesión, temporizador, cola de sesiones pendientes |
| App | `lib/data/api_client.dart` | **Única función que se conecta al servidor:** `ApiClient._send` (l.42) |
| App | `lib/data/auth_repository.dart`, `ceosmos_repository.dart` | Acceso a los recursos REST (auth, users, favorites, focus-sessions, devices, media, admin) |
| App | `lib/core/wearable*.dart` | Cliente TCP del wearable y validación del protocolo |
| App | `lib/core/media_cache_io.dart` | Caché LRU en disco de imágenes |
| API | `src/*/…controller.ts` / `…service.ts` | Controladores y servicios; acceso a la BD **solo** por `PrismaService` (consultas parametrizadas) |
| BD | `prisma/schema.prisma` + migraciones | Tablas `User`, `Session`, `FocusSession`, `Favorite`, `LinkedDevice`, `MediaItem`, `AuditLog`… |

## 3. Fase 1 · Inspección y análisis estático

### 3.1 Herramientas ejecutadas

| Herramienta | Alcance | Resultado | Evidencia |
| --- | --- | --- | --- |
| `flutter analyze` (reglas del proyecto, `flutter_lints`) | Toda la app | **No issues found** | `fase1_estatico/01_flutter_analyze.txt` |
| `flutter analyze` con reglas estrictas (`strict-casts`, `strict-raw-types`, `discarded_futures`, `unawaited_futures`, `avoid_catches_without_on_clauses`, `close_sinks`, `cancel_subscriptions`, `avoid_dynamic_calls`, `avoid_slow_async_io`…) | Toda la app | **82 avisos** (64 en prácticas integradas, 14 en el núcleo de CEOSMOS, 4 en pruebas) | `02_flutter_analyze_estricto.txt`, `02b_issues.txt`, `scripts/analysis_options_estricto.yaml` |
| `flutter pub outdated` | Dependencias Dart | 60+ paquetes con versión más nueva; ninguno bloqueado | `03_flutter_pub_outdated.txt` |
| `npm outdated` / `npm audit --omit=dev` | API | Antes: **38 vulnerabilidades: 3 críticas, 20 altas**, 12 moderadas, 3 bajas. **Después de P11-D08: 0** | `04_npm_outdated.txt`, `05_npm_audit.txt`, `12_npm_audit_despues.txt` |
| ESLint (configuración del proyecto) | API `src/` | 192 hallazgos: 82 de formato, 56 `no-unsafe-member-access`, 34 `no-unsafe-assignment`, 2 `no-floating-promises`… | `06_eslint_backend_resumen.txt` |
| ESLint `complexity` (umbral 5) | API | Mayor V(G): `csrfMiddleware` 12, `TasksService.updateTask` 12, `AuthService.login` 11, `AdminService.getAuditLogs` 11 | `07_complejidad_backend.txt` |
| `scripts/complejidad_dart.js` (McCabe aproximado) | `lib/core`, `lib/data`, `lib/domain`, `lib/ui` | 195 funciones; 10 con V(G) ≥ 10. Mayor: `AuthScreen.build` 28, **`traducirError` 27**, `AdminScreen.build` 23 | `09_complejidad_dart.txt` |
| Búsqueda de secretos en archivos versionados | App y API | Sin secretos de servidor versionados; solo configuraciones públicas de cliente de Firebase de las prácticas. `.env` y `.devdb/` ignorados por git | `08_secretos.txt` |

Distribución de los 82 avisos estrictos: 26 `discarded_futures`, 24 `avoid_catches_without_on_clauses`, 9 `avoid_dynamic_calls`, 8 `argument_type_not_assignable` (casts implícitos), 5 `unawaited_futures`, 4 `strict_raw_type`, 2 `for_in_of_invalid_type`, 2 `avoid_slow_async_io`, 1 `only_throw_errors`, 1 `close_sinks`.

### 3.2 Puntos de revisión obligatorios

| Punto | Resultado de la revisión | Ubicación |
| --- | --- | --- |
| Métodos sin manejo de excepciones | `ApiClient._send` captura `TimeoutException` y `ClientException` (incluye `SocketException`). En la API, `FavoritesController.add` **no** controlaba (corregido en §8) el error de clave única de Prisma (P2002) → 500 en concurrencia (**P11-D02**, corregido). `SoundController` usa `catch` genérico sin `on` (3 casos) | `api_client.dart:57-70`, `favorites.controller.ts:45`, `sound_controller.dart:33,50,62` |
| Credenciales o claves expuestas | **`JWT_SECRET ?? 'changeme'`** (corregido, P11-D06): si falta la variable en un despliegue, los tokens se firman con un secreto público (**P11-D06**). Las `apiKey` de Firebase son configuración pública de cliente (aceptable si se restringen por paquete/SHA-1) | `auth.module.ts:15`, `jwt.strategy.ts:22`, `firebase_p07.dart:24` |
| Validaciones duplicadas o inexistentes | Duplicadas a propósito (defensa en profundidad): la política de contraseña está en la app y en la API; `targetMinutes`/`durationSeconds` en DTO, servicio y **CHECK** de la BD. Inexistente: tamaño máximo de `metadata` (solo el límite de 100 KB de Express) (**P11-D04**, corregido: 4 KB en la API y red de seguridad en la BD) | `auth_repository.dart:23`, `focus-sessions.dto.ts`, migración `…_movil_integral` |
| Código inaccesible o redundante | Rama `user == null` con `media != null` en `finishSession` es inalcanzable (al cerrar sesión se descarta la sesión activa); se documenta en §4.4. Sin código muerto reportado por el analizador | `app_state.dart:274` |
| Consultas construidas con datos sin validar | Ninguna: antes no había `$queryRaw`/`$executeRaw` en la API; la corrección P11-D07 agregó uno, escrito como plantilla etiquetada de Prisma (el `userId` viaja como parámetro, lo verifica Jest), así que todas las consultas siguen siendo parametrizadas y la Práctica 3-4 usa Floor con parámetros enlazados. Además `contentKey` se valida con `^[A-Za-z0-9:_-]{1,80}$` | `fase4_db/sql_crudo.txt` |
| Operaciones de red bloqueando el hilo principal | No: Dart usa E/S asíncrona y los sockets nativos de la Práctica 6 corren en `Thread {}` propios. Avisos `avoid_slow_async_io` (2) en la caché son E/S de disco asíncrona, no bloqueante | `TcpChatTransport.kt:34,72`, `media_cache_io.dart:56,98` |
| Recursos que no se liberan | `close_sinks` en `wearable_io.dart:46` es un falso positivo: el socket se guarda en `_socket` y se destruye en `_cerrarSocket()`/`dispose()` (verificado por prueba: «El dispositivo cierra la conexión → error y socket liberado»). `discarded_futures` en `app.dart:30` (`_state.restore()` en `initState`) deja la excepción sin observar si falla fuera de `ApiException` | `wearable_io.dart:46,104`, `app.dart:30` |
| Configuración de red | `network_security_config.xml` prohíbe HTTP en claro salvo `10.0.2.2` y `localhost` (desarrollo) | `android/app/src/main/res/xml/` |

## 4. Fase 2 · Pruebas White Box de la aplicación móvil

Se eligieron tres métodos críticos (más dos de apoyo). Las pruebas están en `test/whitebox/` (73 casos con el código corregido) y se ejecutan con:

```
flutter test test/whitebox                                  # 73/73
flutter test --coverage --branch-coverage                   # suite completa 129/129
node p11yp12/p11/scripts/cobertura_lcov.js coverage/lcov.info
```

### 4.1 Método de validación · `WearableLectura.parse` (`lib/core/wearable.dart:16-26`)

Valida cada lectura que envía el wearable por TCP antes de guardarla en las métricas de la sesión.

```dart
final hr = json['hr'];
final steps = json['steps'];
if (hr is! num || hr < 30 || hr > 230) return null;            // C1 C2 C3
if (steps != null && (steps is! num || steps < 0)) return null; // C4 C5 C6
return WearableLectura(heartRate: hr.round(), steps: (steps as num?)?.round(), at: now);
```

![Grafo de flujo de parse](evidencias/grafos/cfg_parse.png)

**Complejidad ciclomática:** aristas 16 − nodos 11 + 2 = **V(G) = 7** (6 condiciones atómicas + 1). **Caminos independientes y casos:**

| Camino | C1 | C2 | C3 | C4 | C5 | C6 | Entrada | Esperado | Obtenido |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CB1 | V | – | – | – | – | – | `{steps:10}` / `{hr:"72"}` | null | null ✔ |
| CB2 | F | V | – | – | – | – | `{hr:29}` | null | null ✔ |
| CB3 | F | F | V | – | – | – | `{hr:231}` | null | null ✔ |
| CB4 | F | F | F | F | – | – | `{hr:72}` | lectura, steps null | ✔ |
| CB5 | F | F | F | V | V | – | `{hr:72, steps:"mil"}` | null | null ✔ |
| CB6 | F | F | F | V | F | V | `{hr:72, steps:-1}` | null | null ✔ |
| CB7 | F | F | F | V | F | F | `{hr:72, steps:1240}` | lectura completa | ✔ |

**Valores límite:** 29 ✗, 30 ✔, 31 ✔, 229 ✔, 230 ✔, 231 ✗; decimales 29.9 ✗, 30.4 ✔ (→30), 229.6 ✔ (→230), 230.4 ✗. Hallazgo menor: la comparación se hace **antes** de redondear, por eso 230.4 se rechaza aunque redondeado sería 230 (comportamiento aceptable, se documenta). `steps`: 0 ✔, −0.5 ✗, 12.7 → 13.

**Excepciones** (en `_alRecibir`, con un `ServerSocket` real): línea que no es JSON (`FormatException` capturada), JSON que no es objeto, línea > 512 caracteres, frecuencia fuera de rango → todas ignoradas, solo se guarda la válida. Puerto cerrado → estado `error` con mensaje. El dispositivo cierra la conexión → estado `error` y socket liberado. Búfer: 3 601 lecturas → se conservan las 3 600 más recientes.

También se probaron los límites de `validarContrasenaNueva` (7 ✗, 8 ✔, 72 ✔, 73 ✗ y la falta de cada clase de carácter por separado), `validarCorreo` y `validarUsuario` (2 ✗, 3 ✔, 30 ✔, 31 ✗).

### 4.2 Método de cálculo · `WearableClient.resumenSesion` (`lib/core/wearable.dart:48-63`)

Calcula promedio (1 decimal), mínimo, máximo y pasos que se guardan en `FocusSession.metadata` (JSONB).

![Grafo de flujo de resumenSesion](evidencias/grafos/cfg_resumen_sesion.png)

**V(G)** = 19 − 15 + 2 = **6** (C1 `m.isEmpty`, C2 `deviceId == null`, C3 `a < b`, C4 `a > b`, C5 `ultima?.steps != null`).

| Camino | Entrada | Esperado | Obtenido |
| --- | --- | --- | --- |
| CB1 (C1=V) | sin muestras | `{}` | ✔ |
| CB2 (C1=F, C2=V) | `[70]`, sin dispositivo | `{}` | ✔ |
| CB3 (C3/C4 solo una iteración, C5=F) | `[72]` | prom 72.0, mín = máx = 72, sin `lastSteps` | ✔ |
| CB4 (C3 y C4 toman V y F, C5=V) | `[80,60,100,61]`, pasos 1500 | prom **75.3** (301/4 = 75.25), mín 60, máx 100, `lastSteps` 1500 | ✔ |
| Límite redondeo | `[60,61,61]` | 60.7 | ✔ |
| Límite del búfer | 3 600 muestras de 90 | 3600 muestras, prom 90.0 | ✔ |

Apoyo: **`traducirError`** (`api_client.dart:94`), el método de **mayor complejidad** del núcleo (V(G) ≈ 27), se probó con 23 casos de tabla, uno por rama (401/403/404/409/429/5xx, mensajes en lista, cuerpo no JSON). También los límites del temporizador (`remaining`/`progress` en 0 s, mitad, exacto y excedido) y las excepciones `StateError`/`ArgumentError`.

### 4.3 Método de comunicación · `ApiClient._send` (`lib/data/api_client.dart:42-79`)

![Grafo de flujo de _send](evidencias/grafos/cfg_send.png)

**V(G)** = 24 − 17 + 2 = **9** (D1 `token != null`, D2 `body != null`, 2 salidas de excepción, C3a `status ≥ 200`, C3b `status < 300`, C4a `status == 401`, C4b `token != null`). El script automático da 8 porque no reconoce `on http.ClientException`; el valor correcto es el manual.

| Camino | Decisiones | Caso de prueba | Resultado |
| --- | --- | --- | --- |
| P1 | D1=F, D2=F, 2xx | GET sin token → JSON; sin cabecera `Authorization` | ✔ |
| P2 | D1=V, D2=V, 2xx | POST con token y cuerpo → `Bearer`, `Content-Type`, JSON enviado | ✔ |
| P3 | Timeout | servidor tarda 300 ms con límite de 50 ms → «tardó demasiado» | ✔ |
| P4 | ClientException | **puerto cerrado real** (SocketException) → «No hay conexión», `statusCode` null | ✔ |
| P5 | C3a=F, C4a=F | status 199 → excepción | ✔ |
| P6 | C3a=V, C3b=F, C4a=F | 300 y 500 → excepción; el 500 no filtra el detalle de Prisma | ✔ |
| P7 | C4a=V, C4b=V | 401 con token → `onUnauthorized()` 1 vez | ✔ |
| P8 | C4a=V, C4b=F | 401 sin token (login fallido) → **no** cierra sesión | ✔ |
| P9 | D1=V, D2=F | GET con token (P7) | ✔ |
| Extra | 204 / texto | 204 sin cuerpo → null; cuerpo no JSON → texto (FormatException controlada) | ✔ |

Apoyo: **`AppState.finishSession`** (`app_state.dart:272-305`), que decide si la sesión se guarda o queda pendiente:

![Grafo de flujo de finishSession](evidencias/grafos/cfg_finish_session.png)

Casos: sin red → pendiente, no se muestra como guardada, se reenvía **una sola vez** al volver; sin sesión activa → no envía nada; 401 durante el guardado → no se encola y vuelve al acceso; **respuesta perdida** (el servidor guardó pero el cliente recibió `Connection reset`) → antes **la sesión se duplicaba al reintentar** (defecto **P11-D01**: 2 registros idénticos); con la corrección, la prueba `P11-D01 CORREGIDO` comprueba 1 solo registro.

### 4.4 Cobertura obtenida

Valores con el código corregido (suite completa **129/129**; antes 128/128, ver `antes_cobertura_resumen.txt`). Herramienta: `flutter test --coverage --branch-coverage` (registros `DA` = líneas ejecutables e `BRDA` = bloques de rama del VM de Dart). Salida completa: `evidencias/fase2_app/cobertura_resumen.txt` y `lcov.info`.

**Por método crítico**

| Tipo | Método | Instrucciones | Ramas |
| --- | --- | --- | --- |
| Validación | `WearableLectura.parse` | 8/8 = **100 %** | 3/3 = **100 %** |
| Validación | `WearableClientImpl._alRecibir` | 10/10 = 100 % | 7/7 = 100 % |
| Validación | `AuthRepository.validarContrasenaNueva` | 4/4 = 100 % | 3/3 = 100 % |
| Cálculo | `WearableClient.resumenSesion` | 13/13 = **100 %** | 6/6 = **100 %** |
| Cálculo | `traducirError` | 23/23 = 100 % | 17/17 = 100 % |
| Comunicación | `ApiClient._send` | 18/18 = **100 %** | 8/8 = **100 %** |
| Comunicación | `AppState.finishSession` | 27/27 = 100 % | 6/6 = 100 % |

**Cobertura de condiciones:** las tablas de §4.1–4.3 muestran que cada condición atómica (C1…C6 de `parse`, C1…C5 de `resumenSesion`, D1/D2/C3a/C3b/C4a/C4b de `_send`) tomó los valores **V y F** al menos una vez → 100 % de cobertura de condiciones en los tres métodos. En `finishSession`, la condición `user == null` (con sesión activa) no toma V porque es **inalcanzable** (`_cerrarLocal` descarta la sesión al salir) y `i >= 0` = F solo ocurre si el usuario cierra sesión mientras la petición está en vuelo; se justifican en lugar de forzarlas.

**Por archivo del núcleo**

| Archivo | Instrucciones | Ramas |
| --- | --- | --- |
| `lib/core/wearable.dart` | 23/23 = 100 % | 11/11 = 100 % |
| `lib/data/api_client.dart` | 56/58 = 96.6 % | 38/39 = 97.4 % |
| `lib/core/wearable_io.dart` | 69/72 = 95.8 % | 25/27 = 92.6 % |
| `lib/data/auth_repository.dart` | 46/55 = 83.6 % | 25/32 = 78.1 % |
| `lib/core/media_cache_io.dart` | 49/59 = 83.1 % | 22/30 = 73.3 % |
| `lib/core/app_state.dart` | 168/217 = 77.4 % | 54/75 = 72.0 % |
| `lib/data/ceosmos_repository.dart` | 29/54 = 53.7 % | 15/27 = 55.6 % |
| **Total núcleo** (`lib/core`, `lib/data`, `lib/domain`) | **534/679 = 78.6 %** | **225/297 = 75.8 %** |
| Total `lib/` (incluye UI y las 10 prácticas) | 1891/4565 = 41.4 % | 597/1779 = 33.6 % |

Los módulos críticos superan el objetivo (≥ 85 % instrucciones, ≥ 80 % ramas). El total del núcleo queda en 78.6 % / 75.8 % porque incluye código que **no conviene** cubrir con pruebas unitarias artificiales: `config.dart` (depende de la plataforma), `token_store.dart` (plugin de almacenamiento seguro, se prueba en el dispositivo), los métodos de administración de `ceosmos_repository.dart` (probados por HTTP en la Fase 3 y en el E2E) y `copyWith`/`fromJson` de modelos sin uso en las rutas críticas.

### 4.5 WB-06 · Rendimiento de la interfaz en el S24

`integration_test/p11_ui_perf_test.dart`, ejecutado con `flutter drive --profile` en el teléfono con datos reales de la API (50 sesiones en el historial). Recorre Explorar → Mi sesión → Equipos → Perfil → Inicio con desplazamientos rápidos y registra el `FrameTiming` de cada cuadro. Salida: `evidencias/fase2_app/ui_perf_s24.json`.

| Métrica (752 cuadros, 23.8 s) | Construcción (hilo UI) | Rasterizado (hilo GPU) |
| --- | --- | --- |
| Promedio | 1.81 ms | 3.57 ms |
| Percentil 50 | 0.42 ms | 3.09 ms |
| Percentil 90 | 5.59 ms | 5.84 ms |
| Percentil 99 | 11.12 ms | 11.29 ms |
| Máximo | 87.5 ms (primer cuadro de una pestaña) | 26.4 ms |
| Cuadros > 8.33 ms (presupuesto a 120 Hz) | 34 (4.5 %) | 18 (2.4 %) |
| Cuadros > 16.7 ms (presupuesto a 60 Hz) | 4 (0.5 %) | 5 (0.7 %) |

Carga inicial (login + 4 lecturas en paralelo: favoritos, historial, dispositivos, biblioteca): **984 ms**. Limitación: `watchPerformance` de `integration_test` no pudo conectarse al VM Service desde el teléfono (`Bad state: Failed to connect to VM Service`, ver `ui_perf_intento1_watchPerformance_fallo.txt`); la alternativa usada (`SchedulerBinding.addTimingsCallback`) entrega los mismos tiempos de construcción y rasterizado medidos por el motor.

## 5. Fase 3 · White Box del sitio web y los servicios (API)

### 5.1 Pruebas unitarias del backend (Jest)

Archivos nuevos: `src/focus-sessions/focus-sessions.service.spec.ts`, `src/devices/devices.controller.spec.ts` (incluye `FavoritesController`) `src/media/media.service.spec.ts` y, con las correcciones, `src/common/filters/http-exception.filter.spec.ts` (filtro, guard y secreto JWT). Resultado: antes **46/46**; con el código corregido **64/64**, incluida la suite original `app.controller.spec.ts` (`evidencias/fase3_web/jest_backend.txt`, `antes_jest_backend.txt`).

![Grafo de FocusSessionsService.create](evidencias/grafos/cfg_backend_create.png)

| Archivo | Instrucciones | Ramas | Funciones |
| --- | --- | --- | --- |
| `focus-sessions.service.ts` | 100 % | 91.7 % | 100 % |
| `devices.controller.ts` | 100 % | 89.3 % | 100 % |
| `favorites.controller.ts` | 100 % | 90.0 % | 100 % |
| `media.service.ts` | 100 % | 93.8 % | 100 % |
| `http-exception.filter.ts` (nuevo comportamiento) | 95.2 % | 82.6 % | 100 % |
| `jwt-secret.ts` (nuevo) | 100 % | 85.7 % | 100 % |

Las ramas que faltan no son lógica de la aplicación: Istanbul cuenta las ramas que TypeScript genera para los metadatos de los decoradores (`typeof X === "function" ? X : Object`) en constructores y parámetros. Los controladores delgados (`focus-sessions.controller.ts`, `media.controller.ts`) se cubren con las pruebas HTTP de §5.2.

Casos clave: `create` con `endedAt < startedAt`, futuro > 5 min, duración > objetivo (400) y sus **límites exactos** aceptados (`endedAt == startedAt`, `ahora + 5 min`, `duration == target·60`); DTO con `contentKey` de 81 caracteres o con `' OR 1=1--` (rechazados), `targetMinutes` 4/5/180/181, `limit` 0/1/100/101; dirección de dispositivo `host:5`, `host:123456`, MAC incompleta, `host:80; DROP TABLE` (rechazadas); `P2002 → 409`, otro error de Prisma se propaga; actualización de dispositivo ajeno → 404 (no revela existencia).

### 5.2 Pruebas HTTP contra la API en ejecución

Script `scripts/fase3_http.js` (34 casos, todos con medición de tiempo y tamaño). Cada caso verifica: código HTTP, estructura JSON, formato de error uniforme `{statusCode, message, error}`, ausencia de trazas internas y ausencia de campos sensibles (`password`, `passwordHash`, `token`, `code`…). **Resultado: antes 33/34; después de las correcciones 40/40** (34 casos originales + H35–H40 de las correcciones; `fase3_web/http_resultados.json`, `antes_http_resultados.json`).

| Código | Situación probada | Endpoint | Obtenido |
| --- | --- | --- | --- |
| 200 | Consulta exitosa | `GET /users/me`, `GET /focus-sessions?limit=5`, `PATCH /devices/:id` | 200 ✔ |
| 201 | Registro creado | `POST /devices`, `POST /focus-sessions`, `POST /media` | 201 ✔ |
| 204 | Eliminación sin cuerpo | `DELETE /devices/:id` (0 bytes) | 204 ✔ |
| 400 | JSON mal formado / falta campo / campo no permitido (`userId`, asignación masiva) / UUID inválido / `limit=101` | varios | 400 ✔ |
| 401 | Sin token, token alterado, token revocado tras logout, contraseña incorrecta | `GET /users/me`, `POST /auth/login` | 401 ✔ |
| 403 | Usuario autenticado sin rol ADMIN | `GET /admin/users` | 403 ✔ (sin token → 401: no confunde autenticación con autorización) |
| 404 | Dispositivo/medio inexistente, eliminar dos veces, ADMIN sobre usuario inexistente | `PATCH/DELETE /devices/:id`, `DELETE /media/:id` | 404 ✔ |
| 409 | Dispositivo con la misma dirección (UNIQUE) | `POST /devices` | 409 ✔ |
| 409 | Video de YouTube ya guardado | `POST /media` | Antes **400 ✘**; después **409 ✔** (P11-D05) |
| 422 | Validación semántica (`endedAt < startedAt`, duración > objetivo) | `POST /focus-sessions` | 400 (la API no usa 422; se acepta pero se documenta) |
| 413 | Cuerpo de 300 KB | `POST /focus-sessions` | Antes 413 sin el campo `error`; después 413 con formato uniforme ✔ |
| 429 | 12 intentos de login en < 1 min | `POST /auth/login` | 429 ✔ |
| 500 | Error inesperado | `PUT /favorites/:key` concurrente | Antes **500** reproducido (P11-D02); después ya no ocurre; el filtro responde 500 genérico solo ante errores no previstos (Jest) |

**Información sensible:** ninguna respuesta incluye `passwordHash`; `/users/me/sessions` devuelve solo `id`, `createdAt`, `ipAddress`; el login devuelve el JWT (necesario para clientes Bearer) y además la cookie `Authentication` con `HttpOnly; Secure; SameSite=None`. Cabeceras: sin `X-Powered-By`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, HSTS de 2 años. Antes, los 401 de JWT devolvían el mensaje interno de la librería (`jwt malformed`); ahora responden `Unauthorized` (H39).

## 6. Fase 4 · White Box de la base de datos

Base PostgreSQL 16.11 local. Scripts: `scripts/fase4_crud.sql`, `fase4_explain.sql`, `fase4_concurrencia.js`. Todos los datos de prueba se eliminan al final de cada script.

### 6.1 Operaciones (FocusSession, Favorite, LinkedDevice)

| # | Operación | Resultado | Tiempo |
| --- | --- | --- | --- |
| 1 | Inserción válida de `FocusSession` con `metadata` JSONB | `INSERT 0 1`, devuelve `avgHeartRate` 71.3 | 11.3 ms |
| 2 | `contentKey` NULL | **NOT NULL** rechaza | 0.6 ms |
| 2 | `durationSeconds 3601` con `targetMinutes 60` | **CHECK** `FocusSession_valores_check` rechaza | 0.6 ms |
| 2 | `endedAt < startedAt` | **CHECK** rechaza | 0.6 ms |
| 2 | `mode = 'SLEEP'` | **ENUM** rechaza | 2.8 ms |
| 2 | `userId` inexistente | **FOREIGN KEY** rechaza | 2.7 ms |
| 2 | Favorito repetido | **UNIQUE** (`userId`,`contentKey`) rechaza | 0.7 ms |
| 2 | `contentKey` de 81 caracteres | **CHECK** de longitud rechaza | 2.0 ms |
| 2 | Dispositivo con la misma dirección | **UNIQUE** (`userId`,`type`,`address`) rechaza | 0.7 ms |
| – | Transacción: 1.ª inserción válida + 2.ª que viola UNIQUE + `COMMIT` | PostgreSQL convierte el COMMIT en **ROLLBACK**: 0 filas de la transacción | – |
| 3 | Consulta por id existente | 1 fila | 2.1 ms |
| 4 | Consulta por id inexistente | 0 filas | 0.25 ms |
| 5 | `UPDATE … lastSeenAt` filtrando por `userId` (como `PATCH /devices`) | `UPDATE 1`; con otro `userId`: `UPDATE 0` | 3.2 ms |
| 6 | `DELETE` del dispositivo | `DELETE 1` | 0.4 ms |
| 7 | Consulta después de borrar | 0 filas (persistencia verificada) | 0.4 ms |

Evidencia: `evidencias/fase4_db/crud_salida.txt`.

### 6.2 Plan de ejecución y tiempos (EXPLAIN ANALYZE)

| Consulta (pantalla de la app) | Datos actuales | Con volumen (100 000 filas) | Con índice propuesto |
| --- | --- | --- | --- |
| Q1 `FocusSession` por usuario, `ORDER BY startedAt DESC LIMIT 50` (historial) | Bitmap Index Scan, **0.088 ms** | Bitmap Index Scan `FocusSession_userId_startedAt_idx`, **0.257 ms** | – |
| Q2 `MediaItem` por usuario (biblioteca) | **Seq Scan**, 0.039 ms | **Seq Scan, 11.8 ms** | Bitmap Index Scan, **0.211 ms** (56× menos) |
| Q2b `count(*)` de `MediaItem` del usuario (antes de cada alta) | – | Seq Scan, 15.1 ms | – |
| Q3 `Session` por `token` (en **cada** petición autenticada) | Index Scan UNIQUE, 0.026 ms | Index Scan, 0.025 ms (20 000 sesiones) | – |
| Q4 `Session` por `userId` (login y `/users/me/sessions`) | Seq Scan, 0.034 ms | **Seq Scan, 2.33 ms** | Bitmap Index Scan, 0.073 ms |
| Q5 `Favorite` por usuario | Bitmap Index Scan del UNIQUE, 0.066 ms | – | – |

El volumen se generó dentro de una transacción con `ROLLBACK` (verificado: 0 filas sintéticas al final). Evidencia: `fase4_db/antes_explain_salida.txt` (antes) y `fase4_db/explain_despues.txt` (después). Todas las consultas sencillas quedan muy por debajo del objetivo de 200 ms; el riesgo estaba en el crecimiento de `MediaItem` y `Session` sin índice por `userId` (**P11-D03**). Con los índices reales de la migración: Q2 **0.146 ms**, Q2b **0.115 ms**, Q4 **0.069 ms** (`fase4_db/explain_despues.txt`).

### 6.3 Transacciones y operaciones parcialmente completadas

La API usa `$transaction` en `AuthService` (verificación de correo y restablecimiento de contraseña) y en la paginación de la bitácora. Las escrituras de la app móvil (`focus-sessions`, `favorites`, `devices`) son de una sola fila, por lo que no pueden quedar a medias. `MediaService.addMedia` hacía **leer-y-después-escribir** (`count`, `findFirst`, `create`) sin transacción ni índice único. En 4 corridas de 10 altas simultáneas **no se reprodujo** (1 fila, 9 respuestas 400), pero era un riesgo (**P11-D07**). Se corrigió con una transacción y un bloqueo por usuario (`pg_advisory_xact_lock`); después, 1 fila y 9 respuestas 409 (§8).

### 6.4 Consistencia servidor ↔ app

El historial que muestra la app es el que devuelve `GET /focus-sessions`; tras una sesión creada sin red, la app la muestra marcada `synced=false` y la reemplaza por la del servidor al sincronizar (comprobado en el S24, §7.5). El único riesgo de inconsistencia encontrado, la respuesta perdida (P11-D01), quedó corregido con `clientId`.

### 6.5 Inyección SQL y seguridad en la nube

Antes de las correcciones no había SQL crudo en la API; ahora solo existe el bloqueo de P11-D07, también parametrizado. Prisma parametriza todas las consultas y los DTO con `whitelist + forbidNonWhitelisted` rechazan campos extra. Neon (producción) se conecta con `sslmode=require` y el usuario de conexión está solo en `.env` (no versionado). La base local acepta `trust` solo en `127.0.0.1`. Neon **no** se usó para estas pruebas.

### 6.6 DB-06 · Concurrencia

**a) Dos sesiones SQL sobre la misma fila** (`fase4_db/concurrencia_sql.txt`): la sesión A hace `UPDATE` y mantiene la transacción 3 s; la B (0.7 s después) **espera 2.23 s** el bloqueo de fila y luego escribe; valor final «Escrito por B» (última escritura gana, sin corrupción). Con `lock_timeout = 1s`, B se cancela a los 1.02 s con `canceling statement due to lock timeout` y el valor de A se conserva.

**b) Diez peticiones simultáneas a la API** (`fase4_db/antes_concurrencia_api.json` y `concurrencia_api_despues.txt`):

| Escenario | Códigos | Filas en BD | Evaluación |
| --- | --- | --- | --- |
| C1 `POST /media` misma URL ×10 | Antes 201×1, 400×9; después 201×1, **409×9** | 1 | Correcto; ahora con bloqueo por usuario (P11-D07) |
| C2 `PUT /favorites/:key` mismo favorito ×10 (después de corregir) | **200×10** en 4 de 4 corridas | 1 | Corregido (`concurrencia_api_despues.txt`) |
| C2 (antes) | **200×7, 500×3** (repetido 4 veces: 3, 2, 1 y 1 errores 500) | 1 | **Defecto P11-D02**: la integridad se mantiene por el índice UNIQUE, pero la API responde 500 (`PrismaClientKnownRequestError` P2002 en `favorite.upsert`, `fase4_db/error_500_upsert_favorito.txt`) |
| C3 `POST /devices` misma dirección ×10 | 201×1, 409×9 | 1 | Correcto (P2002 → 409) |
| C4 `PATCH /devices/:id` ×10 | 200×10 | 1 (valor final «Nombre-9») | Correcto (última escritura gana) |

## 7. Fase 5 · Conectividad y rendimiento

### 7.1 Condiciones y limitaciones

- **HTTP teléfono → API por USB:** el perfil «Público» del firewall de Windows bloquea conexiones entrantes a `node.exe` en esta red institucional y la configuración de red de la app solo permite HTTP en claro hacia `localhost`/`10.0.2.2`. No se modificó el firewall de una red pública. Por eso la API se alcanza con `adb reverse` (USB): las latencias HTTP de la API **no** incluyen el Wi-Fi.
- **Red real del teléfono:** el ping y la descarga del sitio web de CEOSMOS (Vercel) sí usan el Wi-Fi y la salida a Internet.
- **Neon bloquea ICMP** (100 % de pérdida en ping): se documenta la limitación; para servidores externos se usa la medición HTTP del sitio web.

### 7.2 A · Ping (ICMP, 20 paquetes desde el S24, intervalo 0.5 s)

| Destino | Mín (ms) | Prom (ms) | Máx (ms) | Desv. (mdev, ms) | Pérdida |
| --- | --- | --- | --- | --- | --- |
| Laptop servidor `10.13.40.197` (Wi-Fi local) | 23.2 | **54.9** | 125.0 | 26.8 | **0 %** |
| `8.8.8.8` (Internet) | 16.8 | 35.1 | 97.6 | 18.0 | 0 % |
| `ceosmos-t8ee.vercel.app` (sitio web) | 76.2 | 87.3 | 97.8 | 6.2 | 0 % |
| Neon (`*.neon.tech`) | – | – | – | – | 100 % (ICMP bloqueado) |

Evidencia: `fase5_red/ping_s24.txt`. La alta variación hacia la laptop (mdev 26.8 ms) es propia del Wi-Fi institucional compartido (ahorro de energía y retransmisiones), no del servidor.

### 7.3 B / D · Latencia HTTP: 10 solicitudes consecutivas desde el S24

Endpoint real `GET /api/focus-sessions?limit=50` (historial), mismo token y mismos datos. Corrida 2 (oficial) — `fase5_red/s24_red_salida.txt`:

| Solicitud | Código HTTP | Tiempo (ms) | Tamaño (bytes) |
| --- | --- | --- | --- |
| 1 | 200 | 38.6 | 151 588 |
| 2 | 200 | 36.9 | 151 588 |
| 3 | 200 | 34.3 | 151 588 |
| 4 | 200 | 32.1 | 151 588 |
| 5 | 200 | 32.0 | 151 588 |
| 6 | 200 | 41.2 | 151 588 |
| 7 | 200 | 40.4 | 151 588 |
| 8 | 200 | 50.7 | 151 588 |
| 9 | 200 | 79.2 | 151 588 |
| 10 | 200 | 43.8 | 151 588 |

**Promedio 42.9 ms**, mínimo 32.0, máximo 79.2, desviación estándar 14.0 ms, 10/10 exitosas (100 %), tamaño 148 KB.

**Después de las correcciones** (`s24_red_despues.txt`, 20:22): con 50 sesiones que llevan los metadatos reales de la app (~230 B cada una, P11-D04), la misma petición devuelve **28 851 B** en **18.9 ms** de promedio (mín. 14.5, máx. 34.3, desv. 5.5), 10/10 con 200.

Repetición con las mismas condiciones pero con historial sin metadatos grandes (corrida 1, `s24_red_corrida1.txt`): **22.9 ms** promedio (18.0–31.1, desv. 4.1) con respuestas de **64 KB**. El mismo endpoint casi duplicó su latencia al pasar de 64 KB a 148 KB: el tamaño del JSON es el factor dominante (ver P11-D04).

### 7.4 C · Tasa de transferencia (3 mediciones cada una)

Tasa (Mbps) = bytes × 8 / tiempo (s) / 1 000 000.

| Medición | Recurso | Bytes | Tiempo (s) | Tasa (Mbps) |
| --- | --- | --- | --- | --- |
| Descarga 1 | Sitio web CEOSMOS `main.e5355dbf8f1d3c6d.js` (Wi-Fi + Internet) | 637 412 | 0.555 | 9.19 |
| Descarga 2 | ídem | 637 412 | 0.545 | 9.36 |
| Descarga 3 | ídem | 637 412 | 0.573 | 8.91 |
| **Promedio descarga Wi-Fi** | | | **0.558** | **9.15** |
| Descarga 1–3 | API `GET /focus-sessions?limit=100` (USB) | 218 088 | 0.083 / 0.077 / 0.160 | 21.1 / 22.5 / 10.9 (prom. **18.2**) |
| Subida 1 | API `POST /focus-sessions` con 100 KB de metadatos (USB) | 100 226 | 0.390 | 2.06 |
| Subida 2 | ídem | 100 226 | 0.425 | 1.89 |
| Subida 3 | ídem | 100 226 | 0.281 | 2.85 |
| **Promedio subida** | | | **0.365** | **2.27** |

**Después de P11-D04** la API ya no acepta cuerpos de 100 KB: desde el S24, 90 KB → **400** y el cuerpo máximo válido (3.9 KB) → 201 en 28–81 ms. Con cuerpos tan pequeños, la «tasa» (0.86 Mbps) mide la latencia, no el ancho de banda; por eso la medición de 2.27 Mbps se conserva como la de subida. La «subida» es efectiva de extremo a extremo: incluye que la API valide y guarde 100 KB de JSONB; por eso es menor que la descarga por el mismo cable USB. La corrida 1 dio 10.45 Mbps de descarga por Wi-Fi (repetibilidad ±12 %).

### 7.5 E · Prueba de interrupción (en el S24)

`integration_test/p11_red_test.dart` + `scripts/fase5_orquestar.sh`: con una sesión de enfoque en curso, el equipo quita el enlace (`adb reverse --remove`, 19:01:48.295), la app termina la sesión sin red, el enlace vuelve a las 19:01:54.730.

| Criterio | Resultado observado |
| --- | --- |
| Detecta el error | Sí: en **20.5 ms** (corrida 1: 35.8 ms) con «No hay conexión con el servidor de CEOSMOS. Revisa tu red.» |
| No muestra la operación fallida como exitosa | Sí: la sesión aparece con `synced=false` y el aviso «La sesión se guardará cuando vuelva la conexión» |
| Conserva los datos | Sí: un segundo intento sin red mantiene 1 pendiente |
| Reintenta de forma controlada | Sí: al recargar datos con red (7.9 s después del corte) se envió la cola y quedó 0 pendientes |
| Evita duplicados al recuperar la conexión | Sí: **0 duplicados** en las 3 corridas en el S24. Antes fallaba en el escenario de respuesta perdida (P11-D01); con el `clientId` también queda cubierto (prueba unitaria y 10 reintentos simultáneos contra la API real) |

### 7.6 NET-07 · Carga controlada (API local, laptop como cliente)

`scripts/fase5_carga.js`: 10 cuentas distintas (la API permite una sesión por usuario), 50 sesiones precargadas por cuenta (respuesta de 24.4 KB), 100 solicitudes por usuario, calentamiento previo descartado. Límite general de la API subido con `THROTTLE_LIMIT=6000` **solo** en este entorno (el de `/auth` sigue en 10/min). Evidencia: `fase5_carga/carga_resultados.json`.

| Escenario | Usuarios | Solicitudes | Exitosas | Fallidas | Prom. (ms) | P95 (ms) | Máx. (ms) | Solicitudes/s | Tasa (Mbps) | CPU API* | RAM API | Transacciones PG |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Lectura `GET /focus-sessions?limit=50` | 1 | 100 | 100 | 0 | 11.7 | 14.5 | 24.7 | 85.5 | 16.7 ↓ | 107 % | 93 MB | 290 |
| Lectura | 5 | 500 | 500 | 0 | 33.3 | 50.1 | 76.3 | 149.8 | 29.3 ↓ | 169 % | 97 MB | 1 429 |
| Lectura | 10 | 1 000 | 1 000 | 0 | 63.8 | 86.6 | 120.0 | 156.5 | 30.6 ↓ | 169 % | 99 MB | 2 822 |
| Escritura `POST /focus-sessions` | 1 | 100 | 100 | 0 | 8.7 | 10.9 | 12.3 | 113.9 | 0.19 ↑ | 89 % | 99 MB | 99 (100 filas) |
| Escritura | 5 | 500 | 500 | 0 | 25.4 | 38.8 | 57.8 | 196.3 | 0.32 ↑ | 168 % | 115 MB | 1 638 (500 filas) |
| Escritura | 10 | 1 000 | 1 000 | 0 | 49.5 | 69.9 | 82.9 | 201.3 | 0.33 ↑ | 155 % | 155 MB | 2 876 (1 000 filas) |

\* Porcentaje de un hilo lógico (400 % = los 4 hilos del i3). Total: 3 200 solicitudes medidas, **0 fallidas**, todas las escrituras persistidas (filas contadas en la BD) y limpiadas al final (2 100 filas borradas).

**Antes vs. después de las correcciones** (misma prueba; ahora cada escritura lleva `clientId`):

| Escenario | Usuarios | Prom. antes → después (ms) | P95 antes → después (ms) | Solicitudes/s antes → después | Fallidas |
| --- | --- | --- | --- | --- | --- |
| Lectura | 1 | 11.7 → 12.0 | 14.5 → 13.8 | 85.5 → 83.5 | 0 → 0 |
| Lectura | 5 | 33.3 → 36.9 | 50.1 → 54.9 | 149.8 → 132.3 | 0 → 0 |
| Lectura | 10 | 63.8 → 66.5 | 86.6 → 87.5 | 156.5 → 150.2 | 0 → 0 |
| Escritura | 1 | 8.7 → 10.5 | 10.9 → 12.3 | 113.9 → 94.0 | 0 → 0 |
| Escritura | 5 | 25.4 → 28.7 | 38.8 → 40.3 | 196.3 → 173.2 | 0 → 0 |
| Escritura | 10 | 49.5 → 56.2 | 69.9 → 75.1 | 201.3 → 177.5 | 0 → 0 |

Las escrituras son ~12 % más lentas por la búsqueda del `clientId` (costo aceptado a cambio de no duplicar; se podría reducir a una sola consulta con `INSERT … ON CONFLICT`). Las lecturas no cambiaron de código: sus diferencias (−4 % a −12 % de solicitudes/s) son variación entre corridas en la misma laptop. Evidencia: `fase5_carga/carga_resultados.json` y `antes_carga_resultados.json`.

**Interpretación:** de 5 a 10 usuarios el rendimiento ya no sube (150 → 156 lecturas/s) y la latencia se duplica (33 → 64 ms): el sistema está saturado. La CPU del proceso de la API se estabiliza en ~170 % (el hilo de JavaScript de Node al 100 % más los hilos de Prisma), mientras que cada consulta tarda < 0.3 ms en PostgreSQL. Cada petición autenticada genera ≈ 2.8 transacciones (sesión por token + usuario + consulta), lo que se ve en la columna de transacciones.

## 8. Fase 6 · Defectos, solución real y verificación

Cada defecto se documentó al encontrarlo y luego **se corrigió en el código**. Las pruebas de las fases 2 a 5 se repitieron con el código corregido: los resultados «antes» se guardaron con el prefijo `antes_` en `evidencias/` y los de «después» con el nombre normal o con el sufijo `_despues`. Durante la verificación apareció un defecto nuevo, causado por una de las correcciones (P11-D09); también está documentado y corregido.

| ID | Componente | Severidad | Estado | Verificación después de corregir |
| --- | --- | --- | --- | --- |
| P11-D01 | App + API + BD (sesiones de enfoque) | **Alta** | **Corregido** | 10 reintentos simultáneos con el mismo `clientId` → 1 fila; S24: 0 duplicados |
| P11-D02 | API (`PUT /favorites`) | **Alta** | **Corregido** | 4 corridas × 10 simultáneas: 40/40 respuestas 200, 0 errores 500 |
| P11-D06 | API (secreto JWT) | **Alta** | **Corregido** | Sin `JWT_SECRET` la API no arranca (código de salida 1) |
| P11-D08 | API (dependencias) | **Alta** | **Corregido** | `npm audit --omit=dev`: 38 → **0** vulnerabilidades |
| P11-D03 | BD (`MediaItem`, `Session`) | Media | **Corregido** | 11.8 → 0.146 ms y 2.33 → 0.069 ms con 100 000 / 20 000 filas |
| P11-D04 | API + BD (`metadata` del historial) | Media | **Corregido** | 100 KB → 400; historial de 50 sesiones: 148 KB → 28 KB |
| P11-D05 | API (códigos y formato de error) | Baja | **Corregido** | Batería HTTP 33/34 → **40/40** |
| P11-D07 | API (`addMedia`) | Baja | **Corregido** (preventivo) | 4 corridas × 10 simultáneas: 1 fila y 9 × 409 |
| P11-D09 | BD (CHECK de la corrección D04) | Media | **Corregido** | Detectado en el S24 (500); tras corregirlo, 201 en el S24 y caso H40 |

Archivos modificados — API (`ceosmos-api`, rama `movil-integral`): `prisma/schema.prisma`, migraciones `20261112090000_p11_correcciones` y `20261112093000_p11_metadata_check`, `src/auth/jwt-secret.ts` (nuevo), `src/auth/auth.module.ts`, `src/auth/jwt.strategy.ts`, `src/auth/jwt-auth.guard.ts`, `src/common/filters/http-exception.filter.ts`, `src/focus-sessions/dto/focus-sessions.dto.ts`, `src/focus-sessions/focus-sessions.service.ts`, `src/favorites/favorites.controller.ts`, `src/media/media.service.ts`, `src/media/media.controller.ts`, `package.json`. App: `lib/domain/models.dart`, `lib/core/app_state.dart`, `lib/data/api_client.dart` y el doble de la API `test/support/fake_ceosmos_api.dart`. Las migraciones se aplicaron **solo en la base local**; ver §8.10. El cambio exacto de cada archivo está en `evidencias/correcciones/app_correcciones.diff` y `evidencias/correcciones/api_correcciones.diff`.

### P11-D01 · El reintento duplicaba una sesión de enfoque cuando se perdía la respuesta

- **Componente:** `lib/core/app_state.dart` (`finishSession`, `_enviarPendientes`) y API `src/focus-sessions/focus-sessions.service.ts` (`create`).
- **Pasos para reproducirlo:** 1) iniciar y terminar una sesión; 2) el servidor guarda la fila, pero la conexión se corta antes de que llegue la respuesta (`Connection reset by peer`); 3) volver a cargar datos con red.
- **Resultado esperado:** una sola sesión en el servidor.
- **Resultado observado (antes):** dos filas idénticas con el mismo `startedAt`. La app no podía distinguir «no llegó» de «llegó, pero no volvió la respuesta».
- **Evidencia (antes):** prueba `DEFECTO P11-D01` en `test/whitebox/wb_comunicacion_test.dart`, salida `fase2_app/antes_wb_salida.txt`.
- **Solución aplicada:**
  - BD: columna `FocusSession.clientId` e índice `UNIQUE ("userId", "clientId")` (migración `20261112090000_p11_correcciones`).
  - App: `FocusSession` tiene un campo `clientId`; `finishSession` lo genera **una sola vez** con `const Uuid().v4()` antes del primer envío, y la cola de pendientes reenvía el mismo objeto, así que el reintento lleva el mismo `clientId` (`lib/core/app_state.dart:293`, `lib/domain/models.dart:178-189`).
  - API: el DTO acepta `clientId` (UUID v4). `create` busca primero `(userId, clientId)` y, si existe, devuelve esa fila. Si dos reintentos llegan a la vez, el índice UNIQUE rechaza al segundo (`P2002`) y el servicio devuelve la fila ganadora en lugar de fallar (`focus-sessions.service.ts:38-67`). Los clientes que no envían `clientId` funcionan como antes.
- **Verificación (después):**
  - Prueba unitaria `P11-D01 CORREGIDO`: con la respuesta perdida, el servidor tiene **1** fila y la app queda con 0 pendientes y la sesión sincronizada.
  - Jest: reintento con el mismo `clientId` → no se llama a `create`; carrera con `P2002` → devuelve la ganadora.
  - API real: casos H35/H36 → mismo `id` en los dos envíos (`fase3_web/http_resultados.json`); 10 envíos **simultáneos** con el mismo `clientId` → 10 × 201, **1 id y 1 fila** (`fase4_db/d01_reintentos_simultaneos.json`).
  - S24: prueba de interrupción con la app corregida → 0 duplicados; en la BD la sesión enviada desde el teléfono tiene su `clientId` (`fase5_red/s24_red_despues.txt`, `s24_clientId_en_bd.txt`).
- **Costo medido:** las escrituras hacen una búsqueda indexada más; en la prueba de carga el promedio de escritura con 10 usuarios pasó de 49.5 a 56.2 ms (§7.6).

### P11-D02 · `PUT /favorites/:key` simultáneo respondía 500

- **Componente:** `ceosmos-api/src/favorites/favorites.controller.ts` (`add`).
- **Pasos para reproducirlo:** 10 `PUT /api/favorites/<misma clave>` simultáneos con el mismo token (`scripts/fase4_concurrencia.js`).
- **Resultado esperado:** 200 en las 10 (la operación es idempotente).
- **Resultado observado (antes):** de 1 a 3 respuestas `500 Internal server error` por corrida (en 4 de 4 corridas). Causa: el `upsert` de Prisma hace `SELECT` y luego `INSERT`; dos peticiones ven «no existe», las dos intentan insertar y la segunda choca con el índice UNIQUE (`P2002`), error que no se controlaba.
- **Evidencia (antes):** `fase4_db/antes_concurrencia_api.json`, `fase4_db/error_500_upsert_favorito.txt`.
- **Solución aplicada:** `add` captura `PrismaClientKnownRequestError` con código `P2002` y devuelve el favorito ya existente con `findUniqueOrThrow`; cualquier otro error se sigue propagando (`favorites.controller.ts:50-76`).
- **Verificación (después):** 4 corridas × 10 peticiones simultáneas → **40/40 respuestas 200**, 1 fila y 0 errores en el log de la API (`fase4_db/concurrencia_api_despues.txt`). Jest: «upsert simultáneo que pierde la carrera (P2002) devuelve el favorito, no 500» y «otros errores se siguen propagando».

### P11-D03 · Consultas sin índice en `MediaItem.userId` y `Session.userId`

- **Componente:** `ceosmos-api/prisma/schema.prisma` (`MediaItem`, `Session`).
- **Pasos para reproducirlo:** `scripts/fase4_explain.sql` con 100 000 elementos de biblioteca y 20 000 sesiones (dentro de una transacción revertida).
- **Resultado esperado:** búsqueda por índice al listar la biblioteca o las sesiones de un usuario.
- **Resultado observado (antes):** `Seq Scan`: 11.8 ms (`GET /media`), 15.1 ms (el `count` previo a cada alta) y 2.33 ms (sesiones por usuario), creciendo con el tamaño de la tabla.
- **Evidencia (antes):** `fase4_db/antes_explain_salida.txt`.
- **Solución aplicada:** `@@index([userId, createdAt])` en `MediaItem` y `@@index([userId])` en `Session`; en SQL, `CREATE INDEX "MediaItem_userId_createdAt_idx"` y `CREATE INDEX "Session_userId_idx"` (migración `20261112090000_p11_correcciones`).

| Consulta (100 000 / 20 000 filas) | Antes | Después |
| --- | --- | --- |
| `GET /media` (biblioteca del usuario) | Seq Scan, 11.8 ms | Bitmap Index Scan `MediaItem_userId_createdAt_idx`, **0.146 ms** |
| `count(*)` antes de cada alta | Seq Scan, 15.1 ms | Bitmap Index Scan, **0.115 ms** |
| Sesiones por usuario (login y `/users/me/sessions`) | Seq Scan, 2.33 ms | Bitmap Index Scan `Session_userId_idx`, **0.069 ms** |

- **Verificación (después):** `fase4_db/explain_despues.txt` (script `scripts/fase4_explain_despues.sql`).

### P11-D04 · El historial devolvía metadatos de cualquier tamaño

- **Componente:** `focus-sessions/dto/focus-sessions.dto.ts` (`metadata` sin límite) y `focus-sessions.service.ts` (`list`).
- **Pasos para reproducirlo:** guardar sesiones con metadatos grandes (cualquier cliente podía enviar hasta 100 KB por petición) y abrir el historial.
- **Resultado esperado:** el historial trae poca información por sesión.
- **Resultado observado (antes):** 50 sesiones = **148 KB** por respuesta y **42.9 ms** de latencia en el S24, frente a 22.9 ms con 64 KB. En el peor caso, 50 × 100 KB ≈ 5 MB por pantalla.
- **Evidencia (antes):** `fase5_red/s24_red_salida.txt` y `s24_red_corrida1.txt`.
- **Solución aplicada:**
  - API: validador `@MaxJsonBytes(4096)` en `metadata` (`focus-sessions.dto.ts`): más de 4 KB de JSON compacto → **400**. La app envía unos 230 bytes (resumen del wearable), así que el límite no le afecta.
  - BD: restricción `CHECK` como red de seguridad (ajustada después, ver P11-D09).
  - El peor caso del historial baja de ≈ 5 MB a ≈ 210 KB (50 × 4 KB). No se quitó `metadata` de la lista porque la app muestra el resumen del wearable en el historial.
- **Verificación (después):**
  - Jest: 4 096 bytes se aceptan, 4 097 se rechazan.
  - HTTP: H37 (más de 4 KB) → 400.
  - S24: cuerpo de 90 KB → **400**; cuerpo de 3.9 KB → 201.
  - Historial de 50 sesiones con los metadatos reales de la app: **28.2 KB y 18.9 ms** en promedio (10/10 solicitudes; `fase5_red/resumen_despues.md`).

### P11-D05 · Códigos HTTP y formato de error inconsistentes

- **Componente:** `media.service.ts`, `media.controller.ts`, `common/filters/http-exception.filter.ts`, `auth/jwt-auth.guard.ts`.
- **Resultado observado (antes):**
  - Medio duplicado → **400** (caso H27 fallido).
  - `DELETE /media/:id` → 200 con cuerpo (`/devices` usa 204).
  - El 413 salía sin el campo `error`, porque el filtro solo capturaba `HttpException`.
  - Los 401 devolvían el mensaje de la librería (`jwt malformed`).
  - Borrar un medio ajeno respondía 403, lo que revelaba que el elemento existe.
- **Evidencia (antes):** `fase3_web/antes_http_resultados.json` (33/34).
- **Solución aplicada:**
  - Duplicado → `ConflictException` (**409**).
  - `@HttpCode(204)` en `DELETE /media/:id`; `deleteMedia` usa `deleteMany({ where: { id, userId } })`, así que un medio ajeno o inexistente responde **404** (igual que `/devices`).
  - El filtro pasa a `@Catch()` y normaliza todo a `{ statusCode, message, error }`: los errores de body-parser (413, JSON inválido) con mensaje propio, y los inesperados como 500 genérico registrado en el log.
  - El guard responde `Unauthorized` sin el detalle interno.
  - En la app, `traducirError` traduce el 409 («Ese elemento ya está en tu biblioteca.»).
- **Decisión documentada:** la validación semántica (`endedAt < startedAt`) sigue en **400** y no en 422, porque el frontend web y la app ya tratan 400 como «datos inválidos». Cambiarlo no aporta y rompería clientes.
- **Verificación (después):** batería HTTP **40/40** (H27 → 409, H29 → 204 sin cuerpo, H38 → 413 con formato uniforme, H39 → 401 `Unauthorized`); Jest del filtro y del guard (`http-exception.filter.spec.ts`).

### P11-D06 · Secreto JWT por defecto `'changeme'`

- **Componente:** `ceosmos-api/src/auth/auth.module.ts`, `src/auth/jwt.strategy.ts`.
- **Pasos para reproducirlo:** arrancar la API sin `JWT_SECRET` (por ejemplo, un redespliegue con variables incompletas).
- **Resultado esperado:** la API no arranca sin secreto.
- **Resultado observado (antes):**
  - La API arrancaba y firmaba los tokens con `'changeme'`, un valor público: cualquiera podía falsificar un JWT.
  - Además, `JwtModule.register` leía la variable **al importar el módulo**, antes de que `ConfigModule` cargara el `.env`. Hoy funcionaba solo porque el cliente de Prisma, importado antes, carga el `.env` de forma implícita. Se comprobó que la firma era la del secreto real y no la de `'changeme'` (`fase1_estatico/10_jwt_secreto_antes.txt`), pero cambiar el orden de los imports habría bastado para romper o debilitar la autenticación.
- **Evidencia (antes):** `fase1_estatico/08_secretos.txt` y `10_jwt_secreto_antes.txt`.
- **Solución aplicada:** `src/auth/jwt-secret.ts` con `jwtSecret()`, que lanza un error si la variable falta, vale `changeme` o mide menos de 32 caracteres. `JwtModule.registerAsync({ useFactory })` y `JwtStrategy` la usan en tiempo de ejecución, así que ya no dependen del orden de los imports.
- **Verificación (después):** la API compilada, ejecutada sin `.env` ni `JWT_SECRET`, se detiene con «JWT_SECRET no está definido o tiene menos de 32 caracteres; la API no puede arrancar.» y código de salida 1 (`fase1_estatico/13_jwt_sin_secreto_despues.txt`); Jest con 3 casos (sin secreto, `changeme` o 31 caracteres rechazados; 32 aceptados). Con el `.env` real (54 caracteres) la API arranca y todas las pruebas autenticadas pasan.

### P11-D07 · Alta de medios «leer y luego escribir» sin protección

- **Componente:** `media.service.ts` (`addMedia`).
- **Resultado observado (antes):** el límite de 100 y la verificación de duplicados eran tres consultas separadas sin transacción. Era un riesgo teórico: no se reprodujo en 40 altas simultáneas.
- **Solución aplicada:** `addMedia` corre dentro de `prisma.$transaction` y lo primero que hace es ``SELECT pg_advisory_xact_lock(hashtext(${userId}))``. Es un bloqueo por usuario que se libera solo al terminar la transacción, así que dos altas del mismo usuario se ejecutan una después de la otra. La consulta es parametrizada (tagged template de Prisma) y no concatena texto.
- **Verificación (después):** 4 corridas × 10 altas simultáneas de la misma imagen → **1 × 201 y 9 × 409**, 1 fila. Jest comprueba que el bloqueo se toma antes del `count` y que el `userId` viaja como parámetro.

### P11-D08 · Dependencias del backend con vulnerabilidades conocidas

- **Componente:** `ceosmos-api/package.json`.
- **Resultado observado (antes):** `npm audit --omit=dev`: **38** vulnerabilidades (3 críticas: `handlebars` y `liquidjs` vía `@nestjs-modules/mailer`, y `proxy-addr`; 20 altas, entre ellas `ws`).
- **Evidencia (antes):** `fase1_estatico/05_npm_audit.txt`.
- **Solución aplicada:**
  - `npm audit fix` (actualizaciones compatibles).
  - Se eliminaron `@nestjs-modules/mailer`, `nodemailer` y `@types/nodemailer`: ningún archivo de `src/` los importa, porque el correo se envía con Resend (`src/mail/mail.service.ts`).
  - `npm audit fix` dejó `@nestjs/core` en 11.2.9 y `@nestjs/common` en 11.1.17, una combinación incompatible que hizo fallar la suite de `app.controller.spec.ts`. Se alinearon `@nestjs/common` y `@nestjs/testing` a 11.2.9.
- **Verificación (después):** `npm audit --omit=dev` → **found 0 vulnerabilities** (`fase1_estatico/12_npm_audit_despues.txt`); `nest build` correcto; Jest 64/64.

### P11-D09 · Regresión introducida por la corrección de P11-D04 (detectada en el S24)

- **Componente:** migración `20261112090000_p11_correcciones` (CHECK `FocusSession_metadata_tamano_check`).
- **Pasos para reproducirlo:** desde el teléfono, guardar una sesión con metadatos de 3.9 KB (válidos según la API).
- **Resultado esperado:** 201.
- **Resultado observado:** **500**. El log muestra `code: "23514" … violates check constraint "FocusSession_metadata_tamano_check"`. Causa: la API mide el JSON compacto (`JSON.stringify`), pero el CHECK medía `metadata::text`, y PostgreSQL escribe el JSONB con un espacio después de cada `,` y `:`. Por ejemplo, `{"a":[1,2,3],"b":"x"}` ocupa 21 bytes compacto y 26 bytes como texto JSONB.
- **Evidencia:** `fase5_red/s24_red_despues_intento2_regresion_500.txt`, `fase4_db/regresion_check_jsonb.txt`.
- **Solución aplicada:** migración nueva `20261112093000_p11_metadata_check`. El límite de negocio (4 KB compactos) queda solo en la API, y el CHECK de la BD pasa a ser una red de seguridad de 8 KB sobre `metadata::text`; la forma de texto de JSONB nunca llega al doble del JSON compacto. No se editó la migración ya aplicada.
- **Verificación (después):** S24 → los 3 envíos de 3.9 KB responden **201** (`fase5_red/s24_red_despues.txt`); nuevo caso de regresión **H40** (metadata en el límite exacto de 4 096 bytes, con muchos separadores) → 201.
- **Lección:** cuando una regla se valida en dos capas, ambas deben medir lo mismo; la prueba en el dispositivo real detectó una diferencia que las pruebas unitarias con dobles no podían ver.

### 8.10 Despliegue pendiente de las correcciones

- Las migraciones se aplicaron solo en la base **local** (`127.0.0.1:5433`, `fase4_db/migracion_local.txt`). Neon y Railway no se modificaron, porque las acciones en producción requieren tu autorización.
- **La API y la app nuevas deben desplegarse juntas:** la app corregida envía `clientId`, y una API anterior, con `forbidNonWhitelisted`, lo rechazaría con 400.
- Orden para producción: 1) aplicar las dos migraciones en Neon (`node prisma/migrate-ws.js --apply`); 2) desplegar la rama `movil-integral` de la API; 3) compilar la app.

## 9. Matriz de pruebas White Box (después de las correcciones)

### Aplicación móvil

| ID | Prueba | Resultado | Evidencia |
| --- | --- | --- | --- |
| WB-01 | Cobertura de instrucciones | **Aprobado**: 100 % en los 7 métodos críticos; 78.6 % del núcleo | `fase2_app/cobertura_resumen.txt`, `lcov.info` |
| WB-02 | Cobertura de decisiones | **Aprobado**: 100 % de ramas en los métodos críticos; 75.8 % del núcleo | ídem |
| WB-03 | Cobertura de condiciones | **Aprobado**: cada condición atómica de `parse`, `resumenSesion` y `_send` tomó V y F (tablas §4.1–4.3) | `test/whitebox/*`, `wb_salida.txt` |
| WB-04 | Manejo de excepciones | **Aprobado** (P11-D01 corregido): timeout, sin red, 401, 5xx, JSON inválido, TCP cerrado, respuesta perdida | `wb_comunicacion_test.dart` (73/73) |
| WB-05 | Validación de entradas | **Aprobado** | `wb_validacion_test.dart` |
| WB-06 | Rendimiento de interfaz | **Aprobado**: p90 5.6/5.8 ms, 0.5 % de cuadros > 16.7 ms | `fase2_app/ui_perf_s24.json` |

### Sitio web / API

| ID | Prueba | Resultado | Evidencia |
| --- | --- | --- | --- |
| WEB-01 | Respuesta HTTP exitosa | **Aprobado** (200/201/204) | `fase3_web/http_resultados.json` |
| WEB-02 | Respuesta HTTP de error | **Aprobado** (P11-D02 y D05 corregidos): 400/401/403/404/409/413/429 correctos, sin 500 en concurrencia | ídem, `fase4_db/concurrencia_api_despues.txt` |
| WEB-03 | Validación del backend | **Aprobado**: Jest 64/64; límites de `metadata` y `clientId` | `fase3_web/jest_backend.txt` |
| WEB-04 | Autenticación y autorización | **Aprobado** (P11-D06 corregido): 401 ≠ 403, token revocado, secreto obligatorio | H05–H10, H33, H39 |
| WEB-05 | Latencia HTTP | **Aprobado**: 18.9 ms promedio desde el S24 (antes 42.9 ms) | `fase5_red/resumen_despues.md` |
| WEB-06 | Consistencia de respuesta | **Aprobado**: 10/10 con el mismo código y tamaño | ídem |

### Base de datos

| ID | Prueba | Resultado | Evidencia |
| --- | --- | --- | --- |
| DB-01 | Inserción válida | **Aprobado** | `fase4_db/crud_salida.txt` |
| DB-02 | Integridad | **Aprobado**: NOT NULL, CHECK, ENUM, FK, UNIQUE (incluido `userId, clientId`), transacción revertida | ídem, `d01_reintentos_simultaneos.json` |
| DB-03 | Consulta | **Aprobado** (P11-D03 corregido): todas las consultas por usuario usan índice | `explain_despues.txt` |
| DB-04 | Actualización | **Aprobado** | `crud_salida.txt` |
| DB-05 | Eliminación | **Aprobado**, persistencia verificada | ídem |
| DB-06 | Concurrencia | **Aprobado** (P11-D02 y D07 corregidos) | `concurrencia_sql.txt`, `concurrencia_api_despues.txt` |

### Conectividad y rendimiento

| ID | Prueba | Resultado | Evidencia |
| --- | --- | --- | --- |
| NET-01 | Ping | **Aprobado**: 0 % de pérdida, 54.9 ms a la laptop; Neon bloquea ICMP (documentado) | `fase5_red/ping_s24.txt` |
| NET-02 | Latencia de API | **Aprobado**: 18.9 ms (después) / 42.9 ms (antes) | `s24_red_despues.txt`, `s24_red_salida.txt` |
| NET-03 | Tasa de descarga | **Medido**: 9.15–11.65 Mbps por Wi-Fi (sitio web) | ídem |
| NET-04 | Tasa de subida | **Medido**: 2.27 Mbps con 100 KB (antes); tras P11-D04 el cuerpo máximo es ~4 KB y la «tasa» queda dominada por la latencia (0.86 Mbps) | ídem |
| NET-05 | Pérdida de conexión | **Aprobado**: detectada en 20–47 ms, no se muestra como exitosa | `.host` + salidas |
| NET-06 | Recuperación | **Aprobado** (P11-D01 corregido): 0 duplicados, incluso con respuesta perdida | ídem + `d01_reintentos_simultaneos.json` |
| NET-07 | Carga controlada | **Aprobado**: 3 200 + 3 200 solicitudes, 0 fallidas antes y después | `fase5_carga/` |

## 10. Registro de métricas

### A. Tabla de medición de conectividad

| Métrica | Unidad | Muestras | Valor |
| --- | --- | --- | --- |
| Ping mínimo (S24 → laptop) | ms | 20 paquetes | 23.2 |
| Ping promedio | ms | 20 paquetes | 54.9 |
| Ping máximo | ms | 20 paquetes | 125.0 |
| Pérdida de paquetes | % | 20 paquetes | 0 |
| Latencia HTTP | ms | 10 solicitudes | Antes 42.9 (mín 32.0, máx 79.2, desv 14.0); después 18.9 (mín 14.5, máx 34.3, desv 5.5) |
| Tiempo de descarga | s | 3 mediciones | 0.558 (637 KB por Wi-Fi) |
| Tasa de descarga | Mbps | 3 mediciones | 9.15 |
| Tasa de subida | Mbps | 3 mediciones | 2.27 |
| Tamaño de respuesta | bytes / KB | 10 solicitudes | Antes 151 588 B = 148 KB; después 28 851 B = 28.2 KB |
| Tiempo de consulta DB | ms | 3+ consultas | Q1 0.088 · Q3 0.026 · Q5 0.066 (EXPLAIN ANALYZE); con volumen Q2 11.8 |

### C. Indicadores calculados

| Indicador | Valor | Objetivo orientativo | Cumple |
| --- | --- | --- | --- |
| Latencia promedio HTTP | 18.9 ms (antes 42.9 ms) | ≤ 500 ms | Sí |
| Pérdida de paquetes | 0 % | 0 % | Sí |
| Tasa de transferencia (descarga Wi-Fi) | 9.15 Mbps | – | – |
| Cobertura de instrucciones (módulos críticos) | 100 % (métodos); 95.8–100 % (`wearable*`, `api_client`) | ≥ 85 % | Sí |
| Cobertura de ramas (módulos críticos) | 100 % (métodos); 88.9–100 % | ≥ 80 % | Sí |
| Tiempo de consulta sencilla a DB | < 0.3 ms (ejecución), 2.1 ms con ida y vuelta de psql | ≤ 200 ms | Sí |
| Respuestas exitosas del endpoint | 10/10 = 100 % (y 3 200/3 200 en carga) | 100 % | Sí |
| Operaciones inválidas correctamente rechazadas | Después: 40/40 casos HTTP (antes 33/34); 9/9 inserciones inválidas en la BD | 100 % | Sí |

## 11. Preguntas

**1. Diferencia entre cobertura de instrucciones, de decisiones y de condiciones (ejemplo de CEOSMOS).**
La de instrucciones mide qué líneas se ejecutaron; la de decisiones, si cada `if` tomó la salida verdadera y la falsa; la de condiciones, si cada condición atómica dentro de una decisión fue verdadera y falsa. En `WearableLectura.parse`, la línea `if (hr is! num || hr < 30 || hr > 230) return null;` queda cubierta al 100 % de instrucciones con dos casos (`{hr:72}` y `{}`) y también al 100 % de decisiones (V y F). Pero con esos dos casos nunca se evalúa `hr > 230` como verdadera (el `||` corta antes); solo los casos `hr=29` y `hr=231` hacen que `hr < 30` y `hr > 230` tomen el valor V. Por eso se diseñaron 7 caminos (CB1–CB7).

**2. Método con mayor complejidad ciclomática y consecuencias.**
En el núcleo, `traducirError` (`lib/data/api_client.dart:94`, V(G) ≈ 27; 28 tras agregar la traducción del 409 en P11-D05) — solo lo supera `AuthScreen.build` (28), que es construcción de interfaz. Consecuencias: hacen falta al menos 27 casos para cubrir sus caminos (se hicieron 23 casos de tabla que cubren el 100 % de sus ramas), el orden de los `if` importa (p. ej. «invalid or expired code» debe evaluarse antes que «invalid or expired») y un cambio en un mensaje del backend puede caer en la rama equivocada sin que falle la compilación. Conviene convertirlo en una tabla de pares (patrón → mensaje) o que la API devuelva códigos de error estables. En la API, el mayor es `csrfMiddleware` (12).

**3. Diferencia entre ping y tiempo de respuesta de una API.**
El ping mide el viaje de ida y vuelta de un paquete ICMP a nivel de red (IP), sin conexión ni aplicación. El tiempo de respuesta de la API incluye el establecimiento TCP (y TLS si es HTTPS), el envío de la petición, la autenticación del JWT, las consultas a PostgreSQL, la serialización JSON y la transferencia del cuerpo. En CEOSMOS: ping a la laptop 54.9 ms (por Wi-Fi); la API por USB 42.9 ms con 148 KB de respuesta. No son equivalentes: además, Neon bloquea ICMP (100 % de pérdida) aunque el servicio funciona.

**4. Ping de 30 ms pero solicitud HTTP de 2 000 ms.**
Resolución DNS; apertura de TCP y negociación TLS (varios viajes de ida y vuelta); servidor en reposo que «despierta» (Railway o Neon serverless suspenden el cómputo); consultas lentas o sin índice (como `MediaItem` sin índice); bloqueos de fila por concurrencia (en §6.6 una escritura esperó 2.23 s un bloqueo); saturación del proceso Node (en la carga la latencia se duplicó sin que cambiara la red); respuestas grandes con poco ancho de banda; limitador de peticiones, colas o reintentos; y tiempo de CPU del teléfono para decodificar el JSON.

**5. Efecto del tamaño de la respuesta JSON en la app móvil.**
Afecta el tiempo de transferencia, la memoria y la CPU para decodificar, la batería y el consumo de datos móviles. Medido en el S24: el mismo `GET /focus-sessions?limit=50` pasó de 64 KB a 148 KB y su latencia de 22.9 ms a 42.9 ms; con 100 elementos (218 KB) una descarga llegó a 160 ms. La carga inicial de la app (4 lecturas) tardó 984 ms. Por eso se limitó `metadata` a 4 KB (P11-D04): con los metadatos reales de la app el historial pasó a 28 KB y 18.9 ms. Además, conviene devolver solo los campos que se muestran y paginar.

**6. Pérdida de conexión después de enviar y antes de recibir la respuesta.**
El cliente no sabe si el servidor procesó la petición. En CEOSMOS, `ApiClient` lanza «No hay conexión», `finishSession` marca la sesión como pendiente y la reenvía en la siguiente carga; antes de la corrección, si el servidor sí la había guardado se creaba un duplicado (reproducido en la prueba del defecto P11-D01). Ahora el reintento lleva el mismo `clientId` y el servidor devuelve la sesión que ya tenía: no se pierden datos, no se muestra un éxito falso y no se duplica.

**7. Cómo evitar que una solicitud reintentada genere duplicados.**
Con idempotencia, que es lo que se implementó en CEOSMOS (P11-D01): la app genera un UUID v4 por sesión antes del primer intento (`clientId`); la BD tiene `UNIQUE(userId, clientId)`; la API busca esa clave y, si existe, devuelve la fila; si dos reintentos llegan a la vez, el UNIQUE rechaza al segundo y la API devuelve la ganadora. Verificado con 10 reintentos simultáneos → 1 fila. En operaciones naturalmente idempotentes se usa `PUT`/`upsert` (como `PUT /favorites/:key`), controlando el `P2002` que aparece en concurrencia (P11-D02, también corregido). Además, conviene reintentar con espera exponencial y un límite.

**8. Ventajas de una transacción al modificar varios registros.**
Atomicidad (todo o nada), consistencia con las restricciones, aislamiento frente a otras operaciones concurrentes y durabilidad. Se comprobó en §6.1: una transacción con una inserción válida y otra que violaba UNIQUE terminó con 0 filas, en lugar de dejar la mitad. En la API, `AuthService` usa `$transaction` para marcar el código como usado y verificar el correo a la vez; Con la corrección P11-D07, `MediaService.addMedia` también usa una transacción, con un bloqueo por usuario.

**9. Diferencias entre ejecutar una consulta directamente en la BD y desde la app.**
Directamente en PostgreSQL, el historial (Q1) se ejecuta en 0.088 ms (0.26 ms con 100 000 filas). Desde la app, la misma información tarda 22.9–42.9 ms: se suman la red/USB, el `JwtAuthGuard` (2 consultas extra por petición: sesión por token y usuario), el `ValidationPipe`, Prisma (construcción de la consulta y conversión de filas a objetos), la serialización a JSON de 64–148 KB y la decodificación en el teléfono. Además, desde la app los resultados siempre se filtran por el `userId` del token (no se puede consultar lo de otro usuario), y la API impone límites (`limit` ≤ 100).

**10. Principal cuello de botella y evidencia.**
El proceso de la API (Node.js) — en particular su hilo de JavaScript y el trabajo fijo por petición — no la base de datos. Evidencia: a partir de 5 usuarios el rendimiento se estanca en ~150–156 lecturas/s y ~196–201 escrituras/s mientras la latencia crece de forma lineal (33 → 64 ms en lectura), la CPU del proceso queda en ~170 % (un hilo de JS saturado + hilos de Prisma) y cada consulta tarda < 0.3 ms en PostgreSQL. Cada petición hace ~2.8 transacciones, dos de ellas solo para validar el JWT. Para el usuario del teléfono, el segundo factor es el tamaño de las respuestas (P11-D04). Mejoras: guardar en caché la validación de la sesión, devolver menos datos, más instancias/`cluster` de Node y los índices de P11-D03, ya aplicados, para cuando crezcan las tablas.

## 12. Código fuente de las pruebas entregadas

| Archivo | Qué prueba |
| --- | --- |
| `test/whitebox/wb_validacion_test.dart` | `parse`, `_alRecibir` (TCP real), validaciones de acceso — valores límite y excepciones |
| `test/whitebox/wb_calculo_test.dart` | `resumenSesion`, `traducirError`, temporizador |
| `test/whitebox/wb_comunicacion_test.dart` | `ApiClient._send`, `finishSession`, defecto P11-D01 |
| `integration_test/p11_red_test.dart` | Latencia, transferencia e interrupción desde el S24 |
| `integration_test/p11_ui_perf_test.dart` + `test_driver/p11_perf_driver.dart` | Rendimiento de la interfaz en el S24 |
| `ceosmos-api/src/focus-sessions/focus-sessions.service.spec.ts` | Servicio y DTO de sesiones de enfoque |
| `ceosmos-api/src/devices/devices.controller.spec.ts` | Dispositivos, DTO de dirección, favoritos |
| `ceosmos-api/src/media/media.service.spec.ts` | Biblioteca multimedia (transacción con bloqueo, 409, borrado por dueño) |
| `ceosmos-api/src/common/filters/http-exception.filter.spec.ts` | Filtro de errores, guard JWT y secreto obligatorio (correcciones D05/D06) |
| `ceosmos-api/prisma/migrations/20261112090000_p11_correcciones` y `20261112093000_p11_metadata_check` | Migraciones de las correcciones (aplicadas solo en local) |
| `p11yp12/p11/scripts/*` | Análisis estático, cobertura, HTTP, SQL, concurrencia, red, carga y grafos |

Copias de todos ellos en `p11yp12/p11/codigo_pruebas/`.
