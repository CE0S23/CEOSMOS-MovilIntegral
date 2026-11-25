# CEOSMOS Móvil Integral · Matriz de cumplimiento de la rúbrica

Revisión del 25/11/2026, versión 1.3.0 (commit `fc37eed`, CI en verde). Cifras: `evidencias/documentacion/cifras.md`.
Estados: **Cumple** (verificado) · **Parcial** (cumple con un límite declarado) · **No verificado** (no se pudo probar; se dice tal cual).

## A. Documento de seguimiento del proyecto

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| A1. Planteamiento del problema y justificación | **Cumple** | Seguimiento §1: contexto, problema, pregunta guía, usuarios y roles, objetivo general, 7 objetivos con estado, alcance, limitaciones y metodología | `memoria/01`, `memoria/02` |
| A2. Seguimiento de avances | **Cumple** | Seguimiento §2: cronología con fechas de git (08/10 y 11/11 a 25/11), etiquetas `entrega-v1` a `entrega-v4` y 1.3.0, plan por parcial contra lo entregado (passkeys no hechas), indicadores y pendientes | 42 commits; `memoria/10 - Bitácora.md`; `cifras.md` |
| A3. Evidencia de decisiones y cambios | **Cumple** | Seguimiento §3: 19 decisiones con alternativas, motivo, efecto y commit; 5 cambios de plan; 9 incidentes con lección (incluido el borrado de datos del S24 y la tablet) | `memoria/09 - Decisiones técnicas.md`; commits citados |

## B. Diseño y arquitectura

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| B1. Diseño de arquitectura | **Cumple** | Seguimiento §4: arquitectura, despliegue, secuencia BLE, datos y almacenamiento por función, capas, APIs y seguridad | `evidencias/diagramas/` (4 diagramas; fuentes en `tool/diagramas/`) |
| B2. Diseño de interfaz y UX | **Cumple** (faltan 4 capturas en el teléfono) | Seguimiento §5; Manual de usuario | `memoria/11 - Sistema de diseño.md`; `evidencias/manual/`, `evidencias/pwa/` |

## C. Desarrollo de la aplicación tipo PWA

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| C1. Funcionamiento | **Cumple** en Chromium (24/11): acceso, inicio, sesión y Equipos | Seguimiento §6.1 | `evidencias/pwa/` |
| C2. Manifiesto | **Cumple**: id, scope, display_override, íconos maskable, capturas, atajos; 0 errores de instalabilidad | Seguimiento §6.1 | `web/manifest.json`, `test/pwa_test.dart` |
| C3. Service worker y sin conexión | **Cumple**: `sw.js` propio con precarga versionada; sesión sin red enviada una sola vez al volver la red | Seguimiento §6.1 | `web/sw.js`, `scripts/pwa_precache.py`, `test/sin_conexion_test.dart`, `evidencias/pwa/01…04` |
| C4. Responsivo e instalable | **Parcial**: 91 tamaños sin desbordes e instalación en escritorio; instalación en el teléfono **no verificada** | Seguimiento §5 y §6.1 | `test/tamanos_pantalla_test.dart` |

## D. Integración con dispositivos inteligentes

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| D1. Comunicación | **Cumple** en Android (S24 + Tab S9, BLE con reto + HMAC; TCP/IP). Web Bluetooth de la PWA **no verificado en hardware** | Seguimiento §4.5 y §6.2 | `evidencias/ble_*.png`, `evidencias/diagramas/ble_secuencia.png` |
| D2. Capacidades o sensores | **Parcial**: radio BLE, botón, D-pad, vibración, notificaciones, servicio en primer plano y Keystore reales; pulso y pasos **simulados** | Seguimiento §6.2; Reporte §5 | — |
| D3. Intercambio y procesamiento | **Cumple**: JSON validado, 20 msg/s, 30–230 bpm, `metadata.wearable`, latido de 5 s | Seguimiento §4.5 | `lib/core/ble/`, `test/ble/` |
| D4. Permisos y compatibilidad | **Cumple** (Android 11 o anterior declarado, no probado) | Seguimiento §6.2 | `evidencias/ble_11_*`, `ble_12_*` |

## E. Seguridad y calidad

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| E1. Protección de información y autenticación | **Cumple**: JWT HS256, Keystore, Red Box 13/13 y 37/37 (local) y 27/27 (producción), HMAC en BLE, MASVS; el SW nunca guarda la API | Seguimiento §4.7; Reporte §4.4 | `evidencias/blindaje/masvs.md`, `redbox_*.txt` |
| E2. Pruebas y validación | **Cumple**: 344/344 Flutter, 79/79 API, 14/14 por app Kotlin, cobertura 56.0 % (núcleo 84.8 %), 29 corridas de CI y la de la 1.3.0 en verde | Reporte §3 | `test/`, `.github/workflows/ci.yml`, CI |
| E3. Rendimiento, estabilidad y recuperación | **Cumple**: reintentos exponenciales, idempotencia, modo sin conexión, usuario torpe de 12 100 acciones, red mínima | Reporte §4 | `evidencias/blindaje/red/`, `mono/` |

## F. Presentación y defensa

| Criterio | Estado | Dónde | Evidencia |
|---|---|---|---|
| F1. Demostración funcional | Guion de 8 min abajo; ensayo pendiente del autor | Este documento | `evidencias/blindaje/Lista de verificacion previa.md` |
| F2. Dominio técnico | Preguntas probables abajo y Hoja de defensa | Este documento | `evidencias/blindaje/Hoja de defensa.md` |

## Pendientes que solo puede resolver el equipo

1. Instalar el APK 1.3.0 en el S24 y la Tab S9 (`adb install -r`, sin desinstalar): en los equipos sigue la 1.2.1.
2. Probar la PWA con Web Bluetooth contra el Reloj y la TV reales: `adb reverse tcp:4200 tcp:4200`, abrir `http://localhost:4200` en Chrome del S24, Equipos › Conectar.
3. Decidir si la PWA se publica en un dominio (agregar ese origen a la lista CORS de la API de producción).
4. Opcional: leer pulso real (reloj Wear OS con sensor) en lugar del simulado.

## Guion de demostración (≈ 8 min)

Antes: API de producción (o `scripts\dev_backend.ps1` si es local); `scripts\construir_pwa.ps1 -Servir`; tablet con Reloj y TV abiertos; S24 con CEOSMOS.

1. **Problema y arquitectura (1 min).** Seguimiento, figuras 1 y 2: un código Flutter, dos clientes (APK y PWA), una API, una base, dos periféricos BLE.
2. **PWA (2 min).** Abrir `http://localhost:4200` en Chrome → «Instalar» → se abre en su ventana. DevTools › Application: manifiesto y `sw.js` activo. Cambiar el ancho: barra inferior ↔ barra lateral.
3. **Sin conexión (2 min).** DevTools › Network › Offline → recargar: abre con «Sin conexión». Terminar una sesión corta → recargar (sigue pendiente) → Online: pasa a «Sincronizado» y aparece una sola vez en el historial.
4. **Dispositivos (2 min).** En el S24: Equipos › Reloj › Conectar (PIN). Pulso en vivo (simulado, decirlo); el botón del Reloj pausa la sesión; la TV proyecta y «Siguiente» inicia la sesión. Apagar y encender el Bluetooth: reconecta solo.
5. **Seguridad y calidad (1 min).** GitHub Actions en verde (Flutter, PWA, Kotlin); Red Box 27/27 en producción; 344 pruebas.

## Preguntas probables

- **¿Por qué no usaron el service worker de Flutter?** En Flutter 3.41 se instala y se desregistra solo; sin un SW propio la app no abre sin red.
- **¿Qué guarda el service worker?** Solo el app shell (31 archivos, 19.1 MB) e imágenes externas (máx. 60). Nunca la API, Firebase ni peticiones que no sean GET.
- **¿Cómo se actualiza la PWA?** `pwa_precache.py` pone en `sw.js` un hash del contenido; si cambia un archivo, se instala el nuevo SW y se borra la caché anterior.
- **¿Qué pasa con el token sin conexión?** Sigue en el almacén seguro; el servidor lo revalida en la primera petición y un 401 cierra la sesión y borra la copia local.
- **¿Cómo evitan duplicar sesiones?** Cada sesión lleva un `clientId` generado una vez; si llega repetida, el servidor devuelve la existente.
- **¿Por qué BLE y no TCP como decía el plan?** El plan venía de la inestabilidad del cuatrimestre anterior; con periféricos nativos en Kotlin el enlace fue estable. TCP quedó como alternativa.
- **¿El pulso es real?** No: la tablet no tiene sensor; la app Reloj lo simula con el formato de un reloj real. Flujo, validación y guardado son los mismos.
- **¿Cómo se protege el enlace BLE?** Reto de un solo uso y respuesta HMAC-SHA256 con el PIN, que nunca viaja; sin autenticar se rechaza (GATT 8) y 3 fallos bloquean 60 s. La carga útil no va cifrada (riesgo aceptado).
- **¿Por qué la TV no es PWA?** Web Bluetooth solo puede ser central; la TV debe ser periférico GATT.
- **¿Funciona en iPhone?** La app, la instalación y el modo sin conexión sí; Safari no tiene Web Bluetooth y la tarjeta lo explica.
- **¿Qué salió mal en el proyecto?** Una prueba de estrés desinstaló la app real de los dos equipos (se perdieron datos locales); se corrigió el aislamiento y ahora se comprueba el paquete antes de correr.
