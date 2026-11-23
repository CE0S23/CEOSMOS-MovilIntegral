# Dossier de blindaje · CEOSMOS Integral

Versión de entrega `entrega-v4` (app 1.2.1) · 22/11/2026, cierre final (actualiza la del 21/11) · Samsung Galaxy S24 (Android 17) y Galaxy Tab S9 (Android 16).

Regla de este documento: lo **medido** se distingue de lo **inferido**, y lo que no se hizo se dice. El 22/11 se ejecutaron las partes medibles de las etapas 1 y 2: robustez, accesibilidad, barrido de tamaños, red mínima, geografía, Red Box ampliado, secretos y mapa MASVS. Lo que sigue sin hacer está en §6.

**Novedades del 22/11 (todas con prueba de regresión):** manejo global de errores con aviso amigable; áreas táctiles de 48 dp y fuente al 200 % sin desbordes; barra lateral desplazable en ventanas anchas y bajas; diálogo «Agregar a mi biblioteca» desplazable y confirmación antes de borrar (los dos hallados por el usuario torpe en la tablet); mensaje claro ante un certificado no confiable; 6 correcciones de seguridad en la API, **en producción desde el 22/11** (PR CEOSMOSV2 #1, Red Box de producción 27/27); reconexión BLE sin PIN corregida tras la prueba de punta a punta (§9).

## 1. Resumen ejecutivo y alcance

CEOSMOS Integral es una app Flutter de concentración, calma e inspiración conectada a su API (NestJS + PostgreSQL en Vercel/Neon), con Reloj y TV compañeros por BLE y funciones de soporte, reportes, mensajería y herramientas derivadas de las prácticas del curso. Cada función conserva su propia base de datos.

**Alcance de la etapa 3 (cierre):** pasada final de regresión en el código de entrega, prueba de «usuario torpe» dentro de la app, prueba de ventana flotante para hallar el tamaño mínimo funcional, Red Box de la API, comprobación de la API de producción, APK de release firmado con llave propia, plan de contingencia ensayado y documentación de defensa.

| Indicador | Resultado | Tipo |
|---|---|---|
| Pruebas de Flutter | **331/331** (`flutter test`; 217 el 21/11 + barrido de 91 tamaños, accesibilidad, errores, TLS, doble toque, biblioteca, scripts y reconexión BLE), análisis estático sin avisos | medido |
| Pruebas de Kotlin | Reloj, TV y Companion: 14/14 por app más lint sin errores | medido |
| Cobertura de líneas (toda `lib/`) | **52.9 %** (3 074 / 5 814, medida el 21/11); núcleo `core`/`data`/`domain` 78.9 % (P11) | medido |
| Usuario torpe dentro de la app | S24: 5 000 acciones, 0 errores, 0 crashes, 0 ANR. Tab S9: 5 000 acciones, 0 crashes, 0 ANR, 4 desbordes → corregidos y verificados (2 100 acciones con la misma semilla, 0 errores) | medido |
| Red Box de la API | Local: **13/13** + ampliado **37/37** (27/37 antes de corregir). Producción (22/11, sin credenciales, ≤ 4 req/s): **27/27** | medido |
| Reloj y TV de punta a punta (S24 + Tab S9) | 6 de 7 pruebas aprobadas en hardware; la reconexión sin PIN falló y se corrigió (v4); el tercer dispositivo, no verificado en hardware | medido |
| Soporte con roles (F-05) | admin, agente y usuario1: ticket, chat, adjunto, asignación y presencia aprobados; usuario2 no verificado | medido |
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
| F-05 | Soporte con roles (22/11 noche; el usuario escribió las contraseñas) | S24 + Tab S9 | **aprobado** con admin, agente y usuario1 (§9); usuario2 **no verificado** (mismo rol que usuario1) |
| F-06 | Incidencias en tiempo real: alta en la tablet visible al instante en el S24 | S24 + Tab S9 | aprobado (21/11) |
| F-07 | Reportes compartidos (Flutter y Android) conectados a la nube | S24 | aprobado |
| F-08 | Mis incidencias y acceso: solo lo propio | S24 | aprobado |
| F-09 | Mensajería entre equipos por Wi-Fi | S24 → Tab S9 | aprobado (21/11) |
| F-10 | Reloj y TV conectados a la vez por BLE, con lecturas en vivo | S24 + Tab S9 | aprobado; de punta a punta el 22/11 (§9) |
| F-11 | Seguridad de la cuenta, Directorio de alumnos y Citas de bienestar abren desde Perfil | S24 | aprobado |
| F-12 | Ningún texto visible contiene «Práctica», «P» + número, «Examen» ni «Eval.» | prueba automática | aprobado (`navegacion_funciones_test.dart`) |
| F-13 | Atrás vuelve a la sección y no cierra la app (Android 16/17) | prueba + equipos | aprobado |
| F-14 | Registro de una cuenta nueva | — | **no verificado: requiere acceso al correo** para el código; cubierto por pruebas con la API simulada |

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

Regiones: Vercel `iad1` (medido) y Neon `us-east-1` (medido en el `.env` local; que producción use el mismo host es inferido). Firestore (consola, 22/11): `practica7-8` en **us-central1** y `reportes-movil` en **nam5** (multirregión EE. UU.); `mesaayuda-p7` **no verificado** (la cuenta no tiene acceso a ese proyecto). La API solo publica IPv4 (en redes solo IPv6 Android usa 464XLAT, **inferido**). Para usuarios reales en la UE faltaría el aviso RGPD; no es un bloqueo técnico.

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

Las 6 correcciones de la API se fusionaron a producción el 22/11 (PR CEOSMOSV2 #1, merge `c07b01f`; 79/79 pruebas; despliegue «Ready»). **Verificado en producción** (`scripts/redbox_produccion.sh`, 27/27): CORS ajeno sin 500, JSON anidado sin sesión sin 500, tokens HS512 o de otra forma → 401, `alg:none` cortado por el firewall de Vercel (403), mensaje de login genérico, CSP presente, 429 por fuerza bruta. Lo que exige iniciar sesión (IDOR, `javascript:` en medios, rol) **no se repitió en producción**: el asistente no escribe contraseñas en servicios de producción; queda cubierto en local (13/13, 37/37) y en Jest. Rollback sin usar: redesplegar `a4d8d6a` con las variables actuales (no promover el despliegue viejo, que guarda los secretos anteriores).

**Firestore sin sesión (22/11, medido):** lecturas y escrituras rechazadas (403) en `practica7-8` y `reportes-movil`; en `mesaayuda-p7`, `turnos` y `contadores` dan 403, pero **`dispositivos` se lee sin sesión** (3 documentos de presencia: nombre, modelo, rol y última conexión). CEOSMOS no usa esa colección (la presencia de Soporte vive en `practica7-8/dispositivos`, que sin sesión da **403**, medido el 22/11). La regla la debe ajustar el dueño del proyecto `mesaayuda-p7` (otra cuenta de Google; la sesión del usuario no tiene acceso).

**Interceptación:** la app no confía en CA de usuario y rechaza un certificado autofirmado (prueba con un servidor HTTPS local). No se usó mitmproxy en el teléfono porque exige cambiar el proxy del sistema.

**Cifrado:** en tránsito, TLS en la API y en Firestore. En reposo, Keystore para el token; SQLite y SharedPreferences sin cifrar porque solo guardan datos de práctica. En BLE no hay cifrado del enlace: la integridad se protege con reto + HMAC y no se envía el PIN.

**Ataques (medido el 21/11 con `scripts/redbox_api.sh` contra la API local):** 13/13 bloqueados (`evidencias/blindaje/redbox_api_entrega.txt`). Antes (P10 y P7) ya se habían probado el acceso ajeno en Firestore y las escrituras BLE no autenticadas.

**Dependencias y secretos:** gitleaks 8.30.1 sobre los 33 commits del historial y el árbol de trabajo (22/11; `evidencias/blindaje/secretos_gitleaks.txt`, con los valores ocultos). En el historial hay 19 coincidencias: 7 claves de cliente de Firebase (públicas por diseño) y 12 tokens de sesión de la base local de P12 dentro de planes EXPLAIN (no son de producción). No hay contraseñas, JWT_SECRET, llaves ni `key.properties` en el historial. El keystore queda fuera del repositorio. Auditoría de dependencias (22/11, `evidencias/blindaje/dependencias.md`): OSV-Scanner sobre `pubspec.lock` → **0 vulnerabilidades**; `npm audit` de la API → **0 en producción** y 26 en herramientas de desarrollo, que bajaron a 19 moderadas con `npm audit fix` compatible (la alta de `brace-expansion` quedó corregida; el resto exige Jest 29 o Nest CLI 12, versiones mayores); companion: OSV sobre sus dependencias directas → solo `org.json 20180813` (únicamente pruebas) con 3 avisos DoS, actualizado a `20260719`. Las dependencias transitivas de Gradle no se escanearon (no verificado). `flutter pub outdated`: 13 directas con versiones nuevas, ninguna con aviso de seguridad.

## 6. Límites conocidos y riesgos aceptados

| Límite o riesgo | Impacto | Mitigación / estado |
|---|---|---|
| Pruebas con sesión de la API no repetidas en producción | IDOR, medios `javascript:` y rol solo se midieron en local | Mismo código desplegado (79/79 Jest, 37/37 local); producción verificada sin credenciales (27/27). Secretos rotados por el usuario el 22/11: las sesiones anteriores quedaron invalidadas (los dos equipos volvieron a Acceso) |
| **Incidente 22/11: la app real del S24 se desinstaló** | El usuario torpe se corrió con la variable `ORG_GRADLE_PROJECT_ceosmosMonkey`, que no llega a Gradle (reproducido). `flutter test` instaló el paquete real y lo desinstaló al terminar (S24: `firstInstallTime` 22/11 14:03): se perdieron los datos locales (sesión, SQLite, emparejamiento del Reloj y la TV). Los datos en la nube no se afectaron | Corregido: marcador `android/app/.ceosmos_monkey`, comprobación del paquete con aapt2 antes de correr y alarma si la app real se reinstala (`scripts/mono_bloques.ps1`, `test/blindaje_scripts_test.dart`). Tablet: **confirmado**, su app real también se reinstaló (22/11 14:49). Desde entonces todo se instala encima con `install -r` (v3 y v4 conservaron la sesión) |
| `mesaayuda-p7/dispositivos` legible sin sesión | Se ven 3 registros de presencia (nombre, modelo, rol, última conexión) | Exigir `request.auth != null` en la regla (tarea del usuario) |
| Usuario torpe: 5 000 acciones por equipo, no 20 000 | Menos cobertura aleatoria que la planeada | El S24 se quedó sin batería; el usuario decidió no repetir lo ya probado. Los hallazgos de la tablet se corrigieron y se verificaron con la misma semilla |
| Usabilidad con personas reales y recorrido con sesión en el equipo | Sin datos de usuarios reales; el recorrido con sesión del 22/11 no se hizo (la tablet estaba en Acceso y no se usaron credenciales) | Barrido automático, accesibilidad y usuario torpe; recorrido manual del 21/11 |
| El «usuario torpe» no entra a las funciones con nube (Soporte, Reportes, Citas) | Esas pantallas no reciben acciones al azar | Se excluyeron a propósito para no tocar datos reales; cubiertas por el recorrido manual |
| La entrega usa el APK firmado con la llave de depuración | Cualquiera con esa llave podría firmar una actualización | El APK con llave propia está listo (`release/CEOSMOS-entrega-v1-release.apk`), pero requiere registrar su SHA-1 en Firebase e instalarlo exige desinstalar (se pierden datos). Riesgo aceptado: decisión pendiente del usuario |
| SQLite y SharedPreferences sin cifrar | Datos de funciones legibles con acceso root | No guardan credenciales; el token está en el Keystore |
| Sin ofuscación ni detección de root | Ingeniería inversa más fácil | Dart se compila AOT a código nativo; aceptado para una app académica |
| Clave de Firebase de `mesaayuda` sin restringir | Uso de la cuota por terceros | Restringir por paquete + SHA (tarea del usuario) |
| Limitador de la API en memoria por instancia | En Vercel cada instancia cuenta por su lado | Upstash Redis (mejora futura) |
| Mensajería entre equipos en texto plano en la LAN | Otra persona en la misma Wi-Fi podría leerla | Aceptado: es solo de demostración y en red local |
| BLE: autenticación con reto + HMAC y PIN que nunca viaja; la carga útil no va cifrada | Se podría escuchar el tráfico de lecturas (pulso, pasos, estado de la TV) a pocos metros | Riesgo aceptado: el cifrado AES-256-GCM no se hizo porque tocaba las 3 apps a la vez justo antes de la entrega |
| Errores transitorios de GATT (`ANDROID_SPECIFIC_ERROR`) | La primera conexión a veces falla | Reintento manual o automático; documentado en la guía |
| Al abrir CEOSMOS, Reloj y TV no se conectan solos | Hay que pulsar «Conectar» (no pide el PIN: queda guardado) | Comportamiento actual; la reconexión automática cubre las caídas durante el uso |
| Tercer central sin PIN | No se probó con un tercer equipo real | Pruebas automáticas + registro real del 22/11: «Escritura rechazada: central no autenticado» |

## 7. Pruebas

| Conjunto | Cantidad | Cómo reproducir |
|---|---|---|
| Flutter (unidad, widgets, caja negra y blanca, BLE, funciones, accesibilidad, tamaños, TLS, CI) | 331 | `flutter test` |
| Cobertura | 52.9 % de líneas (núcleo 78.9 %), medida el 21/11 | `flutter test --coverage` |
| Kotlin (Reloj, TV, Companion) | 14 por app más lint | `cd companion; ./gradlew test lint` |
| Usuario torpe en el teléfono | 5 000 acciones por equipo + verificación de 2 100 en la tablet | `powershell -File scripts\mono_bloques.ps1 -Serial <serial>` (copia aislada `.monkey`) |
| Red Box de la API | 13 + 37 ampliado (local) + 27 en producción sin credenciales | `scripts\dev_backend.ps1`, luego `bash scripts/redbox_api.sh` y `bash scripts/redbox_ampliado.sh`; producción: `bash scripts/redbox_produccion.sh` |
| API (Jest) | 79 | `npx jest` en `ceosmos-api` |
| Red mínima | 65 mediciones | `bash scripts/medir_red.sh` |
| Sin texto académico visible | 1 recorrido | `flutter test test/navegacion_funciones_test.dart` |
| Scripts de operación (marcador, sin `monkey`, verificación de producción) | 5 | `flutter test test/blindaje_scripts_test.dart` |
| CI | Cada push y pull request | GitHub Actions `CI` (sin secretos ni producción) |

## 8. Plan de contingencia

- **Script:** `scripts/arreglo_rapido.sh <área>` (o `.ps1`). Ejecuta el análisis y las pruebas del área, compila en modo debug, instala en los dos equipos sin borrar datos y muestra el logcat de la app, cronometrando cada paso.
- **Volver atrás:** `git checkout entrega-v3` (o anteriores), o reinstalar `release\CEOSMOS-entrega-v3-release-llave-depuracion.apk` (se instala encima sin perder datos; misma firma). La entrega es `release\CEOSMOS-entrega-v4-release-llave-depuracion.apk` (1.2.1).
- **Verificación automática tras instalar (22/11):** el paso 6 del script (`scripts/verificar_produccion.ps1` o `.sh`) intenta entrar con un correo inexistente y espera «Correo o contraseña incorrectos.»: prueba que la app instalada llega a producción. Ciclo completo medido en el S24 con el área `login`: **164 s** (análisis 30, pruebas 18, build 35, instalación 42, logcat 20, verificación 18). El release usa producción aunque se compile sin `--dart-define` (`lib/core/config.dart`, `test/config_api_test.dart`).
- **Guía de fallos:** `evidencias/blindaje/Guia de fallos rapidos.md`.
- **Lista previa:** `evidencias/blindaje/Lista de verificacion previa.md`.

**Ensayo cronometrado (21/11, Tab S9, medido):**

| Fallo simulado | Área del script | ¿Lo detectaron las pruebas? | Detección (análisis + pruebas) | Verificación (análisis, pruebas, build, instalación, logcat) | Ciclo completo |
|---|---|---|---|---|---|
| F1 · campo de correo sin validar | `login` | sí (análisis y 1 prueba) | 20 s | 125 s | 2.4 min |
| F2 · timeout del cliente de la API en 1 ms | `red` | sí | 22 s | 92 s | 1.9 min |
| F3 · permiso de Bluetooth mal manejado | `ble` | sí | 26 s | 86 s | 1.9 min |

El ciclo medido no incluye el tiempo humano de escribir el arreglo: en el ensayo, la corrección fue restaurar el código. Con 2 minutos por ciclo quedan unos 15 minutos para diagnosticar y escribir el cambio dentro del margen de 20. Detalle en `evidencias/blindaje/ensayo/`. El código quedó idéntico al terminar (verificado con `git diff`).

\pagebreak

## 9. Cierre final en hardware (22/11, noche)

Equipos: S24 como central y Tab S9 con las apps Reloj y TV. Los dos con CEOSMOS **1.2.1** (`entrega-v4`, instalada encima: la sesión se conservó). Evidencias en `evidencias/blindaje/final/`.

**Producción.** Antes de fusionar: `/health` 200, sin token 401, login con correo inexistente → «Correo o contraseña incorrectos.» en los dos equipos, despliegue «Ready» y en los logs «Prisma connected to Neon» sin errores de base de datos ni de autenticación. Tras la rotación de secretos las sesiones anteriores se invalidaron; el usuario volvió a entrar y los dos equipos cargaron sus datos («Sincronizado»). Después de fusionar `blindaje-api` las sesiones siguieron válidas. `verificar_produccion` fallaba en la tablet aunque la app sí llegaba (espera fija de 6 s y la «ñ» mal decodificada por la consola): corregido con prueba de regresión.

| # | Reloj y TV de punta a punta | Resultado |
|---|---|---|
| 1 | Conexión con PIN al Reloj y a la TV, pulso en vivo | aprobado (63–87 bpm en el S24) |
| 2 | Notificación del S24 al Reloj | aprobado (aparece y vibra) |
| 3 | «Siguiente» en la TV inicia la sesión en el S24; pausa desde la TV y desde el Reloj | aprobado |
| 4 | Reconexión sin PIN tras cerrar y abrir las apps Reloj y TV | **falló en 1.2.0**: el S24 seguía en «Conectado» con lecturas congeladas (el enlace físico no cae porque las dos apps comparten el Bluetooth de la tablet). Corregido en 1.2.1: latido cada 5 s, reautenticación tras 2 envíos fallidos y vigilancia del silencio del Reloj (4 pruebas en `test/ble/ecosistema_ble_test.dart`). Repetido: los dos se reautentican solos en unos 4 s, sin PIN |
| 5 | Bluetooth del S24 apagado y encendido | aprobado: «Reconectando…» y los dos vuelven en ≤ 8 s sin cancelarse; Bluetooth encendido al final |
| 6 | Permiso de Bluetooth denegado y concedido | aprobado: «Permiso de Bluetooth denegado. Actívalo en Ajustes…», sin cierre; concedido de nuevo, reconecta |
| 7 | Tercer dispositivo sin PIN | **no verificado en hardware** (no hay un tercer central); pruebas automáticas y registro real «Escritura rechazada: central no autenticado» |

| F-05 · Soporte con roles (usuario2 no verificado: mismo rol que usuario1) | Resultado |
|---|---|
| Crear ticket (usuario1) | aprobado (REP901) |
| Mensajes en tiempo real | admin ↔ agente 2 s; usuario1 → admin 3 s. El usuario recibe con «Actualizar» (diseño de la práctica) |
| Adjunto ≤ 300 KB | aprobado: 203 KB enviado y recibido; 434 KB rechazado |
| Asignación agente ↔ admin | aprobado: «Pasar al administrador» y «Devolver al agente», 3 s cada uno |
| Presencia | aprobado (conectado/desconectado por rol) |
