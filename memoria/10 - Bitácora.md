---
tags: [ceosmos, bitacora]
estado: vigente
actualizado: 2026-11-19
---

# Bitácora

- **08/10/2026** — Primera revisión: app Flutter local (sin BD), catálogo, sesiones, 11 pruebas.
- **11/11/2026** — Fases 0–5: plan, ventana Prácticas (10 prácticas, BD propia), análisis de faltantes, app real contra la API, pruebas en emulador; Neon + Resend + S24.
- **11/11/2026** — Práctica 11 (White Box): correcciones y reporte.
- **12/11/2026** — Práctica 12 (optimización, estrés, resiliencia); API en Vercel.
- **18/11/2026** — Revisión completa:
  - P4: campo `correo` con migración v1→v2 (probado en el S24).
  - P5, P6 (Wi-Fi S24↔tablet), P9 (DB-01…09), P10 (SEG) probados en dispositivos.
  - BLE: central en CEOSMOS + apps Reloj y TV; probado en hardware; 2 defectos corregidos.
  - Corrección de Atrás en prácticas (Android 16/17).
  - Red Box de la API (13/13) y del APK.
  - Memoria reestructurada en esta carpeta; respaldo en `C:/CESAR10cuatri/memoria_respaldo_2026-11-18/`.
  - Commits locales en `main` (sin push).
  - Word actualizado (sección «Prácticas del curso aplicadas en la app CEOSMOS»; respaldo del original en `memoria_respaldo_2026-11-18/`).
  - 15:10 — Cuentas P7 creadas en Firebase Auth; falta su documento de rol (pausado por el usuario).

- **18/11/2026 (tarde)** — Prácticas 13-14: 27 pruebas Flutter + 5 Kotlin nuevas, regresión DEF-BLE-01 demostrada, 3 errores de lint corregidos, CI en GitHub Actions. Historial redactado (secreto antiguo; respaldo `C:/CESAR10cuatri/CEOSMOS.MovilIntegral_respaldo_pre_redaccion_2026-11-18.bundle`), repo público `CE0S23/CEOSMOS-MovilIntegral`, PR #1, runs #1–#4 en verde. → [[Práctica 13-14 - Automatización de pruebas y CI]]
- **18/11/2026 (~19:55)** — Cierre P13-14 en pausa: PR #1 fusionado (CI de main verde), inventario de secretos, `.bundle` borrado, claves de practica7-8 y reportes-movil restringidas y probadas (reportes OK). Falta: rotación (usuario), verificación en el S24, P7, mesaayuda-p7, alertas, logs, Word. → [[Práctica 13-14 - Automatización de pruebas y CI]]
- **19/11/2026** — Entregables P13-14 terminados:
  - [x] Logs de los runs de main (44438169735), #7 y #8 en `evidencias/p13_14/`.
  - [x] Captura de Actions con main en verde.
  - [x] Word completado (URLs de los 9 runs, tiempo total, matriz AUT-01–08), 2 páginas.
  - [x] Commit y push a `main` con evidencias, Word, memoria y captura `firebase_01` (`firebase_02` vacía, fuera de git).
  - [ ] Siguen pendientes: rotación de secretos, clave de `mesaayuda-p7`, alertas de GitHub y P7.
- **19/11/2026 (tarde)** — Prácticas 7–12:
  - [x] P7: documentos de rol de las 4 cuentas creados en la consola; clave restringida aceptada por Firebase Auth; recorrido con los 4 roles en S24 + Tab S9 y TC01–TC08 aprobados. → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
  - [x] 4 fallas corregidas: correos de rol viejos, formulario en blanco con el teclado (`PracticaHost`), mensaje propio en «Pendiente», texto del rechazo de adjuntos.
  - [x] P8, P11, P12 confirmadas con `flutter test` 215/215 y CI; P9 y P10 con una prueba rápida en los dos equipos.
  - [x] Word: P7 reescrita (sin «No aplicado por completo»); respaldo en `C:/CESAR10cuatri/memoria_respaldo_2026-11-19/`.
  - [ ] Siguen pendientes: rotación de Neon/`JWT_SECRET`, clave de `mesaayuda-p7`, alertas de GitHub. → [[08 - Pendientes]]
- **21/11/2026** — Rediseño estético (sin cambios de lógica). → [[11 - Sistema de diseño]]
  - [x] `lib/core/theme/`: tokens, `CeosmosPaleta` (claro/oscuro), escala Bricolage + DM Sans, espaciados, radios, sombras y temas de componentes; `themeMode: system`.
  - [x] Pantallas de CEOSMOS y las 7 prácticas Flutter sin colores ni tamaños sueltos; errores con ícono + texto (`Aviso`).
  - [x] Reloj y TV (`TemaCeosmos.kt`, escala compacta/grande, foco D-pad cian) y prácticas nativas P9/P10/BD (`CeosmosTema`, estilo `CeosmosPracticas`).
  - [x] 6 combinaciones ajustadas a WCAG AA (`tool/contraste/`); 215/215 pruebas, analyze limpio, gradle test + lint verde.
  - [x] Capturas antes/después en `evidencias/rediseno/`.
  - [ ] Recorrido en S24 / Tab S9 pendiente: no había equipos conectados por adb.
- **21/11/2026 (tarde)** — Reestructura: prácticas → funciones de CEOSMOS. → [[12 - Mapa de funciones]]
  - [x] Pestaña «Prácticas» reemplazada por **Soporte**; Mensajería en Equipos; Seguridad, Directorio y Citas en Perfil › Cuenta y herramientas.
  - [x] Sin «Práctica/P#/Examen/Eval.» visible (Flutter, títulos de MaterialApp, etiquetas del manifest y barra nativa); prueba `navegacion_funciones_test.dart`.
  - [x] Botón ⓘ «Referencia académica» centralizado en `lib/core/referencias_academicas.dart` (`mostrarReferenciasAcademicas`).
  - [x] Word «Reporte de avances - CEOSMOS revicion.docx» reescrito por funciones + «Calidad y pruebas»; respaldo en `C:/CESAR10cuatri/memoria_respaldo_2026-11-21/`.
  - [x] 216/216 pruebas, analyze limpio, companion verde, capturas en `evidencias/reestructura/`.
  - [x] Recorrido en S24 / Tab S9 hecho por la tarde (ver [[12 - Mapa de funciones]]); quedan agente y usuarios de Soporte (contraseñas del usuario).

- **22/11/2026** — **Blindaje completado** → [[13 - Blindaje]]: usabilidad, funcionalidad, redes y seguridad medidas; API endurecida en producción (Red Box 27/27 en prod, 13 + 37 en local); Reloj, TV y Soporte probados de punta a punta (reconexión BLE corregida); incidente del usuario torpe corregido; 331/331 pruebas; `entrega-v4` (1.2.1) en los dos equipos.
- **22/11/2026 (noche)** — Documentación final: Reporte de avances actualizado a 1.2.1 y Manual de usuario nuevo (`Reporte de avances - CEOSMOS revicion.docx/.pdf`, `Manual de usuario - CEOSMOS.docx/.pdf`).

- **25/11/2026** — Commit y CI de la 1.3.0 (`fc37eed`, [corrida 45686893198](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/45686893198) en verde) y documentación final:
  - [x] Cifras medidas hoy: Flutter 344/344, API 79/79, Kotlin 14/14 por app, cobertura 56.0 % (núcleo 84.8 %), 29 corridas de CI → `evidencias/documentacion/cifras.md`.
  - [x] Nuevo `Documento de seguimiento del proyecto - CEOSMOS.docx/.pdf`; Reporte de avances reorganizado (sin A1–B2); Manual con índice automático, figuras y texto alternativo; Matriz, prácticas 13-14, Hoja de defensa y Lista previa al día. Diagramas nuevos: `evidencias/diagramas/despliegue.png`, `datos.png`.
  - [x] Copias finales en `entrega/` (LEEME.md). Respaldo previo: `C:/CESAR10cuatri/respaldos/documentacion_2026-11-25/`.
  - [ ] APK 1.3.0 en los equipos, Web Bluetooth en hardware y capturas de Explorar, Perfil, Administración y PWA instalada (equipos no conectados).

## 1.4.0 (26/11/2026) · retomar desde la primera fase sin marcar
Respaldo: etiqueta `respaldo-pre-1.4.0` y `C:/CESAR10cuatri/respaldos/pre-1.4.0_2026-11-26/` (memoria + Reporte final sin commit). Plan completo: Fases 1–6 del pedido del 26/11; adenda en `evidencias/v1_4/LEEME.md`.
- [x] Fase 1 · Campos de usuario sin espacios (Flutter `lib/core/sin_espacios.dart`, Kotlin `practicas/SinEspacios.kt`, API `@SinEspacios`). Pruebas: Flutter 23 (sin_espacios + AUT), JUnit app 5/5, Jest 89/89. API en PR CE0S23/CEOSMOSV2#2 **sin fusionar** (el permiso para fusionar a producción fue denegado): prod sigue sin la regla (Red Box prod 28/29, P-25 falla hasta fusionar).
- [x] Fase 2 · Reloj con 8 modos de simulación (`Simulador.kt`), «Sensor real» de pasos (contador → detector → acelerómetro), campo `act` en el protocolo, alertas de salud (`lib/core/alertas_salud.dart`: notificación «Alertas de salud» + POST_NOTIFICATIONS, aviso interno, Reloj, TV, `metadata.wearable`), interruptor en Perfil. La API no necesitó cambios (metadata ≤ 4096 B). Pruebas: Dart 373/373, Kotlin 30×3. **No verificado en equipos** (sin adb): `dumpsys sensorservice` de la Tab S9, notificación real y vibración. El commit incluye también el código de la Fase 3 (comparte archivos).
- [x] Fase 3 · Causas raíz corregidas (33f65f2) y medidas en S24 + Tab S9 el 26/11 (`evidencias/v1_4/botones_*`). ANTES (companion 1.0): Reloj toque 50/50 aceptadas por el periférico, TV toque 50/50, **TV D-pad: el foco se perdía tras CADA pulsación (5/5)**; latencia no medible (sin registro). DESPUÉS (1.4.0): Reloj 50/50 confirmadas (mediana 34,5 ms, p95 64), TV 50/50 (34 ms, p95 73), TV D-pad 30/30 sin perder el foco (85,5 ms, p95 104). El doble disparo sospechado no se reprodujo. Nuevo fallo hallado en equipo y corregido: la TV abría el enlace compartido mientras la app Reloj se reiniciaba y el Reloj ya no podía conectar (servicios en caché) → se redescubren.
- [x] Fase 4 · Tarjeta «Tu Reloj y TV» en Inicio (`lib/ui/tarjeta_equipos.dart`, misma en Android y PWA): estado de cada equipo, pulso con corazón, pasos, actividad, «hace N s», alerta activa, proyección de la TV, estado vacío con botón a Equipos y «Conectar». Prueba de widget (4), barrido de 91 tamaños con la tarjeta cargada (sin desbordes desde 240 dp; la columna de 200 dp sigue fuera de la regla) y fuente al 200 %. De paso: barra de sesión dentro del área desplazable en ventanas < 480 dp de alto. **Sin verificar en equipos.**
- [ ] Fase 5 · Equipos, Web Bluetooth, PWA, Lighthouse, capturas.
- [ ] Fase 6 · Cierre 1.4.0 (versión, pruebas, cifras, adenda, entrega-v5, CI, release/).

## Estado de las tareas pedidas (18/11)
- [x] Tarea 1 · Actividades 4–12 validadas (P7 completada el 19/11).
- [x] Tarea 2 · Requerimientos contrastados; BLE y TV desarrollados; BD propia por práctica verificada.
- [x] Tarea 3 · Apps Reloj y TV por BLE + central en CEOSMOS (ver [[06 - BLE Wearable y TV]]).
- [x] Tarea 4 · Pruebas reales en S24 y Tab S9 (BLE, P4, P5, P6, P9, P10; evidencias en `evidencias/`).
- [x] Tarea 5 · Black/White/Red Box (ver [[07 - Pruebas (Black, White, Red Box)]]).
- [x] Tarea 6 · Memoria reestructurada (esta carpeta) con respaldo.
- [x] Tarea 7 · Reporte Word actualizado (P7 completa desde el 19/11).
- [x] Cerrar P7 (19/11) → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]].

- **24/11/2026** — Revisión contra la rúbrica del profesor → [[14 - PWA y rúbrica]]:
  - [x] PWA: `web/sw.js` propio (el de Flutter 3.41 se desregistra solo), manifiesto completo, `scripts/construir_pwa.ps1`, tarea `pwa` en CI. Chrome: 0 errores de instalabilidad.
  - [x] Modo sin conexión (app y PWA): perfil + pendientes persistidos, reconexión automática; verificado en Chromium (sesión offline enviada una vez al volver la red).
  - [x] Web Bluetooth en la PWA (selector probado en Chromium; hardware no verificado) y mensajes para navegadores sin BLE.
  - [x] Avatar a media cabecera en tabletas corregido. Versión 1.3.0+5. 344/344 pruebas, analyze limpio.
  - [x] Reporte: planteamiento, objetivos, seguimiento, decisiones, arquitectura (diagramas), UX, PWA, dispositivos. Matriz de cumplimiento en `evidencias/rubrica/`. Respaldo previo en `C:/CESAR10cuatri/respaldos/rubrica_2026-11-24/`.
  - [ ] APK 1.3.0 en S24/Tab S9 y Web Bluetooth con el Reloj/TV reales (sin equipos conectados).

---
Navegación: [[00 - Índice CEOSMOS]] · [[08 - Pendientes]] · [[09 - Decisiones técnicas]]
