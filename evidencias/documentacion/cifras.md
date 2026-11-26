# Cifras vigentes de CEOSMOS Móvil Integral (fuente única)

Corte: **26/11/2026 (1.4.0)**. Los documentos entregados (Reporte final y Manual) son de la 1.3.0 y no se regeneraron: lo nuevo está en la adenda `evidencias/v1_4/LEEME.md`. Todo documento de la entrega (Seguimiento, Reporte de avances, Manual, Matriz de cumplimiento, reporte de las prácticas 13 y 14, Hoja de defensa) debe coincidir con este archivo. «Medido hoy» significa que se ejecutó el 26/11/2026; los demás datos vienen de la evidencia indicada y no se repitieron.

## Versión y etiquetas

| Dato | Valor | Fuente |
|---|---|---|
| Versión de la app | **1.4.0+6** (companion Reloj/TV/Companion: 1.4.0, versionCode 2) | `pubspec.yaml`, `companion/app/build.gradle.kts` |
| Commits de la 1.4.0 | Fases 1–5: `2f21234`, `33f65f2`, `a5e8e05`, `2ae89fb`, `592daf8`, `02fd57f` (26/11) | `git log` |
| Commit de la versión 1.3.0 | `fc37eed` (25/11/2026) | `git log` |
| Etiquetas | `entrega-v1` 7c6715e (21/11) · `entrega-v2` ce1d0d1 (22/11) · `entrega-v3` be6b0ba (22/11) · `entrega-v4` 2167f30 (22/11, app 1.2.1) · `respaldo-pre-1.4.0` 31defc1 · `entrega-v5` (1.4.0, commit de cierre del 26/11) | `git tag` |
| Primer commit del repositorio | 11/11/2026 (`7417fdf`, línea base) | `git log --reverse` |
| Primera revisión (anterior al repositorio) | 08/10/2026 | `memoria/10 - Bitácora.md` |
| Commits en `main` antes de la documentación final | 42 | `git log` |
| APK instalado en los equipos | **1.4.0** con `install -r` (26/11): S24 CEOSMOS; Tab S9 CEOSMOS, Reloj y TV. Datos, sesión y emparejamiento intactos | `evidencias/v1_4/LEEME.md` |

## Pruebas (medido hoy, 26/11/2026)

| Conjunto | Resultado | Comando |
|---|---|---|
| Flutter (unitarias, widgets, caja negra y blanca, BLE, PWA, sin conexión, 91 tamaños…) | **374/374** en 1 min 38 s | `flutter test --coverage` |
| Análisis estático | **0 avisos** | `flutter analyze` |
| API (Jest, rama `espacios-1.4.0`, PR CE0S23/CEOSMOSV2#2 **sin fusionar**: producción sigue con 79) | **89/89** (8 suites) | `npx jest` |
| Kotlin (Reloj, TV y Companion) | **30/30 cada una** (90 en debug) | `gradlew test{Reloj,Tv,Companion}DebugUnitTest` |
| Kotlin de la app (campos nativos sin espacios) | **5/5** | `android: gradlew :app:testDebugUnitTest` |
| Cobertura de líneas, toda la app | **58.1 %** (3 755 de 6 458) | `coverage/lcov.info` |
| Cobertura del núcleo (`core`, `data`, `domain`) | **84.7 %** (1 578 de 1 864) | `coverage/lcov.info` |

Históricos (no son la cifra vigente): 11 pruebas (08/10) · 215 (18–19/11, prácticas 13 y 14, cobertura 49.5 %) · 216 (21/11) · 331 (22/11, 1.2.1, cobertura 52.9 % / núcleo 78.9 %) · 344 (24–25/11, 1.3.0, cobertura 56.0 % / núcleo 84.8 %).

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
| Red Box en producción sin credenciales | 27/27 (22/11); con los casos nuevos P-24/P-25: **28/29** el 26/11 (P-25 falla hasta fusionar el PR #2) | `evidencias/v1_4/redbox_produccion_antes.txt` |
| Usuario torpe | 12 100 acciones: S24 5 000 (0 errores) · Tab S9 5 000 (4 desbordes, corregidos) · verificación 2 100 (0 errores). Plan inicial de 20 000 no completado | `evidencias/blindaje/mono/` |
| Tamaños de ventana | 91 (200–1600 × 320–1000 dp); sin desbordes desde 240 dp, también con la tarjeta «Tu Reloj y TV» cargada (26/11, `evidencias/v1_4/barrido_tamanos.md`); la columna de 200 dp queda fuera de la regla; ventana flotante real: cómoda desde 260 × 440 dp | `test/tamanos_pantalla_test.dart` |
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
| Web Bluetooth contra el Reloj y la TV reales | **no verificado en hardware** (26/11: el S24 quedó bloqueado con su PIN de pantalla) |
| Lighthouse 12.8.2 (26/11, `localhost:4200`, API de producción, pantalla de acceso) | móvil: rendimiento 61 · accesibilidad 92 · buenas prácticas 82 · SEO 100; escritorio: 70 · 92 · 81 · 100 (`evidencias/v1_4/lighthouse/`) |
| Instalabilidad (CDP `Page.getInstallabilityErrors`, 26/11) | 0 errores; manifiesto y `sw.js` activos (`evidencias/v1_4/instalabilidad.json`) |
| Pulso y pasos del Reloj | pulso **simulado** (8 modos, 1.4.0); pasos simulados o del contador de pasos real de la Tab S9 |
| Botones del Reloj y la TV (26/11) | antes: foco del D-pad perdido tras cada pulsación (5/5); después: Reloj 50/50, TV 50/50, D-pad 30/30, mediana 34–86 ms (`evidencias/v1_4/botones_*`) |

## Hitos (fechas de git, salvo el 08/10)

08/10 primera revisión local · 11/11 línea base, API real y caja blanca · 18/11 optimización y resiliencia, BLE en hardware, Red Box, CI y repositorio público · 19/11 Soporte con 4 roles · 21/11 sistema de diseño, prácticas como funciones, `entrega-v1` · 22/11 blindaje, API corregida en producción, `entrega-v2…v4` (1.2.1) · 24/11 revisión de la rúbrica, PWA y modo sin conexión (sin commit) · 25/11 commit de la 1.3.0 y documentación final · 26/11 1.4.0 (campos sin espacios, simulación y alertas, robustez del Reloj y la TV, tarjeta de Inicio).
