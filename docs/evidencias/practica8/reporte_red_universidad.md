# CEOSMOS Móvil Integral · Prueba en la red universitaria

**Fecha:** 23 de octubre de 2026, 17:51 (UTC−06:00)  
**Entorno:** equipo Windows de desarrollo, conexión disponible al momento de la prueba.  
**Dictamen actualizado:** no se reprodujo un bloqueo en la conexión actual, pero la versión web sí depende de fuentes descargadas desde `fonts.gstatic.com:443`. Al bloquear ese dominio deliberadamente, desaparece el texto de la interfaz.

## Resultados observados

| Verificación | Resultado | Evidencia |
|---|---|---|
| Caja negra de autenticación, formularios, catálogo, sesiones, favoritos, dispositivos, datos por usuario, navegación y errores | **21/21 PASS; 12/12 requisitos cubiertos** | [reporte de casos](reporte.md), [eventos JSONL](flutter-test.jsonl), [CSV](casos.csv) |
| Análisis estático | **Sin problemas** (`flutter analyze --no-pub`) | Salida de consola: `No issues found!` |
| Compilación web con CanvasKit local | **Correcta** (`flutter build web --release --no-web-resources-cdn --no-pub`) | Salida de consola: `√ Built build\web` |
| Recursos servidos desde `127.0.0.1:8765` | **HTTP 200** en `/`, `flutter_bootstrap.js`, `main.dart.js`, `canvaskit/canvaskit.wasm` y `assets/assets/audio/orbit.mp3` | Solicitudes `HEAD` desde el equipo |
| Arranque en Chrome 155, compilación web local | **Carga correcta:** DOM con `flutter-view` y `flt-glass-pane`; proceso terminó con código 0, sin salida de error de red | Chrome en modo headless contra `http://127.0.0.1:8765/` |
| DNS y HTTPS hacia `pub.dev/api/packages/flutter_lints` | **HTTP 200** | Solicitud `HEAD` |
| DNS y HTTPS hacia `storage.googleapis.com/flutter_infra_release/releases/releases_windows.json` | **HTTP 200** | Solicitud `HEAD` |
| DNS y HTTPS hacia `fonts.googleapis.com/css2?family=Roboto` | **HTTP 200** | Solicitud `HEAD` |
| Solicitudes reales de la app web a `fonts.gstatic.com:443` | **Tres archivos de fuentes HTTP 200**; sin errores en la carga normal | [registro del navegador](capturas/navegador.json), [captura de la app](capturas/app_demo.png) |
| Simulación de bloqueo de `fonts.gstatic.com` | **El texto de la pantalla desaparece**, aunque los gráficos y controles siguen visibles | [captura del bloqueo simulado](capturas/app_fuentes_bloqueadas.png) |
| Puerto local `127.0.0.1:8765` | **TCP abierto**, inicio y recursos locales HTTP 200 | [registro de red y puertos](capturas/red_puertos.json) |

Los códigos 400 y 404 observados al consultar inicialmente la raíz de `storage.googleapis.com` y `fonts.googleapis.com` eran respuestas de rutas sin recurso. Las rutas válidas de la tabla devolvieron 200; **no son evidencia de bloqueo**.

## Errores y limitaciones

- **Errores reales de red detectados en la conexión actual:** ninguno. Las tres fuentes externas solicitadas por la app web devolvieron HTTP 200.
- **Dependencia y riesgo reproducible:** `fonts.gstatic.com` por HTTPS/TCP 443. El bloqueo simulado produjo `ERR_BLOCKED_BY_CLIENT` y eliminó los textos de la pantalla web. Esta simulación **no demuestra** que la universidad haya bloqueado el dominio; demuestra el impacto si llegara a bloquearse.
- **Errores funcionales detectados:** ninguno en los 21 recorridos automatizados. El caso CP-16 **inyecta deliberadamente** un fallo de audio para comprobar que la app muestra un aviso y conserva la sesión; no fue un fallo de la red universitaria.
- **Otras dependencias de red:** cuentas y datos en memoria, catálogo, MP3 y CanvasKit locales. No se observó llamada a API o Firebase durante los flujos principales. La instalación o actualización de Flutter puede requerir `pub.dev` y `storage.googleapis.com`.
- **Pendientes fuera del alcance:** persistencia tras reiniciar, JWT, passkeys reales, BLE/TCP/IP y pruebas en Android físico. Su ausencia responde al estado actual del proyecto; no se puede atribuir a esta red.
- **Incidencias del entorno de prueba:** el primer servidor local, iniciado dentro del sandbox de Codex, produjo `ERR_CONNECTION_TIMED_OUT` y rechazo de socket en `127.0.0.1:8765`. Al servir la misma compilación fuera de ese sandbox, Chrome y las cinco rutas locales funcionaron. El alias `python.exe` de Windows tampoco estaba disponible; se usó Node.js. Ninguna de estas incidencias demuestra un bloqueo de la red universitaria.

## Solicitud sugerida a TI de la universidad

Para la **versión web**, solicitar que se mantenga permitido el acceso HTTPS saliente a **`fonts.gstatic.com` por TCP 443**, pues la app solicita ahí Roboto y Noto Sans Symbols. En esta conexión funcionó (HTTP 200); la captura de bloqueo simulado muestra por qué conviene permitirlo en equipos o redes donde se restrinja. No se necesita abrir el puerto 8765 en el firewall de la universidad: se usó solo en `127.0.0.1` para la prueba local. Para instalar o actualizar Flutter, las rutas verificadas de `pub.dev` y `storage.googleapis.com` también respondieron en TCP 443.

**Límite del dictamen:** los casos funcionales se ejecutaron como pruebas de widgets y el arranque web se comprobó en Chrome local. No se verificó reproducción audible, rendimiento ni el comportamiento de una instalación Android en la red universitaria. El bloqueo de fuentes fue inyectado por la prueba y no fue observado como política de esta red.
