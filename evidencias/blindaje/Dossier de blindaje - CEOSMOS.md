# Dossier de blindaje · CEOSMOS Integral

Versión de entrega `entrega-v1` · 21/11/2026 · Samsung Galaxy S24 (Android 17) y Galaxy Tab S9 (Android 16).

Regla de este documento: lo **medido** se distingue de lo **inferido**, y lo que no se hizo se dice. Las etapas 1 (usabilidad con usuarios y conectividad) y 2 (seguridad ampliada) del plan de blindaje **no se ejecutaron**. Sus apartados aquí recogen solo evidencia previa o de la etapa 3, y lo faltante queda listado en §6.

## 1. Resumen ejecutivo y alcance

CEOSMOS Integral es una app Flutter de concentración, calma e inspiración conectada a su API (NestJS + PostgreSQL en Vercel/Neon), con Reloj y TV compañeros por BLE y funciones de soporte, reportes, mensajería y herramientas derivadas de las prácticas del curso. Cada función conserva su propia base de datos.

**Alcance de la etapa 3 (cierre):** pasada final de regresión en el código de entrega, prueba de «usuario torpe» dentro de la app, prueba de ventana flotante para hallar el tamaño mínimo funcional, Red Box de la API, comprobación de la API de producción, APK de release firmado con llave propia, plan de contingencia ensayado y documentación de defensa.

| Indicador | Resultado | Tipo |
|---|---|---|
| Pruebas de Flutter | **217/217** (`flutter test`), análisis estático sin avisos | medido |
| Pruebas de Kotlin | Reloj, TV y Companion: 14/14 por app más lint sin errores | medido |
| Cobertura de líneas (toda `lib/`) | **52.9 %** (3 074 / 5 814); núcleo `core`/`data`/`domain` 78.9 % (P11) | medido |
| Usuario torpe dentro de la app | en ejecución al cierre de esta sesión: resultado en `evidencias/blindaje/mono/` | medido |
| Red Box de la API (local) | **13/13** ataques bloqueados | medido |
| Tamaño mínimo funcional (ventana flotante) | **320 × 560 dp** | medido |
| Ensayo de arreglo en 20 minutos | 3 fallos detectados por las pruebas; ciclo de 1.9–2.4 min por fallo | medido |
| CI (GitHub Actions) | Verde en cada push: análisis, 217 pruebas, 3 apps Kotlin | medido |

## 2. Usabilidad

**Método (etapa 3):**
1. Prueba automatizada de «usuario torpe» dentro de la app (`integration_test/mono_usuario_test.dart`): toques, texto inválido, Atrás y desplazamientos al azar sobre los widgets de CEOSMOS, con la API simulada. Sustituye a `adb monkey`, que se descartó porque inyecta eventos al sistema: bajó la barra de notificaciones, cambió el brillo y bloqueó el teléfono.
2. Ventana flotante redimensionada en la Tab S9 (`am task resize`) para hallar el tamaño mínimo funcional.
3. Recorrido manual como usuario novato en los dos equipos, en modo claro y oscuro.

**Hallazgos y correcciones:**

| Hallazgo | Dónde | Corrección | Prueba |
|---|---|---|---|
| Con 280 dp de ancho el encabezado se desborda y el avatar queda cortado | Encabezado principal | Marca compacta (solo ícono) bajo 340 dp | `widget_test.dart`: sin desbordes a 280 px |
| A 280 dp la etiqueta de estado del Reloj y la TV se desborda | Equipos › tarjeta BLE | Etiqueta flexible | Misma prueba |
| El botón «Siguiente ▶» de la TV se parte en tres líneas | App TV (tablet) | Botones en `FlowRow` y texto en una sola línea | Revisión en la tablet |
| Las tarjetas de las pantallas nativas salen gris neutro en modo oscuro | Incidencias en tiempo real / Mis incidencias | Tonos `surfaceContainer*` en el tema nativo | Captura en la tablet |
| Se veían identificadores internos con sufijos de práctica | Encabezado y pantallas nativas | Nombres visibles sin el sufijo; las consultas no cambian | Revisión en los equipos |

**Ventana flotante (Tab S9, densidad 300 dpi; medido):**

| Tamaño (dp) | ¿Funcional? | Observación |
|---|---|---|
| 900 × 700 | sí | La tablet la limita a su ancho vertical |
| 600 × 800 | sí | Diseño de teléfono completo |
| 412 × 780 | sí | Igual que el S24 |
| 360 × 640 | sí | Todo legible y tocable |
| **320 × 560** | **sí (mínimo)** | Encabezado justo; todas las pestañas usables |
| 280 × 500 | parcial → corregido | Encabezado desbordado; se corrigió con la marca compacta |
| 240 × 420 | no | Los títulos se parten letra por letra; queda poco contenido visible |

Capturas: `evidencias/blindaje/ventana/` y `evidencias/reestructura/dispositivos/`.

## 3. Funcionalidad: matriz de escenarios

| # | Escenario | Equipo(s) | Resultado |
|---|---|---|---|
| F-01 | Inicio de sesión con la cuenta QA y sincronización | S24 | aprobado (recorrido) |
| F-02 | Validación de campos en Acceso (vacíos, correo inválido) | prueba automática | aprobado |
| F-03 | Sesión de enfoque: iniciar, pausar, continuar y terminar | prueba automática | aprobado |
| F-04 | Soporte como administrador: menú de asignados, todos y dispositivos; ⓘ; Atrás | S24 | aprobado (21/11) |
| F-05 | Soporte con el agente y los dos usuarios | — | **pendiente** (requiere las contraseñas del usuario) |
| F-06 | Incidencias en tiempo real: alta en la tablet visible al instante en el S24 | S24 + Tab S9 | aprobado (21/11) |
| F-07 | Reportes compartidos (Flutter y Android) conectados a la nube | S24 | aprobado |
| F-08 | Mis incidencias y acceso: solo lo propio | S24 | aprobado |
| F-09 | Mensajería entre equipos por Wi-Fi | S24 → Tab S9 | aprobado (21/11) |
| F-10 | Reloj y TV conectados a la vez por BLE, con lecturas en vivo | S24 + Tab S9 | aprobado (con un reintento por error transitorio de GATT) |
| F-11 | Seguridad de la cuenta, Directorio de alumnos y Citas de bienestar abren desde Perfil | S24 | aprobado |
| F-12 | Ningún texto visible contiene «Práctica», «P» + número, «Examen» ni «Eval.» | prueba automática | aprobado (`navegacion_funciones_test.dart`) |
| F-13 | Atrás vuelve a la sección y no cierra la app (Android 16/17) | prueba + equipos | aprobado |
| F-14 | Registro de una cuenta nueva | — | no ejecutado en producción: requiere recibir el código por correo; cubierto por pruebas con la API simulada |

## 4. Conectividad

**Inventario de servicios:**

| Servicio | Uso | Ubicación | Protocolo |
|---|---|---|---|
| API de CEOSMOS (`ceosmos-api.vercel.app`) | Cuenta, sesiones, favoritos, dispositivos, biblioteca y administración | Vercel, región `iad1` (EE. UU. Este); base Neon | HTTPS + HSTS |
| Firestore `practica7-8` | Tickets y chat interno | Google Cloud | HTTPS/gRPC |
| Firestore `reportes-movil` | Reportes compartidos (Flutter y Android) | Google Cloud | HTTPS/gRPC |
| Firestore `mesaayuda` | Incidencias en tiempo real y Mis incidencias | Google Cloud | HTTPS/gRPC |
| BLE GATT | Reloj y TV | Local (unos metros) | BLE con reto + HMAC |
| TCP 5000 | Mensajería entre equipos | Misma red Wi-Fi | TCP en texto plano en LAN |
| API de citas (`localhost:3443`) | Citas de bienestar | Computadora del alumno, por `adb reverse` | HTTPS con certificado fijado |

**Medido:**
- API de producción desde México (21/11): `/health` responde 200. Conexión de 35–113 ms y total de 0.21–0.34 s; un pico de 1.76 s en arranque en frío. HTTP plano → 308. Sin token → 401.
- Carga inicial en el S24 (P11): 984 ms.
- Saturación de la API local (P12): ~5 usuarios concurrentes, ~210 solicitudes/s y sin errores; después la latencia crece de forma lineal.

**Inferido (no medido):**
- **España y Europa:** funciona. No hay restricción por país en Vercel ni en Firebase, pero la API está en EE. UU. Este, así que se esperan unos 90–120 ms de ida y vuelta (hoy ~35 ms desde México). Firestore elige su región al crear el proyecto; no se verificó cuál es.
- **Otros continentes:** Asia y Oceanía tendrían de 150 a 250 ms de ida y vuelta hacia `iad1`. La app lo tolera (timeout de 15 s y reintentos), pero la carga inicial sería más lenta.
- **Red mínima:** no se midió con limitación de ancho de banda. La respuesta más pesada (historial de 50 sesiones) es de 24–28 KB, así que en teoría alcanza con una red 3G.

**Ante caídas (medido en pruebas):** aviso «Sin conexión», reintento con espera progresiva, escrituras idempotentes (`clientId`) sin duplicados y reconexión BLE automática. Las funciones con Firestore sincronizan al volver la red (prueba de la tablet sin red en P9).

## 5. Seguridad

**Mapa MASVS / OWASP Mobile Top 10 (2024):**

| Riesgo | Estado | Evidencia |
|---|---|---|
| M1 Credenciales mal usadas | Mitigado: no hay credenciales de servidor en la app; las claves de Firebase son de cliente y están restringidas por paquete + SHA (excepto `mesaayuda`) | Nota 07 |
| M3 Autenticación y autorización | Mitigado: JWT, roles USER/ADMIN, IDOR → 404, USER en `/admin` → 403 y reglas de Firestore por propietario | Red Box 13/13 |
| M4 Validación de entradas | Mitigado: validación en la app y en la API (DTO + CHECK en la BD); inyección SQL → 401/400 | Red Box RB-04, RB-08, RB-09 |
| M5 Comunicación insegura | Mitigado: HTTPS + HSTS y texto claro solo a localhost. La mensajería en LAN va en texto plano (aceptado, §6) | `network_security_config.xml` |
| M8 Configuración incorrecta | Mitigado: release no depurable, `allowBackup=false` y solo las actividades necesarias exportadas | Nota 07 |
| M9 Almacenamiento inseguro | Mitigado: token en almacenamiento seguro (Keystore) y nada sensible en los registros | `token_store.dart` |
| M2, M6, M7, M10 | No evaluados a fondo (cadena de suministro, privacidad, protección binaria, criptografía) | §6 |

**Cifrado:** en tránsito, TLS en la API y en Firestore. En reposo, Keystore para el token; SQLite y SharedPreferences sin cifrar porque solo guardan datos de práctica. En BLE no hay cifrado del enlace: la integridad se protege con reto + HMAC y no se envía el PIN.

**Ataques (medido el 21/11 con `scripts/redbox_api.sh` contra la API local):** 13/13 bloqueados (`evidencias/blindaje/redbox_api_entrega.txt`). Antes (P10 y P7) ya se habían probado el acceso ajeno en Firestore y las escrituras BLE no autenticadas.

**Dependencias y secretos:** no hay secretos de servidor en el repositorio. El keystore de release queda fuera del repositorio (`C:\CESAR10cuatri\llaves\`) y `key.properties` está en `.gitignore`. 67 paquetes tienen versiones más nuevas que no son compatibles con las restricciones actuales; no se hizo un análisis de vulnerabilidades de dependencias.

## 6. Límites conocidos y riesgos aceptados

| Límite o riesgo | Impacto | Mitigación / estado |
|---|---|---|
| Etapas 1 y 2 del blindaje no ejecutadas (usabilidad con personas, red mínima por API, tabla por continente medida, Red Box ampliado, MASVS completo) | La defensa en esas áreas se apoya en evidencia previa e inferencias | Ejecutarlas si da tiempo; aquí se separa lo inferido |
| El «usuario torpe» no entra a las funciones con nube (Soporte, Reportes, Citas) | Esas pantallas no reciben acciones al azar | Se excluyeron a propósito para no tocar datos reales; cubiertas por el recorrido manual |
| La app instalada en los teléfonos se firma con la llave de depuración | Cualquiera con esa llave podría firmar una actualización | Hay un APK firmado con llave propia en `release/`; instalarlo exige desinstalar (se pierden datos locales), así que se dejó para después de la evaluación |
| Rotación de `JWT_SECRET` y de la contraseña de Neon pendiente | Credenciales que estuvieron expuestas siguen vigentes | Tarea del usuario (08 - Pendientes) |
| Clave de Firebase de `mesaayuda` sin restringir | Uso de la cuota por terceros | Restringir por paquete + SHA (tarea del usuario) |
| Limitador de la API en memoria por instancia | En Vercel cada instancia cuenta por su lado | Upstash Redis (mejora futura) |
| Mensajería entre equipos en texto plano en la LAN | Otra persona en la misma Wi-Fi podría leerla | Aceptado: es solo de demostración y en red local |
| BLE sin bonding cifrado | Se podría escuchar el tráfico de lecturas | Integridad con HMAC; LE Secure Connections como mejora |
| Errores transitorios de GATT (`ANDROID_SPECIFIC_ERROR`) | La primera conexión a veces falla | Reintento manual o automático; documentado en la guía |

## 7. Pruebas

| Conjunto | Cantidad | Cómo reproducir |
|---|---|---|
| Flutter (unidad, widgets, caja negra y blanca, BLE, funciones, CI) | 217 | `flutter test` |
| Cobertura | 52.9 % de líneas (núcleo 78.9 %) | `flutter test --coverage` |
| Kotlin (Reloj, TV, Companion) | 14 por app más lint | `cd companion; ./gradlew test lint` |
| Usuario torpe en el teléfono | 20 000 acciones por equipo | `flutter test integration_test/mono_usuario_test.dart -d <serial>` |
| Red Box de la API | 13 | `scripts\dev_backend.ps1` y luego `bash scripts/redbox_api.sh` |
| Sin texto académico visible | 1 recorrido | `flutter test test/navegacion_funciones_test.dart` |
| CI | Cada push y pull request | GitHub Actions `CI` (sin secretos ni producción) |

## 8. Plan de contingencia

- **Script:** `scripts/arreglo_rapido.sh <área>` (o `.ps1`). Ejecuta el análisis y las pruebas del área, compila en modo debug, instala en los dos equipos sin borrar datos y muestra el logcat de la app, cronometrando cada paso.
- **Volver atrás:** `git checkout entrega-v1`, o reinstalar `release\CEOSMOS-entrega-v1-release-llave-depuracion.apk` (se instala encima sin perder datos).
- **Guía de fallos:** `evidencias/blindaje/Guia de fallos rapidos.md`.
- **Lista previa:** `evidencias/blindaje/Lista de verificacion previa.md`.

**Ensayo cronometrado (21/11, Tab S9, medido):**

| Fallo simulado | Área del script | ¿Lo detectaron las pruebas? | Detección (análisis + pruebas) | Verificación (análisis, pruebas, build, instalación, logcat) | Ciclo completo |
|---|---|---|---|---|---|
| F1 · campo de correo sin validar | `login` | sí (análisis y 1 prueba) | 20 s | 125 s | 2.4 min |
| F2 · timeout del cliente de la API en 1 ms | `red` | sí | 22 s | 92 s | 1.9 min |
| F3 · permiso de Bluetooth mal manejado | `ble` | sí | 26 s | 86 s | 1.9 min |

El ciclo medido no incluye el tiempo humano de escribir el arreglo: en el ensayo, la corrección fue restaurar el código. Con 2 minutos por ciclo quedan unos 15 minutos para diagnosticar y escribir el cambio dentro del margen de 20. Detalle en `evidencias/blindaje/ensayo/`. El código quedó idéntico al terminar (verificado con `git diff`).
