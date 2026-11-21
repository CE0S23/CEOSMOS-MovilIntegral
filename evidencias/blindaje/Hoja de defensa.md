# Hoja de defensa · CEOSMOS Integral

Una página por profesor: qué enseñar en la app, qué abrir y las 10 preguntas más probables, con una respuesta corta y su evidencia. Las cifras marcadas como **medido** salen de pruebas reales. Lo **no medido** se dice tal cual.

\pagebreak

## 1 · Usabilidad

**Qué enseñar (en este orden):** Acceso con un correo inválido, que muestra el error con ícono y texto. Inicio. Explorar con sus filtros. Mi sesión (pausar y terminar). Soporte con el botón ⓘ. Ventana flotante: achicarla hasta 320 × 560 dp.
**Qué abrir:** S24 en modo claro y luego oscuro (Ajustes › Pantalla). Carpetas `evidencias/rediseno/` (antes y después) y `evidencias/blindaje/ventana/`.

| # | Pregunta probable | Respuesta corta | Evidencia |
|---|---|---|---|
| 1 | ¿Cómo sabe el usuario dónde está? | Tienen nombre funcional la barra inferior (6 pestañas), el encabezado «Tu espacio / sección» en tablet y cada función abierta («← Soporte · Tickets y chat interno») | `evidencias/reestructura/` |
| 2 | ¿Qué pasa si se equivoca en un formulario? | Validación antes de enviar, mensaje junto al campo y error con ícono + texto (no solo color) | `test/widget_test.dart` («Acceso valida campos») |
| 3 | ¿Funciona en pantallas pequeñas? | Probado en ventana flotante: completa hasta **320 × 560 dp** (medido). A 280 dp se corrigió el encabezado; por debajo de 280 ya no es cómoda | `evidencias/blindaje/ventana/`, prueba sin desbordes a 280 px |
| 4 | ¿Y con un usuario torpe? | Prueba dentro de la app con 20 000 acciones al azar (toques, textos raros, Atrás, desplazamientos) en cada teléfono | `integration_test/mono_usuario_test.dart`, `evidencias/blindaje/mono/` |
| 5 | ¿Contraste y accesibilidad? | Paleta verificada con WCAG AA; 6 combinaciones ajustadas; objetivos táctiles de 48 dp o más | `tool/contraste/resultado.txt`, nota «11 - Sistema de diseño» |
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
| 5 | ¿Funciona en España o Europa? | **Inferido, no medido**: la API está en EE. UU. Este; desde España se esperan unos 90–120 ms de ida y vuelta (hoy, unos 35 ms desde México). Funciona, pero responde algo más lento. No hay bloqueo por país | §4 del dossier |
| 6 | ¿Qué red mínima necesita? | **No medido** con limitación de ancho de banda. Referencia: la respuesta más grande (historial) pesa 24–28 KB | Reporte P12, §6 del dossier |
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
| 3 | ¿Qué ataques resiste la API? | 13/13 del Red Box del 21/11: sin token o token alterado, `alg:none`, inyección SQL, IDOR, asignación masiva, cuerpo de 2 MB, USER en `/admin` y token tras cerrar sesión | `evidencias/blindaje/redbox_api_entrega.txt` |
| 4 | ¿Y el Bluetooth? | El PIN no viaja por el aire: reto + HMAC. Un central no autenticado no puede escribir ni suscribirse. El enlace BLE no usa bonding cifrado | Nota 06; §6 del dossier |
| 5 | ¿Un usuario puede ver datos de otro? | No: la API filtra por usuario (404 ante IDOR) y las reglas de Firestore bloquean leer o modificar lo ajeno | Red Box, nota P10 |
| 6 | ¿Hay secretos en el código? | Solo claves de cliente de Firebase (públicas por diseño y protegidas por reglas y por paquete + SHA) y la credencial simulada de la práctica de código seguro | §5 del dossier |
| 7 | ¿El APK es seguro? | Release no depurable, `allowBackup=false`, solo las actividades necesarias exportadas y firmado con llave propia (APK de respaldo) | `release/`, nota 07 |
| 8 | ¿Se revisó contra OWASP? | Mapa MASVS / Mobile Top 10 en §5, con lo que está cubierto y lo que no | §5 |
| 9 | ¿Qué riesgos quedan? | Limitador en memoria por instancia, cesión en «Mis incidencias», clave de `mesaayuda-p7` sin restringir y rotación de secretos pendiente | §6 |
| 10 | ¿Se hizo pentest completo? | **No**: el Red Box ampliado de la etapa de seguridad no se ejecutó; hay 13 casos de API más los de BLE, Firestore y APK | §6 |
