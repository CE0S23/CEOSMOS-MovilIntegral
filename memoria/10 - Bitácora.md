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
- [~] Fase 5 · a) APK 1.4.0 con install -r en S24 (CEOSMOS) y Tab S9 (CEOSMOS, Reloj, TV): misma fecha de primera instalación, sesión y PIN/id intactos, emparejamiento reconectado; ojo: el primer arranque del S24 tras instalar mostró «No hay conexión» y entró al reiniciar la app. Sensores Tab S9: contador y detector de pasos (Samsung) + acelerómetro; «Sensor real» probado con permiso concedido. Alertas probadas de punta a punta (S24 → Reloj y TV). d) Lighthouse móvil 61/92/82/100, escritorio 70/92/81/100; instalabilidad 0 errores; los 2 hallazgos son del motor de Flutter web. e) Capturas en `evidencias/v1_4/` (Reloj 8 modos + sensor real, TV con alerta, Explorar y Perfil desde la tablet). **PENDIENTE (el S24 se bloqueó con su PIN de pantalla):** b) Web Bluetooth en Chrome del S24, c) instalar la PWA en el S24, capturas del S24 (Inicio con la tarjeta, alerta en la app, PWA instalada) y el permiso de notificaciones (notificación del sistema no verificada).
- [x] Fase 6 · 1.4.0+6 (companion 1.4.0, versionCode 2). Flutter 374/374 (cobertura 58.1 %, núcleo 84.7 %), Kotlin 30×3 + 5, API 89/89 (rama del PR). `cifras.md` y adenda `evidencias/v1_4/LEEME.md`; notas 08, 12 y 13; etiqueta `entrega-v5`; APK en `release/` (SHA256SUMS). Búsqueda de credenciales: 14 cadenas candidatas, **177 coincidencias sin desglosar** (heurística amplia; no se pudo releer el archivo) → revisar. Ver CI en Actions.

## Pruebas con cuentas 1.4.0 (26/11/2026) · retomar desde el primer bloque sin marcar
Estado inicial: S24 con CEOSMOS «Ceos» (USER) + Reloj y TV conectados; Tab S9 con CEOSMOS «osva», Reloj y TV 1.4.0. Credenciales solo en memoria (bóveda local en el scratchpad), nunca escritas.
- [x] B1 · 1.4.0 en ambos equipos; API prod `/health` 200; Postgres local 5433 y API local en **8081** (el `scripts/dev_backend.ps1` arranca MediConnect con PORT=8080 heredado y la API no levanta: corregir).
- [x] B2 · Prod, 3 cuentas en el S24 (OSVA = ADMIN, osva y Ceos = USER): acceso, espacios rechazados (acceso, PWA y editar usuario), tarjeta de Inicio, favoritos (guardar/filtrar/quitar), sesión de 5 min (pausa congela, terminar → historial; la app no ofrece 1 min), Reloj y TV conectados, notificaciones del sistema «Pulso alto en reposo», «Pulso muy alto» y «Pulso bajo», correr 90 s sin alerta, cierre y reapertura. Admin en solo lectura (lista y bitácora; la app no tiene búsqueda). PWA instalada (WebAPK) con **Web Bluetooth real: Reloj y TV conectados con PIN y lecturas en vivo**. Hallazgos: aviso «sin espacios» con ícono invisible y tapado en diálogos; «1 sesiones»/«1 experiencias»; Web Bluetooth descartaba el equipo vinculado (sin datos de fabricante) → corregido; un ciclo no dio «pulso bajo» en 70 s (al repetir sí). Cada cuenta quedó con 1 sesión de enfoque nueva en su historial (la app no permite borrarlas). Una sola sesión activa por cuenta (diseño de la API).
- [x] B3 · Local (26/11, sesión 2): API local en 8081 + PWA local (4201) con admin@ceosmos.test (ADMIN): «QA-usuario» → ADMIN → USER, desactivado y reactivado. **Fallo hallado y corregido:** bloquear/desbloquear no quedaba en la bitácora (solo ROLE_CHANGE) → acción `USER_STATUS_CHANGE` en la API (rama `espacios-1.4.0`, migración `20261126220000_auditoria_estado`, prueba `src/admin/auditoria-estado.spec.ts`; Jest 91/91; aplicada solo a la base local). Capturas sin datos personales: `evidencias/v1_4/pruebas_cuentas/admin_local_*.png`. «QA-usuario» eliminado de la base local (0 usuarios QA-).
- [x] Paso 0/1 (sesión 2) · CI de c74065d en verde; Fases 3–6 en código completas (nada que completar), `entrega-v5` en 3d63f33. Fallos: a) alertas — causa raíz: tope de 5 alertas COMPARTIDO por sesión (tras 5 de cualquier tipo no llegaba ninguna), ruido ±1 bpm justo en el umbral (baja 35–45 vs ≤45) que reiniciaba el «sostenido», y «muy alto» sin modo propio (dependía del azar en «alta» 150–190, 4 bpm/s). Corrección: histéresis ±3 bpm + tolerancia 2 s, enfriamiento por tipo, una alerta por episodio (recordatorio 5 min), sin tope compartido; Reloj con modo «Frecuencia muy alta» (190–210), alta 125–175, baja 36–43 y 8 bpm/s en modos de alerta. Réplica del simulador en `test/support/simulador_reloj.dart` y `test/ble/alertas_latencia_test.dart`; script de equipo `scripts/medir_alertas.sh`. b) aviso «sin espacios» en el Overlay raíz (encima de los diálogos), ícono con color propio (contraste ≥ 4.5) y región viva; nativo p10 con liveRegion. c) `lib/core/plural.dart` (`contar`) + `Plural.kt` (app y companion), 14 textos Flutter y 8 nativos; prueba que barre `lib/`. d) `dev_backend.ps1`: API en 8081 (`-ApiPort`), PORT restaurado antes de MediConnect (sigue en 3443), aviso y salida 2 si el puerto está ocupado (probado); app/PWA/scripts en 8081.
- [x] Medición de alertas en equipos (S24 «Ceos» + Reloj de la Tab S9, 10 × cada alerta, plazo 70 s, `evidencias/v1_4/pruebas_cuentas/alertas_*.txt`). ANTES: alta 1/10 (17,8 s), muy alta 0/10, baja 1/10 (17,3 s) → 28/30 fallidas (desde la 2.ª ronda ninguna: tope compartido). DESPUÉS (APK y companion nuevos, install -r, sesión y fecha de instalación intactas): alta 10/10 (mín 13,3 · mediana 13,9 · máx 14,4 s), muy alta 10/10 (16,8 · 18,2 · 19,1 s), baja 10/10 (16,8 · 18,5 · 19,8 s) → 0 fallidas. Nota: la 1.4.0 de `release/` se firma con la llave de depuración; para install -r se compiló apartando `android/key.properties` (se restauró).
- [~] B4 · Funciones Firebase y locales. practica7-8: los 4 documentos `dispositivos/{uid}` YA existían (admin, agente, usuario1, usuario2 con nombre/rol/conectado/ultimaConexion) → no se creó nada. TC01–TC08 con las 4 cuentas, mesaayuda-p7 (a/b) y funciones locales: **sin verificar en esta sesión** (el dueño pidió cerrar). TC07 requiere cortar la red del teléfono (prohibido por las reglas). F-14: pendiente (no había Gmail abierto en el Chrome conectado).
- [x] B5 · Cierre (26/11): Flutter 384/384 + analyze limpio, Kotlin app 6/6 y companion (Simulador 11, Plural 1), Jest API 91/91. Búsqueda de contraseñas contra el archivo de credenciales (5 valores, repo + memoria + evidencias + memoria de Claude + API + historial git, sin imprimir): **0 coincidencias** (excluida `.devdb/`, base local ignorada por git, que guarda las cuentas de desarrollo). S24 con «Ceos», Reloj y TV conectados; `stay_on_while_plugged_in` devuelto a 0 en ambos equipos.

| Función | Cuenta | Resultado |
|---|---|---|
| Administración: rol ADMIN↔USER | admin local → QA-usuario | ✅ bitácora ROLE_CHANGE |
| Administración: bloquear/desbloquear | admin local → QA-usuario | ✅ tras corregir (USER_STATUS_CHANGE) |
| USER no ve Administración | usuario QA local | ✅ |
| Alertas alta / muy alta / baja | Ceos (prod) + Reloj | ✅ 30/30 (antes 2/30) |
| Aviso «sin espacios» en diálogo | pruebas de widget | ✅ (equipo: no repetido) |
| practica7-8 dispositivos/{uid} | admin, agente, usuario1, usuario2 | ✅ ya existían |
| TC01–TC08 Soporte | 4 cuentas | ⏸ no verificado |
| mesaayuda-p7 (Reportes, tiempo real, conflicto, bitácora, Mis incidencias) | a, b | ⏸ no verificado |
| Funciones locales (sin conexión, TCP, Seguridad, Directorio, Citas) | — | ⏸ no verificado |
| F-14 código por correo | — | ⏸ pendiente |

- [ ] B5 · Cierre.

## Cierre completo 1.4.0 (26/11/2026, sesión 3) · retomar desde la primera fase sin marcar
- [x] Fase 1 · Documentos del dueño revisados (0 credenciales, sin llaves/tokens) y subidos sin cambios (`0539e5d`). PR #2 **NO fusionado**: `USER_STATUS_CHANGE` es un valor nuevo del enum PostgreSQL `AuditAction` y la build de Vercel corre `prisma migrate deploy`, así que fusionar = migrar Neon. Sin migrar, la escritura de la bitácora falla en silencio (try/catch) y el bloqueo sigue funcionando. Pruebas de administración mutantes: solo locales.
- [x] Fase 2 · 1.4.0+7 (versionCode 7; Reloj/TV versionCode 3, `4bb45c4`) con llave de depuración (`key.properties` apartado y devuelto idéntico, SHA-256 comprobado) e install -r: S24 y Tab S9 con la misma fecha de primera instalación y sesión. S24 pasó de «Ceos» a «OSVA» (ADMIN); la tablet tenía la sesión de «osva» cerrada y se volvió a entrar.
- [x] Fase 3 · Pruebas completas (26/11, S24 = «OSVA» ADMIN, Tab S9 = «osva» USER). Fallos nuevos: ninguno en esta ronda. No verificado en esta sesión (cierre pedido con prisa): PWA con «Ceos» (Web Bluetooth, ventana propia, sin conexión, Lighthouse), Explorar/biblioteca (enlaces javascript:, longitudes), D-pad y 50 pulsaciones (medidos en la Fase 3 de 1.4.0), Bluetooth apagado/encendido, Wearable por Wi-Fi, reinicio del Reloj/TV sin PIN, F-14. Administración mutante en producción: no (PR #2 sin fusionar; hecho en local en B3).

| Función | Cliente | Cuenta | Resultado |
|---|---|---|---|
| Acceso: aviso «sin espacios» (ícono + texto, anunciado) | S24 app | — | ✅ |
| Acceso: correo inexistente → error genérico | S24 app (prod) | — | ✅ |
| Acceso y cierre de sesión | S24 / Tab S9 | OSVA / osva | ✅ |
| Administración visible y carga (solo lectura) | S24 | OSVA (ADMIN) | ✅ |
| Sin Administración | Tab S9 | osva (USER) | ✅ |
| Reloj y TV conectados, 6 actividades | S24 + Tab S9 | OSVA | ✅ |
| Alertas alta / muy alta / baja + notificación del sistema | S24 | OSVA | ✅ (1/1 c/u; 30/30 antes en +6) |
| Mi sesión: pausa, confirmación, historial solo del dueño, «1 sesión» | Tab S9 / S24 | osva / OSVA | ✅ |
| Tickets: acceso sin espacios, TC01 turno, TC02, TC03, TC06, TC08 | S24 + Tab S9 | admin, usuario1, usuario2 | ✅ |
| Chat usuario→admin en tiempo real; admin→usuario por consulta (diseño) | S24 + Tab S9 | admin / usuario1 | ✅ |
| Adjunto 159 KB aceptado / 475 KB rechazado | Tab S9 | usuario1 | ✅ |
| Asignación agente→admin→agente, prioridad, presencia | ambos | agente / admin | ✅ |
| Eliminar ticket y limpiar historial | S24 | admin | ✅ (REP777 QA) |
| Incidencias en tiempo real, conflicto por campo, bitácora | A=S24, B=Tab S9 | — | ✅ |
| Mis incidencias: sin sesión rechazado, aislamiento a/b | S24 / Tab S9 | a / b | ✅ |
| Reportes compartidos Flutter y Kotlin (CRUD; ajenos no legibles por regla) | S24 / Tab S9 | anónimas | ✅ |
| Incidencias sin conexión (persisten, borrar) | S24 | — | ✅ |
| Directorio (alta, consulta, edición, baja, correo y espacios, «1 año») | S24 | — | ✅ |
| Seguridad de la cuenta (espacios, mínimo 8, error genérico) | S24 | — | ✅ |
| Citas de bienestar (acceso y consulta) | S24 + servidor local | cuenta demo del servidor | ✅ |
| Mensajería entre equipos TCP en ambos sentidos | S24 ↔ Tab S9 | — | ✅ |
| PWA, Web Bluetooth, sin conexión, Lighthouse | — | Ceos | ⏸ no verificado |
| F-14 código por correo | — | — | ⏸ pendiente |
- [x] Fase 5 · Cierre: etiqueta `entrega-v6` en el commit final; APK en `release/` (`*entrega-v6*`, SHA-256 en `SHA256SUMS.txt`; `release/` no se versiona y el repo no publica Releases de GitHub → no se publicó nada). Producción: Red Box 28/29 (solo P-25, espacios en la contraseña, hasta fusionar el PR #2; la primera repetición inmediata dio 429 por el limitador de P-23 y se repitió a los 2,5 min); `verificar_produccion.ps1` se omite con sesión iniciada, la comprobación equivalente («Correo o contraseña incorrectos.» desde producción) se hizo a mano en el S24. QA limpiado: REP777 (historial y ticket), QA-INC_CIERRE, REP778/REP779, incidencia local, alumno QA e imágenes de la tablet. «osva» y «Ceos» sin cambios (USER, activos). `stay_on_while_plugged_in` = 0 en ambos; adb reverse 3443 quitado. Búsqueda de contraseñas (5 valores, sin imprimir): **0 en archivos** (repo, memoria, evidencias, memoria de Claude, API) y **0 en el historial de este repo**, pero **1 en el historial del repo de la API**: commit `4726986` (11/08/2026, `payload.json`) con la contraseña de las cuentas CEOSMOS; está en la rama local `backup-antes-de-rollback` y GitHub (CEOSMOSV2, público) aún lo sirve por SHA aunque ninguna rama lo incluye → **rotar esa contraseña** y pedir a GitHub Support la purga del commit (no se tocó nada). Estado final: S24 «OSVA» con Reloj y TV conectados; Tab S9 «osva», Reloj y TV abiertos.

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
