# Dossier de blindaje · CEOSMOS Integral

Versión de entrega `entrega-v2` · 22/11/2026 (actualiza la del 21/11) · Samsung Galaxy S24 (Android 17) y Galaxy Tab S9 (Android 16).

Regla de este documento: lo **medido** se distingue de lo **inferido**, y lo que no se hizo se dice. El 22/11 se ejecutaron las partes medibles de las etapas 1 y 2: robustez, accesibilidad, barrido de tamaños, red mínima, geografía, Red Box ampliado, secretos y mapa MASVS. Lo que sigue sin hacer está en §6.

**Novedades del 22/11 (todas con prueba de regresión):** manejo global de errores con aviso amigable; áreas táctiles de 48 dp y fuente al 200 % sin desbordes; barra lateral desplazable en ventanas anchas y bajas; diálogo «Agregar a mi biblioteca» desplazable y confirmación antes de borrar (los dos hallados por el usuario torpe en la tablet); mensaje claro ante un certificado no confiable; 6 correcciones de seguridad en la API (rama `blindaje-api`, pendiente de promover a producción).

## 1. Resumen ejecutivo y alcance

CEOSMOS Integral es una app Flutter de concentración, calma e inspiración conectada a su API (NestJS + PostgreSQL en Vercel/Neon), con Reloj y TV compañeros por BLE y funciones de soporte, reportes, mensajería y herramientas derivadas de las prácticas del curso. Cada función conserva su propia base de datos.

**Alcance de la etapa 3 (cierre):** pasada final de regresión en el código de entrega, prueba de «usuario torpe» dentro de la app, prueba de ventana flotante para hallar el tamaño mínimo funcional, Red Box de la API, comprobación de la API de producción, APK de release firmado con llave propia, plan de contingencia ensayado y documentación de defensa.

| Indicador | Resultado | Tipo |
|---|---|---|
| Pruebas de Flutter | **319/319** (`flutter test`; 217 el 21/11 + barrido de 91 tamaños, accesibilidad, errores, TLS, doble toque y biblioteca), análisis estático sin avisos | medido |
| Pruebas de Kotlin | Reloj, TV y Companion: 14/14 por app más lint sin errores | medido |
| Cobertura de líneas (toda `lib/`) | **52.9 %** (3 074 / 5 814, medida el 21/11); núcleo `core`/`data`/`domain` 78.9 % (P11) | medido |
| Usuario torpe dentro de la app | S24: 5 000 acciones, 0 errores, 0 crashes, 0 ANR. Tab S9: 5 000 acciones, 0 crashes, 0 ANR, 4 desbordes → corregidos y verificados (2 100 acciones con la misma semilla, 0 errores) | medido |
| Red Box de la API (local) | **13/13** + ampliado **37/37** (27/37 antes de corregir la API) | medido |
| Red mínima | API: 5 kbps o RTT 4 s dentro del timeout de 15 s; Firebase: 5 kbps, falla con RTT 4 s | medido |
| Geografía | API 200 desde los 6 continentes; Madrid 373 ms | medido |
| Tamaño mínimo funcional | Barrido: sin desbordes desde **240 dp** de ancho (91 tamaños). Ventana flotante real: cómodo desde **260 × 440 dp**, sin errores hasta 220 × 380 dp | medido |
| Ensayo de arreglo en 20 minutos | 3 fallos detectados por las pruebas; ciclo de 1.9–2.4 min por fallo | medido |
| CI (GitHub Actions) | Verde en cada push: análisis, todas las pruebas de Flutter, 3 apps Kotlin | medido |

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
| Avatar del encabezado con área táctil de 36 dp | Encabezado | Área de 48 × 48 dp | `accesibilidad_test.dart` |
| Con la fuente del sistema al 200 % el encabezado se desborda 20 px | Encabezado | Marca flexible | `accesibilidad_test.dart` |
| Ventana ancha y baja (≥ 920 × < 760 dp): la barra lateral se desborda hasta 441 px | Barra lateral | Barra desplazable | `tamanos_pantalla_test.dart` (91 tamaños) |
| Diálogo «Agregar a mi biblioteca» se desborda 9–75 px con teclado y errores (usuario torpe, Tab S9) | Explorar › Mi biblioteca | Contenido desplazable | `biblioteca_dialogo_test.dart` + misma semilla en la tablet: 0 errores |
| Borrar de la biblioteca no pedía confirmación | Explorar › Mi biblioteca | Diálogo «¿Eliminar de tu biblioteca?» | `biblioteca_dialogo_test.dart` |
| Un error inesperado podía mostrar la pantalla roja o gris | Toda la app | Manejo global y aviso amigable | `errores_globales_test.dart` |

**Barrido de tamaños (22/11, automático, Acceso + 6 pestañas por tamaño):** 13 anchos (200–1600 dp) × 7 altos (320–1000 dp). Sin desbordes desde 240 dp de ancho en todos los altos; con 200 dp se desbordan Inicio y Perfil (fuera del mínimo). Tabla: `evidencias/blindaje/ventana/barrido_tamanos.md`.

**Ventana flotante real (22/11, Tab S9, release v2, pantalla de Acceso, 14 tamaños):** sin recortes ni errores en ninguno; dos columnas desde 900 × 700; en apaisadas bajas (500 × 300) el formulario queda bajo el pliegue y se alcanza desplazando; cómodo desde 260 × 440 dp. Hoja de contacto: `evidencias/blindaje/ventana/v2/`. No verificado en el equipo: las pestañas con sesión en ventana flotante (cubiertas por el barrido automático).

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

**Red mínima (medido el 22/11 contra producción con un proxy que degrada la red; detalle en `evidencias/blindaje/red/red_minima.md`):**

| Perfil | API CEOSMOS | Firestore | Firebase Auth |
|---|---|---|---|
| 4G (RTT +50 ms · 10 Mbps) | 0.42–0.45 s | 0.70 s | 0.32 s |
| 3G (RTT +200 ms · 750 kbps) | 0.93–0.95 s | 1.08–1.19 s | 0.80 s |
| EDGE/2G (RTT +400 ms · 50 kbps) | 2.46–2.48 s | 2.35–2.41 s | 2.31 s |
| 3G + 5 % / 20 % de pérdida (emulada) | ≤ 2.0 s / ≤ 4.95 s | ≤ 3.1 s / ≤ 4.0 s | 1.8 s / 2.8 s |
| 3G con corte cada 3 s | 0.93 s | 0.88–1.04 s | 0.81 s |
| RTT 4 s | **12.4 s (responde)** | **falla a los 10 s** | **falla a los 10 s** |
| 5 kbps | **11.4 s** | **9.7–9.8 s** | **10.6 s** |

Mínimos: API, 5 kbps o RTT de 4 s dentro del timeout de 15 s (para el historial de 24–28 KB hacen falta ≈ 20 kbps, **calculado**). Firebase, 5 kbps y RTT por debajo de 4 s (Google corta el saludo TLS a los ~10 s). Por debajo del mínimo: la API muestra «El servidor de CEOSMOS tardó demasiado en responder. Intenta de nuevo.» y las sesiones se reenvían sin duplicar; Firestore sigue con la caché local y sincroniza al volver la red.

**Geografía (medido el 22/11 con sondas públicas de Globalping; detalle en `evidencias/blindaje/red/geografia.md`):**

| Continente | API `/api/health` | Firestore | ¿Funciona? |
|---|---|---|---|
| Norteamérica (Los Ángeles, Búfalo) | 200 · 137–258 ms | 304 ms | sí |
| Sudamérica (São Paulo, Campinas) | 200 · 337–379 ms | 973 ms | sí |
| **Europa: España (Madrid, Logroño)** | **200 · 373–400 ms** | **783 ms** | **sí** |
| Europa (Helsinki) | 200 · 396 ms | — | sí |
| Asia (Singapur, Tokio) | 200 · 572–697 ms | 238 ms | sí |
| África (Lagos, Johannesburgo) | 200 · 652–763 ms | 2 068 ms | sí |
| Oceanía (Sídney) | 200 · 561–566 ms | 438 ms | sí |

Regiones: Vercel `iad1` (medido) y Neon `us-east-1` (medido en el `.env` local; que producción use el mismo host es inferido). La región de Firestore **no se verificó**. La API solo publica IPv4 (en redes solo IPv6 Android usa 464XLAT, **inferido**). Para usuarios reales en la UE faltaría el aviso RGPD; no es un bloqueo técnico.

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
| M2, M6, M7, M10 | Parcial o riesgo aceptado (sin escáner de CVE, datos en EE. UU., sin ofuscación, BLE sin cifrado de carga útil) | `evidencias/blindaje/masvs.md` |

El mapa completo control por control (MASVS v2 y Top 10) está en `evidencias/blindaje/masvs.md`.

**Red Box ampliado (22/11, `scripts/redbox_ampliado.sh`, API local con un secreto JWT de prueba desechable):** tokens expirados, de usuario inexistente, con HS512, con rol inventado, Basic y vacíos; inyección NoSQL y SQL, tipos erróneos, JSON malformado y anidado, XSS almacenado, `javascript:` en medios, asignación masiva, títulos de 100 000 caracteres, IDOR en tareas, métodos TRACE/PUT, CORS, cabeceras, trazas en errores, enumeración de usuarios, fuerza bruta y reutilización tras logout. **Primera pasada: 27/37. Tras corregir la API: 37/37**, y el Red Box original sigue en 13/13.

| Hallazgo | ¿También en producción? | Corrección |
|---|---|---|
| Token firmado con otra carga útil o HS512 → 500 | solo con el secreto (inferido) | Solo HS256 y forma validada → 401 |
| CORS con origen ajeno → 500 | **sí (medido)** | Sin cabeceras CORS, sin 500 |
| JSON anidado 5 000 niveles sin sesión → 500 | **sí (medido)** | 400 |
| Sin Content-Security-Policy | **sí (medido)** | `default-src 'none'; frame-ancestors 'none'` |
| Medio IMAGE aceptaba `javascript:` | inferido | Solo https y longitudes acotadas |
| El login revelaba si la cuenta existe | inferido | Mismo mensaje siempre |
| Certificado no confiable → excepción cruda en la app | — | Mensaje claro (`tls_rechazo_test.dart`) |

Las 6 correcciones de la API están en la rama `blindaje-api` (repo CEOSMOSV2, commit `605776c`): 79/79 pruebas, el preview de Vercel compiló en verde, pero está protegido con el inicio de sesión de Vercel y **no se pudo probar**. **Producción aún no las tiene.** Rollback: volver a promover el despliegue anterior (`a4d8d6a`).

**Firestore sin sesión (22/11, medido):** lecturas y escrituras rechazadas (403) en `practica7-8` y `reportes-movil`; en `mesaayuda-p7`, `turnos` y `contadores` dan 403, pero **`dispositivos` se lee sin sesión** (3 documentos de presencia: nombre, modelo, rol y última conexión). La regla la debe ajustar el usuario en la consola de Firebase.

**Interceptación:** la app no confía en CA de usuario y rechaza un certificado autofirmado (prueba con un servidor HTTPS local). No se usó mitmproxy en el teléfono porque exige cambiar el proxy del sistema.

**Cifrado:** en tránsito, TLS en la API y en Firestore. En reposo, Keystore para el token; SQLite y SharedPreferences sin cifrar porque solo guardan datos de práctica. En BLE no hay cifrado del enlace: la integridad se protege con reto + HMAC y no se envía el PIN.

**Ataques (medido el 21/11 con `scripts/redbox_api.sh` contra la API local):** 13/13 bloqueados (`evidencias/blindaje/redbox_api_entrega.txt`). Antes (P10 y P7) ya se habían probado el acceso ajeno en Firestore y las escrituras BLE no autenticadas.

**Dependencias y secretos:** gitleaks 8.30.1 sobre los 33 commits del historial y el árbol de trabajo (22/11; `evidencias/blindaje/secretos_gitleaks.txt`, con los valores ocultos). En el historial hay 19 coincidencias: 7 claves de cliente de Firebase (públicas por diseño) y 12 tokens de sesión de la base local de P12 dentro de planes EXPLAIN (no son de producción). No hay contraseñas, JWT_SECRET, llaves ni `key.properties` en el historial. El keystore queda fuera del repositorio. 67 paquetes tienen versiones nuevas incompatibles; no se usó un escáner de CVE (riesgo aceptado).

## 6. Límites conocidos y riesgos aceptados

| Límite o riesgo | Impacto | Mitigación / estado |
|---|---|---|
| Correcciones de la API sin promover a producción | Producción sigue respondiendo 500 a CORS ajeno y JSON anidado, y sin CSP | Rama `blindaje-api` lista (79/79, 37/37); promover en Vercel (tarea del usuario) |
| `mesaayuda-p7/dispositivos` legible sin sesión | Se ven 3 registros de presencia (nombre, modelo, rol, última conexión) | Exigir `request.auth != null` en la regla (tarea del usuario) |
| Usuario torpe: 5 000 acciones por equipo, no 20 000 | Menos cobertura aleatoria que la planeada | El S24 se quedó sin batería; el usuario decidió no repetir lo ya probado. Los hallazgos de la tablet se corrigieron y se verificaron con la misma semilla |
| Usabilidad con personas reales y recorrido con sesión en el equipo | Sin datos de usuarios reales; el recorrido con sesión del 22/11 no se hizo (la tablet estaba en Acceso y no se usaron credenciales) | Barrido automático, accesibilidad y usuario torpe; recorrido manual del 21/11 |
| El «usuario torpe» no entra a las funciones con nube (Soporte, Reportes, Citas) | Esas pantallas no reciben acciones al azar | Se excluyeron a propósito para no tocar datos reales; cubiertas por el recorrido manual |
| La entrega usa el APK firmado con la llave de depuración | Cualquiera con esa llave podría firmar una actualización | El APK con llave propia está listo (`release/CEOSMOS-entrega-v1-release.apk`), pero requiere registrar su SHA-1 en Firebase e instalarlo exige desinstalar (se pierden datos). Riesgo aceptado: decisión pendiente del usuario |
| SQLite y SharedPreferences sin cifrar | Datos de funciones legibles con acceso root | No guardan credenciales; el token está en el Keystore |
| Sin ofuscación ni detección de root | Ingeniería inversa más fácil | Dart se compila AOT a código nativo; aceptado para una app académica |
| Rotación de `JWT_SECRET` y de la contraseña de Neon pendiente | Credenciales que estuvieron expuestas siguen vigentes | Tarea del usuario (08 - Pendientes) |
| Clave de Firebase de `mesaayuda` sin restringir | Uso de la cuota por terceros | Restringir por paquete + SHA (tarea del usuario) |
| Limitador de la API en memoria por instancia | En Vercel cada instancia cuenta por su lado | Upstash Redis (mejora futura) |
| Mensajería entre equipos en texto plano en la LAN | Otra persona en la misma Wi-Fi podría leerla | Aceptado: es solo de demostración y en red local |
| BLE: autenticación con reto + HMAC y PIN que nunca viaja; la carga útil no va cifrada | Se podría escuchar el tráfico de lecturas (pulso, pasos, estado de la TV) a pocos metros | Riesgo aceptado: el cifrado AES-256-GCM no se hizo porque tocaba las 3 apps a la vez justo antes de la entrega |
| Errores transitorios de GATT (`ANDROID_SPECIFIC_ERROR`) | La primera conexión a veces falla | Reintento manual o automático; documentado en la guía |

## 7. Pruebas

| Conjunto | Cantidad | Cómo reproducir |
|---|---|---|
| Flutter (unidad, widgets, caja negra y blanca, BLE, funciones, accesibilidad, tamaños, TLS, CI) | 319 | `flutter test` |
| Cobertura | 52.9 % de líneas (núcleo 78.9 %), medida el 21/11 | `flutter test --coverage` |
| Kotlin (Reloj, TV, Companion) | 14 por app más lint | `cd companion; ./gradlew test lint` |
| Usuario torpe en el teléfono | 5 000 acciones por equipo + verificación de 2 100 en la tablet | `powershell -File scripts\mono_bloques.ps1 -Serial <serial>` (copia aislada `.monkey`) |
| Red Box de la API | 13 + 37 ampliado | `scripts\dev_backend.ps1`, luego `bash scripts/redbox_api.sh` y `bash scripts/redbox_ampliado.sh` |
| API (Jest) | 79 | `npx jest` en `ceosmos-api` |
| Red mínima | 65 mediciones | `bash scripts/medir_red.sh` |
| Sin texto académico visible | 1 recorrido | `flutter test test/navegacion_funciones_test.dart` |
| CI | Cada push y pull request | GitHub Actions `CI` (sin secretos ni producción) |

## 8. Plan de contingencia

- **Script:** `scripts/arreglo_rapido.sh <área>` (o `.ps1`). Ejecuta el análisis y las pruebas del área, compila en modo debug, instala en los dos equipos sin borrar datos y muestra el logcat de la app, cronometrando cada paso.
- **Volver atrás:** `git checkout entrega-v2` (o `entrega-v1`), o reinstalar `release\CEOSMOS-entrega-v2-release-llave-depuracion.apk` (se instala encima sin perder datos; misma firma que la v1).
- **Guía de fallos:** `evidencias/blindaje/Guia de fallos rapidos.md`.
- **Lista previa:** `evidencias/blindaje/Lista de verificacion previa.md`.

**Ensayo cronometrado (21/11, Tab S9, medido):**

| Fallo simulado | Área del script | ¿Lo detectaron las pruebas? | Detección (análisis + pruebas) | Verificación (análisis, pruebas, build, instalación, logcat) | Ciclo completo |
|---|---|---|---|---|---|
| F1 · campo de correo sin validar | `login` | sí (análisis y 1 prueba) | 20 s | 125 s | 2.4 min |
| F2 · timeout del cliente de la API en 1 ms | `red` | sí | 22 s | 92 s | 1.9 min |
| F3 · permiso de Bluetooth mal manejado | `ble` | sí | 26 s | 86 s | 1.9 min |

El ciclo medido no incluye el tiempo humano de escribir el arreglo: en el ensayo, la corrección fue restaurar el código. Con 2 minutos por ciclo quedan unos 15 minutos para diagnosticar y escribir el cambio dentro del margen de 20. Detalle en `evidencias/blindaje/ensayo/`. El código quedó idéntico al terminar (verificado con `git diff`).
