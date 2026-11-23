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

## Estado de las tareas pedidas (18/11)
- [x] Tarea 1 · Actividades 4–12 validadas (P7 completada el 19/11).
- [x] Tarea 2 · Requerimientos contrastados; BLE y TV desarrollados; BD propia por práctica verificada.
- [x] Tarea 3 · Apps Reloj y TV por BLE + central en CEOSMOS (ver [[06 - BLE Wearable y TV]]).
- [x] Tarea 4 · Pruebas reales en S24 y Tab S9 (BLE, P4, P5, P6, P9, P10; evidencias en `evidencias/`).
- [x] Tarea 5 · Black/White/Red Box (ver [[07 - Pruebas (Black, White, Red Box)]]).
- [x] Tarea 6 · Memoria reestructurada (esta carpeta) con respaldo.
- [x] Tarea 7 · Reporte Word actualizado (P7 completa desde el 19/11).
- [x] Cerrar P7 (19/11) → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]].

---
Navegación: [[00 - Índice CEOSMOS]] · [[08 - Pendientes]] · [[09 - Decisiones técnicas]]
