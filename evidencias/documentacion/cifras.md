# Cifras vigentes de CEOSMOS Móvil Integral (fuente única)

Corte: **25/11/2026**. Todo documento de la entrega (Seguimiento, Reporte de avances, Manual, Matriz de cumplimiento, reporte de las prácticas 13 y 14, Hoja de defensa) debe coincidir con este archivo. «Medido hoy» significa que se ejecutó el 25/11/2026; los demás datos vienen de la evidencia indicada y no se repitieron.

## Versión y etiquetas

| Dato | Valor | Fuente |
|---|---|---|
| Versión de la app | **1.3.0+5** | `pubspec.yaml` |
| Commit de la versión 1.3.0 | `fc37eed` (25/11/2026) | `git log` |
| Etiquetas | `entrega-v1` 7c6715e (21/11) · `entrega-v2` ce1d0d1 (22/11) · `entrega-v3` be6b0ba (22/11) · `entrega-v4` 2167f30 (22/11, app 1.2.1) | `git tag` |
| La versión 1.3.0 no tiene etiqueta propia | — | `git tag` |
| Primer commit del repositorio | 11/11/2026 (`7417fdf`, línea base) | `git log --reverse` |
| Primera revisión (anterior al repositorio) | 08/10/2026 | `memoria/10 - Bitácora.md` |
| Commits en `main` antes de la documentación final | 42 | `git log` |
| APK instalado en los equipos | 1.2.1 (`entrega-v4`); **1.3.0 no instalado** (equipos sin conectar el 24 y el 25/11) | `memoria/13`, `adb devices` vacío |

## Pruebas (medido hoy, 25/11/2026)

| Conjunto | Resultado | Comando |
|---|---|---|
| Flutter (unitarias, widgets, caja negra y blanca, BLE, PWA, sin conexión, 91 tamaños…) | **344/344** en 2 min 10 s | `flutter test --coverage` |
| Análisis estático | **0 avisos** | `flutter analyze` |
| API (Jest, rama `blindaje-api` 3617c0d, mismo código fusionado a producción) | **79/79** (7 suites) | `npx jest` |
| Kotlin (Reloj, TV y Companion) | **14/14 cada una** (42 en debug) | `gradlew test{Reloj,Tv,Companion}DebugUnitTest --rerun` |
| Cobertura de líneas, toda la app | **56.0 %** (3 373 de 6 023) | `coverage/lcov.info` |
| Cobertura del núcleo (`core`, `data`, `domain`) | **84.8 %** (1 437 de 1 695) | `coverage/lcov.info` |

Históricos (no son la cifra vigente): 11 pruebas (08/10) · 215 (18–19/11, prácticas 13 y 14, cobertura 49.5 %) · 216 (21/11) · 331 (22/11, 1.2.1, cobertura 52.9 % / núcleo 78.9 %) · 344 (24/11, 1.3.0).

### Prácticas 13 y 14 (siguen en el repositorio y pasan hoy)

| Tipo | Cantidad | Archivo |
|---|---|---|
| Unitarias Dart | 16 (15 + 1 de regresión DEF-BLE-01) | `test/p13_14/aut01_03_unitarias_test.dart`, `aut03_regresion_tv_reiniciada_test.dart` |
| Unitarias Kotlin | 5 | `companion/app/src/test/.../AutomatizacionProtocoloTest.kt` |
| Integración | 11 (HTTP 4 · sin servidor 2 · SQLite 5) | `test/p13_14/aut04…aut06_*.dart` |

## Integración continua (GitHub Actions)

| Dato | Valor |
|---|---|
| Corridas totales hasta la 1.3.0 | **29**: 27 en verde, 1 fallida (21/11, corregida en la siguiente) y 1 cancelada (22/11 hora local, reemplazada por un push posterior) |
| Corrida de la 1.3.0 (`fc37eed`, 25/11) | **verde**, 5 tareas (Flutter, PWA, Kotlin Reloj, TV y Companion): https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/45686893198 |
| Corrida de `entrega-v4` (1.2.1) | https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/45099965435 |
| Corrida de `main` tras el merge de las prácticas 13 y 14 (#9) | https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44438169735 |
| Corridas de las prácticas 13 y 14 | #1–#9, todas en verde (logs en `evidencias/p13_14/ci_run_*.txt`) |
| Página de Actions | https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions |

La corrida del commit que agrega esta documentación se consulta en la página de Actions (último push a `main`).

## Seguridad, robustez y red (medido el 22/11, no repetido)

| Dato | Valor | Evidencia |
|---|---|---|
| Red Box original (API local) | 13/13 | `evidencias/redbox_api.txt` |
| Red Box ampliado (API local) | 37/37 (27/37 antes de corregir 6 fallos) | `evidencias/blindaje/redbox_ampliado.txt` |
| Red Box en producción sin credenciales | 27/27 (≤ 4 peticiones/s) | `evidencias/blindaje/` |
| Usuario torpe | 12 100 acciones: S24 5 000 (0 errores) · Tab S9 5 000 (4 desbordes, corregidos) · verificación 2 100 (0 errores). Plan inicial de 20 000 no completado | `evidencias/blindaje/mono/` |
| Tamaños de ventana | 91 (240–1600 × 320–1000 dp) sin desbordes; ventana flotante real: cómoda desde 260 × 440 dp | `test/tamanos_pantalla_test.dart` |
| Red mínima de la API | 5 kbps o RTT de 4 s (límite de 15 s de la app); EDGE/2G 2.5 s; 20 % de pérdida ≤ 5 s | `evidencias/blindaje/red/red_minima.md` |
| Firebase | falla con RTT de 4 s; funciona con 2 s | ídem |
| Continentes | 6 continentes con respuesta 200 de la API (137–763 ms); Madrid y Logroño 373–400 ms | `evidencias/blindaje/red/geografia.md` |
| Reloj y TV de punta a punta | 6 de 7 casos en hardware; reconexión corregida en 1.2.1 (≈ 4 s, sin PIN); tercer teléfono sin PIN no verificado | `memoria/13 - Blindaje.md` |
| Soporte con roles | TC01–TC08 con 4 cuentas (19/11); 3 de 4 roles repetidos con 1.2.1 (usuario2 no verificado) | `evidencias/p07_*.png` |
| Plan de contingencia | 3 fallos simulados, 1.9–2.4 min por ciclo | `scripts/arreglo_rapido.*` |

## PWA (medido el 24/11 en Chromium contra la API local)

| Dato | Valor |
|---|---|
| Precarga del service worker | 31 archivos, 19.1 MB; caché con 32 entradas |
| Errores de instalabilidad (Chrome) | 0 |
| Sesión terminada sin red | enviada una sola vez al volver la red (mismo `clientId`) |
| Web Bluetooth contra el Reloj y la TV reales | **no verificado en hardware** |
| Pulso y pasos del Reloj | **simulados** (la Tab S9 no tiene sensor de frecuencia cardiaca) |

## Hitos (fechas de git, salvo el 08/10)

08/10 primera revisión local · 11/11 línea base, API real y caja blanca · 18/11 optimización y resiliencia, BLE en hardware, Red Box, CI y repositorio público · 19/11 Soporte con 4 roles · 21/11 sistema de diseño, prácticas como funciones, `entrega-v1` · 22/11 blindaje, API corregida en producción, `entrega-v2…v4` (1.2.1) · 24/11 revisión de la rúbrica, PWA y modo sin conexión (sin commit) · 25/11 commit de la 1.3.0 y documentación final.
