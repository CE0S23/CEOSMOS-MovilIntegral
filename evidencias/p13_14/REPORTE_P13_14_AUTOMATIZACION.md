# Prácticas 13 y 14 · Automatización de pruebas y validación continua — CEOSMOS Integral

Fecha: 18/11/2026 · Repositorio: https://github.com/CE0S23/CEOSMOS-MovilIntegral · PR: https://github.com/CE0S23/CEOSMOS-MovilIntegral/pull/1

## 1. Componentes críticos elegidos
| # | Componente | Código | Por qué (resultado de la práctica anterior) |
| --- | --- | --- | --- |
| 1 | Acceso (inicio de sesión / registro / verificación) | `lib/data/auth_repository.dart`, `lib/ui/auth_screen.dart` | Puerta de entrada a la API real; P8 (CP-01…06) y Red Box (inyección SQL, 401) mostraron que la validación del cliente y la traducción de errores evitan llamadas inútiles y fugas de detalles. Parte de la validación estaba dentro de la UI. |
| 2 | Comunicación: cliente HTTP de la API y protocolo BLE reto + HMAC | `lib/data/api_client.dart`, `lib/core/ble/ble_protocolo.dart`, `lib/core/ble/ecosistema_ble.dart`, `companion/.../Protocolo.kt` | Los dos defectos de hardware del 18/11 fueron de comunicación BLE; P12 corrigió el doble plazo del cliente HTTP (26 s en RES-01). |
| 3 | Persistencia P4 (alumnos en SQLite, migración v1→v2 del campo `correo`) | `lib/practicas/p03_04/usuarios/` | Única migración de esquema de la app: si falla, se pierden los alumnos guardados con v1. Solo se había probado a mano en el S24. |

## 2. Defecto previo que se previene (DEF-BLE-01)
«La TV reiniciada seguía marcando *Conectado*»: Reloj y TV comparten un solo enlace BLE con la tablet. Al cerrar y abrir la app TV, su servidor GATT olvida la autenticación pero el enlace sigue arriba; CEOSMOS mostraba «Conectado» y cada proyección era rechazada (GATT_INSUFFICIENT_AUTHORIZATION). La prueba `test/p13_14/aut03_regresion_tv_reiniciada_test.dart` lo reproduce con el periférico simulado.

Demostración (`scripts/p13_14_regresion.sh`):
- Código viejo (`1a8f98c^`): **FALLA** — `Expected: contains RolBle.tv · Actual: Set:[RolBle.reloj]` (`regresion_codigo_viejo.txt`).
- Código corregido: **PASA** (`regresion_codigo_nuevo.txt`).

## 3. Pruebas creadas
**Unitarias (Flutter, 15 + 1 de regresión)** — `test/p13_14/aut01_03_unitarias_test.dart`: entrada válida, vacía/nula, fuera de rango (contraseña 7/73, usuario 2/31, edad 0/121, pulso 29/231), resultado esperado (vector HMAC idéntico al de Kotlin, recorte a 180 bytes, la configuración nunca apunta a producción) y excepciones (PIN/reto inválido → `ArgumentError`, basura binaria descartada, errores HTTP traducidos sin detalles internos). Los validadores del código de verificación, del token de restablecimiento, de la contraseña de inicio y de edad/campos de la P4 se **extrajeron de la UI** a funciones (`AuthRepository.validar…`, `validarEdadUsuario`, `validarObligatorio`) sin cambiar mensajes ni comportamiento.

**Unitaria Kotlin (5)** — `companion/app/src/test/.../AutomatizacionProtocoloTest.kt`: sesión válida, vacíos, límites (14 400 s, pulso 30–230, nombre 31), handshake completo y entrada maliciosa sin excepciones.

**Integración (11)**
- `aut04_integracion_api_test.dart` (4): `ApiClient` + `AuthRepository` + `CeosmosRepository` **reales** contra `test/support/servidor_api_local.dart` (`HttpServer` en 127.0.0.1): 201 registro, 401 sin verificar, 200 login con token guardado y `Authorization: Bearer`, 400 validación, 401 credenciales, 201/200 dispositivos, 404 al borrar uno ajeno (IDOR), 401 token revocado → aviso de cierre de sesión, 404 ruta inexistente.
- `aut05_servidor_sin_respuesta_test.dart` (2, widget): pantalla de acceso real; puerto cerrado → «No hay conexión con el servidor de CEOSMOS. Revisa tu red.»; servidor que acepta y no responde → «…tardó demasiado en responder…»; el botón vuelve a habilitarse.
- `aut06_persistencia_p04_test.dart` (5): base Floor generada sobre `sqflite_common_ffi` (mismo SQLite que Android): CRUD en memoria, id duplicado → `DatabaseException`, migración v1→v2 conserva el alumno previo (`correo = null`) y guarda el nuevo; sin la migración Floor se niega a abrir y no borra datos. *Adaptación:* la migración usa un archivo temporal porque una base `:memory:` no puede reabrirse en otra versión.

## 4. Pipeline CI (`.github/workflows/ci.yml`)
`push`, `pull_request` y manual. **Flutter**: checkout → `subosito/flutter-action` 3.41.9 con caché → `pub get` → `analyze` → `flutter test --coverage --file-reporter json` → JUnit (`junitreport`) → resumen en la página del run → artifacts `flutter-test-reports` y `flutter-coverage`. **Kotlin** (matriz Reloj, TV, Companion): Java 17 → caché de Gradle → `test<App>DebugUnitTest` → `lint<App>Debug` → artifact con JUnit XML, HTML y lint. Sin secretos; no hace falta `google-services.json` (el proyecto no aplica el plugin de Google Services). Falla si falla cualquier paso.

## 5. Resultados
| Ejecución | Ejecutadas | Aprobadas | Fallidas | Tiempo |
| --- | --- | --- | --- | --- |
| Local Flutter (`analyze` + `test --coverage`) | 215 | 215 | 0 | 42 s + 69 s |
| Local Kotlin (`test` 6 variantes + lint 3 apps) | 14 × 6 | 84 | 0 | 107 s |
| CI run #1 (push) · [44433685785](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433685785) | 215 + 14 × 3 | todas | 0 | 2 min 55 s |
| CI run #2 (PR) · [44433707000](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433707000) | 215 + 14 × 3 | todas | 0 | 2 min 36 s |
| CI run #3 (push corrección) · [44434252590](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434252590) | 215 + 14 × 3 | todas | 0 | 2 min 18 s |
| CI run #4 (PR corrección) · [44434260779](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434260779) | 215 + 14 × 3 | todas | 0 | 3 min 10 s |

Cobertura de líneas: 49.5 % del proyecto (incluye pantallas de las prácticas); en los componentes críticos: `api_client` 100 %, `ble_protocolo` 100 %, `ecosistema_ble` 94.4 %, `usuarios_page` 94.8 %, base Floor 91.8 %, `auth_repository` 86.9 %, `auth_screen` 83.0 % (`local_resumen_flutter.md`).

### Errores encontrados y correcciones
| # | Error | Causa | Corrección |
| --- | --- | --- | --- |
| E1 | Lint Android: 3 errores (`UnsupportedTvHardware`, `WrongConstant` en `notifyCharacteristicChanged`, `PropertyEscape`) | `bluetooth_le required=true` excluye televisores; la sobrecarga API 33 devuelve `BluetoothStatusCodes`, no `GATT_SUCCESS` (ambos valen 0); `local.properties` sin escapar | `required="false"` + `uses-feature bluetooth`; `BluetoothStatusCodes.SUCCESS`; `local.properties` escapado (solo local, no se versiona) |
| E2 | `Bluetooth apagado: …reconecta solo` falló 1 de 215 en la suite completa con cobertura | Espera fija de 100 ms; bajo carga la reconexión tardó más | Espera por condición (`esperarHasta`, máx. 3 s) en las 4 pruebas BLE positivas |
| E3 | `companion/gradlew` sin permiso de ejecución en git | Repo creado en Windows (modo 100644): en Linux «Permission denied» | `git update-index --chmod=+x` y `chmod +x` en el workflow |
| E4 | Runs #1–#2: avisos «Node.js 20 is deprecated» y «setup-java v4 is deprecated» | Acciones v4 | Acciones a v5 (run #3–#4) y `upload-artifact` a v6 (último push) |
| E5 | El historial contenía un `JWT_SECRET` y la contraseña de Neon en una nota histórica | Copia de una auditoría antigua | Redactado en todo el historial antes de publicar (respaldo `.bundle` local) |

## 6. Matriz de automatización
| ID | Tipo | Componente / prueba | Archivo | Resultado esperado | Resultado obtenido | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| AUT-01 | Unitarias | Validación de acceso, P4 y mensajes BLE con entradas válidas y vacías/nulas | `test/p13_14/aut01_03_unitarias_test.dart` (grupo AUT-01, 4) | Válidas sin error; vacías/null con el mensaje de campo obligatorio, sin excepción | 4/4 aprobadas | Aprobado |
| AUT-02 | Unitarias | Límites (contraseña 7/8/72/73, usuario, código, edad 0/1/120/121, pulso 29/30/230/231), vector HMAC Dart = Kotlin, recorte 180 B, API local por defecto | ídem (grupo AUT-02, 7) + `AutomatizacionProtocoloTest.kt` (5) | Fuera de rango rechazado; resultados exactos | 7/7 Dart, 5/5 Kotlin | Aprobado |
| AUT-03 | Unitarias / regresión | Excepciones (PIN/reto, basura, mensaje imposible, errores HTTP) y DEF-BLE-01 | grupo AUT-03 (4) + `aut03_regresion_tv_reiniciada_test.dart` | Excepciones controladas; la regresión falla con el código viejo y pasa con el nuevo | 4/4; viejo FALLA, nuevo PASA | Aprobado |
| AUT-04 | Integración | Cliente HTTP real ↔ servidor local: 200/201/400/401/404 e IDOR | `aut04_integracion_api_test.dart` (4) | Códigos y cuerpos esperados, token y cabeceras correctos | 4/4 aprobadas | Aprobado |
| AUT-05 | Integración (widget) | Sin servidor: conexión rechazada y tiempo límite → texto en pantalla | `aut05_servidor_sin_respuesta_test.dart` (2) | Mensaje de red/tiempo; botón habilitado; sin sesión | 2/2 aprobadas | Aprobado |
| AUT-06 | Persistencia | P4 en SQLite (FFI): CRUD en memoria, duplicado, migración v1→v2 | `aut06_persistencia_p04_test.dart` (5) | Datos releídos iguales; migración sin pérdida | 5/5 aprobadas | Aprobado |
| AUT-07 | CI | Workflow en push | `.github/workflows/ci.yml` · run #1 | 4 jobs en verde | Éxito, 2 min 55 s | Aprobado |
| AUT-08 | CI | Workflow en PR y en el nuevo push tras la corrección | runs #2, #3, #4 | Verde en PR y tras la corrección | Éxito: 2 min 36 s, 2 min 18 s, 3 min 10 s | Aprobado |

## 7. Evidencias (esta carpeta)
`local_flutter_analyze.txt`, `local_flutter_test.txt`, `local_resumen_flutter.md`, `local_kotlin.txt`, `local_kotlin_lint_antes.txt`, `regresion_codigo_viejo.txt`, `regresion_codigo_nuevo.txt`, `ci_run_<id>.log` (logs completos de cada run), `ci_01_actions_lista_verde.jpg`, `ci_02_run3_push_verde.jpg`.

## 8. Conclusión
Cada push y cada PR ejecutan en menos de 4 minutos 215 pruebas de Flutter, 42 de Kotlin (14 por app), el análisis estático y el lint de las tres apps, sin tocar producción y sin secretos. Un cambio que reintroduzca DEF-BLE-01, rompa la migración de la P4, cambie un código HTTP o desincronice el HMAC entre Dart y Kotlin deja el PR en rojo antes de llegar a los dispositivos. El primer uso ya dio resultado: el lint encontró 3 errores reales del companion y la suite con cobertura destapó una prueba que dependía del tiempo.
