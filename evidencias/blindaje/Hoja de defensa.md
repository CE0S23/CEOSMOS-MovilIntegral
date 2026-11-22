# Hoja de defensa · CEOSMOS Integral

Una página por profesor: qué enseñar en la app, qué abrir y las 10 preguntas más probables, con una respuesta corta y su evidencia. Las cifras marcadas como **medido** salen de pruebas reales. Lo **no medido** se dice tal cual.

\pagebreak

## 1 · Usabilidad

**Qué enseñar (en este orden):** Acceso con un correo inválido, que muestra el error con ícono y texto. Inicio. Explorar con sus filtros. Mi sesión (pausar y terminar). Soporte con el botón ⓘ. Ventana flotante: achicarla hasta 260 × 440 dp (sigue sin errores hasta 220 × 380).
**Qué abrir:** S24 en modo claro y luego oscuro (Ajustes › Pantalla). Carpetas `evidencias/rediseno/` (antes y después) y `evidencias/blindaje/ventana/`.

| # | Pregunta probable | Respuesta corta | Evidencia |
|---|---|---|---|
| 1 | ¿Cómo sabe el usuario dónde está? | Tienen nombre funcional la barra inferior (6 pestañas), el encabezado «Tu espacio / sección» en tablet y cada función abierta («← Soporte · Tickets y chat interno») | `evidencias/reestructura/` |
| 2 | ¿Qué pasa si se equivoca en un formulario? | Validación antes de enviar, mensaje junto al campo y error con ícono + texto (no solo color) | `test/widget_test.dart` («Acceso valida campos») |
| 3 | ¿Funciona en pantallas pequeñas? | Barrido automático de 91 tamaños (240–1600 × 320–1000 dp): sin desbordes desde 240 dp de ancho. En la Tab S9 real, 14 tamaños de ventana flotante sin errores; cómoda desde **260 × 440 dp** (medido). Se corrigió la barra lateral en ventanas anchas y bajas | `test/tamanos_pantalla_test.dart`, `evidencias/blindaje/ventana/barrido_tamanos.md` y `ventana/v2/` |
| 4 | ¿Y con un usuario torpe? | Prueba dentro de la app (copia aislada) con 5 000 acciones al azar por equipo: S24 sin errores ni crashes; en la Tab S9 encontró 4 desbordes en un diálogo, se corrigieron y la misma semilla pasó con 0 errores (medido) | `integration_test/mono_usuario_test.dart`, `evidencias/blindaje/mono/` |
| 5 | ¿Contraste y accesibilidad? | Paleta verificada con WCAG AA; áreas táctiles ≥ 48 dp y botones con nombre (prueba de las guías de Android; se corrigió el avatar de 36 dp); fuente del sistema al 200 % sin desbordes | `test/accesibilidad_test.dart`, `tool/contraste/resultado.txt` |
| 6 | ¿Modo oscuro? | Sigue al del sistema; tiene su propia paleta (no un simple invertido) | `evidencias/rediseno/despues_*_oscuro.png` |
| 7 | ¿El botón Atrás cierra la app? | No: vuelve a la sección anterior (se corrigió para Android 16/17) | `test/navegacion_funciones_test.dart` |
| 8 | ¿Se hizo un estudio con usuarios reales? | **No medido**: no hubo sesiones con usuarios (la etapa de usabilidad con personas no se ejecutó). Se sustituyó con pruebas automatizadas y heurísticas | Este documento, §6 |
| 9 | ¿Por qué esos colores y fuentes? | Paleta guinda/cian entregada; Bricolage para títulos y DM Sans para texto, empaquetadas y sin red | `lib/core/theme/` |
| 10 | ¿Qué mejorarías? | Pruebas con 5 usuarios reales (tareas cronometradas) y lector de pantalla TalkBack de punta a punta | §6 |

\pagebreak

## 2 · Funcionalidad

**Qué enseñar:** Inicio de sesión. Una sesión de enfoque (la TV la proyecta y el Reloj muestra el ritmo cardiaco). Soporte con el menú del administrador. Incidencias en tiempo real (crear en la tablet y verla al instante en el S24). Mensajería entre equipos.
**Qué abrir:** Equipos con Reloj y TV conectados. Soporte › Reportes e incidencias en los dos equipos.

| # | Pregunta probable | Respuesta corta | Evidencia |
|---|---|---|---|
| 1 | ¿Qué hace la app? | Concentración, calma e inspiración con sesiones, audio y paisajes, más funciones de soporte, reportes, mensajería y herramientas | Nota «12 - Mapa de funciones» |
| 2 | ¿Dónde quedaron las prácticas? | Cada una es una función con nombre propio, en la sección donde tiene sentido | `memoria/12 - Mapa de funciones.md` |
| 3 | ¿Cómo funcionan los roles? | En Soporte, el usuario crea tickets, el agente atiende sus asignados y el administrador asigna y gestiona. En CEOSMOS, solo ADMIN ve Administración | Recorrido del 21/11, `test/widget_test.dart` (ADMIN) |
| 4 | ¿Cada función tiene su propia base de datos? | Sí: SQLite, SharedPreferences o una app de Firebase con nombre por función; CEOSMOS usa su API con PostgreSQL | Mapa de funciones |
| 5 | ¿Los datos se comparten en tiempo real? | Sí. Medido el 21/11: una incidencia creada en la tablet apareció en el S24 sin recargar | `evidencias/reestructura/dispositivos/s24_14_*.png` |
| 6 | ¿Qué pasa sin internet? | Las sesiones de enfoque quedan pendientes y se reenvían sin duplicarse (idempotencia); las incidencias se sincronizan al volver la red | `test/p12`, nota P12 |
| 7 | ¿Cómo se conectan el Reloj y la TV? | Por BLE: CEOSMOS es el central y las apps Reloj y TV son periféricos GATT, autenticados con reto + HMAC a partir de un PIN de 6 dígitos | Nota «06 - BLE Wearable y TV» |
| 8 | ¿Cuántas pruebas hay? | 217 de Flutter más 14 de Kotlin por app, en CI en cada push | §7 |
| 9 | ¿Qué falló en las pruebas y cómo se corrigió? | Botón de la TV partido, tarjetas grises en modo oscuro, encabezado desbordado a 280 dp: todo corregido y con prueba | Bitácora del 21/11 |
| 10 | ¿Se puede arreglar algo en vivo? | Sí, con `scripts/arreglo_rapido.sh <área>`; el ensayo midió el ciclo completo | §8 |

\pagebreak

## 3 · Redes

**Qué enseñar:** En Inicio, el aviso «Sincronizado» o «Sin conexión». Equipos (BLE). Mensajería entre equipos por Wi-Fi (TCP 5000). El aviso de conexión dentro de Soporte.
**Qué abrir en la terminal:** `curl -s -o /dev/null -w "%{http_code} %{time_total}\n" https://ceosmos-api.vercel.app/api/health`

| # | Pregunta probable | Respuesta corta | Evidencia |
|---|---|---|---|
| 1 | ¿Qué servicios usa la app? | La API de CEOSMOS (Vercel, región iad1 en EE. UU., HTTPS), Firestore en tres proyectos de Firebase, BLE local, TCP local para la mensajería y una API local para las citas | §4 del dossier |
| 2 | ¿Cuánto tarda la API? | Medido desde México el 21/11: conexión de 35 ms y respuesta de 0.21–0.34 s en `/health` (un pico de 1.76 s en arranque en frío) | `evidencias/blindaje/api_produccion_health.txt` |
| 3 | ¿Y la carga inicial? | Medido en P11: 984 ms (login + 4 lecturas en paralelo) en el S24 | Reporte P11 |
| 4 | ¿Cuántos usuarios aguanta? | Medido en P12 (API local): saturación en ~5 usuarios concurrentes (~210 solicitudes/s); después la latencia crece de forma lineal, sin errores | Reporte P12 |
| 5 | ¿Funciona en España o Europa? | **Sí, medido** el 22/11 con sondas públicas: desde Madrid y Logroño la API responde 200 en 373–400 ms y Firestore en 783 ms. También funciona desde los 6 continentes (137–763 ms). Datos en EE. UU. (Vercel `iad1`, Neon `us-east-1`); para usuarios reales en la UE faltaría el aviso RGPD | `evidencias/blindaje/red/geografia.md` |
| 6 | ¿Qué red mínima necesita? | **Medido** con un proxy que degrada la red: en EDGE/2G (50 kbps, +400 ms) la API responde en 2.5 s; con 20 % de pérdida, en ≤ 5 s. Mínimo: 5 kbps o RTT de 4 s dentro del timeout de 15 s. Firebase falla con RTT de 4 s (Google corta a los 10 s) | `evidencias/blindaje/red/red_minima.md` |
| 7 | ¿Qué pasa si se cae la API? | Aviso «Sin conexión», reintento con espera progresiva y las escrituras pendientes se reenvían sin duplicarse | `test/p13_14/aut05_*`, `test/p12` |
| 8 | ¿Por qué falla a veces el BLE? | Error transitorio de GATT de Android (`ANDROID_SPECIFIC_ERROR`); la app reintenta y conecta (visto el 21/11) | Recorrido del 21/11 |
| 9 | ¿Cómo se comunican los dos teléfonos? | Mensajería por TCP en el puerto 5000 dentro de la misma Wi-Fi; uno crea la sala y el otro se une por IP | `lib/practicas/p06/` |
| 10 | ¿Hay límite de peticiones? | Sí, 120 por minuto por IP (auth 10/min). Detrás de un mismo NAT, los equipos comparten el cupo | Reporte P12, «09 - Decisiones técnicas» |

\pagebreak

## 4 · Seguridad

**Qué enseñar:** Inicio de sesión con contraseña fuerte. «Mis incidencias y acceso», que solo muestra lo propio. La verificación de permisos. El PIN de la TV. El script Red Box.
**Qué abrir en la terminal:** `bash scripts/redbox_api.sh` (requiere la API local con `scripts\dev_backend.ps1`).

| # | Pregunta probable | Respuesta corta | Evidencia |
|---|---|---|---|
| 1 | ¿La comunicación va cifrada? | Sí: HTTPS con HSTS (2 años, `preload`), y HTTP redirige con 308. El tráfico en texto claro solo se permite a `localhost` y al emulador | `api_produccion_health.txt`, `network_security_config.xml` |
| 2 | ¿Dónde se guarda el token? | En almacenamiento seguro (Keystore de Android), nunca en texto plano | `lib/data/token_store.dart` |
| 3 | ¿Qué ataques resiste la API? | Red Box 13/13 + ampliado 37/37 (22/11): tokens expirados, HS512, `alg:none`, inyección SQL/NoSQL, XSS, IDOR, asignación masiva, JSON anidado, CORS, enumeración y fuerza bruta (429). La primera pasada dio 27/37: se corrigieron 6 fallos en la API (rama `blindaje-api`, **falta promoverla a producción**) | `evidencias/blindaje/redbox_ampliado.txt`, `masvs.md` |
| 4 | ¿Y el Bluetooth? | El PIN no viaja por el aire: reto + HMAC. Un central no autenticado no puede escribir ni suscribirse. El enlace BLE no usa bonding cifrado | Nota 06; §6 del dossier |
| 5 | ¿Un usuario puede ver datos de otro? | No: la API filtra por usuario (404 ante IDOR) y las reglas de Firestore bloquean leer o modificar lo ajeno | Red Box, nota P10 |
| 6 | ¿Hay secretos en el código? | Solo claves de cliente de Firebase (públicas por diseño y protegidas por reglas y por paquete + SHA) y la credencial simulada de la práctica de código seguro | §5 del dossier |
| 7 | ¿El APK es seguro? | Release no depurable, `allowBackup=false`, solo las actividades necesarias exportadas y firmado con llave propia (APK de respaldo) | `release/`, nota 07 |
| 8 | ¿Se revisó contra OWASP? | Sí: mapa MASVS v2 y Mobile Top 10 control por control, con su estado (cumple, parcial o riesgo aceptado) y su evidencia | `evidencias/blindaje/masvs.md` |
| 9 | ¿Qué riesgos quedan? | Limitador en memoria por instancia, cesión en «Mis incidencias», clave de `mesaayuda-p7` sin restringir y rotación de secretos pendiente | §6 |
| 10 | ¿Se hizo pentest completo? | No es un pentest profesional: es un Red Box de 50 casos sobre la API, Firestore sin sesión (se halló `mesaayuda-p7/dispositivos` legible: hay que cerrar la regla), gitleaks sobre el historial y una prueba de certificado no confiable. No se usó mitmproxy en el teléfono (exige cambiar el proxy del sistema) | `evidencias/blindaje/masvs.md` |
