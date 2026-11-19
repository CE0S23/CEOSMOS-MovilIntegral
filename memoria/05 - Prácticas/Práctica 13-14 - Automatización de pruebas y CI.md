---
tags: [ceosmos, practica, pruebas, ci]
estado: cumple
actualizado: 2026-11-19
repo: https://github.com/CE0S23/CEOSMOS-MovilIntegral
pr: https://github.com/CE0S23/CEOSMOS-MovilIntegral/pull/1
---

# Prácticas 13 y 14 · Automatización de pruebas y validación continua

**En CEOSMOS:** `test/p13_14/`, `test/support/servidor_api_local.dart`, `companion/app/src/test/.../AutomatizacionProtocoloTest.kt`, `.github/workflows/ci.yml`, `scripts/p13_14_regresion.sh`, `scripts/resumen_pruebas.py`, evidencias en `evidencias/p13_14/`.

## Componentes críticos
- [x] Acceso (login/registro/verificación): validadores extraídos de la UI a `AuthRepository` y a la P4, sin cambiar mensajes.
- [x] Comunicación: `ApiClient` real contra servidor HTTP local y protocolo BLE reto + HMAC (Dart y Kotlin) → [[06 - BLE Wearable y TV]].
- [x] Persistencia: P4 en SQLite (FFI) con migración v1→v2 del correo → [[Práctica 04 - Almacenamiento estructurado]].

## Defecto previo que se previene
- [x] DEF-BLE-01 «TV reiniciada seguía Conectado»: la prueba falla con `1a8f98c^` y pasa con el código actual (`regresion_codigo_viejo.txt` / `regresion_codigo_nuevo.txt`).

## Matriz AUT
- [x] AUT-01 Unitarias · válida y vacía/nula (4/4)
- [x] AUT-02 Unitarias · fuera de rango y resultado esperado (7/7 Dart + 5/5 Kotlin)
- [x] AUT-03 Unitarias · excepciones + regresión DEF-BLE-01 (4/4, demostrada)
- [x] AUT-04 Integración · HTTP real 200/201/400/401/404 (4/4)
- [x] AUT-05 Integración · sin servidor → mensaje en pantalla (2/2, widget)
- [x] AUT-06 Persistencia · CRUD en memoria + migración (5/5)
- [x] AUT-07 CI · push (run #1, 2 min 55 s)
- [x] AUT-08 CI · PR (run #2) y nuevos push tras las correcciones (runs #3–#8; #5–#8 sin avisos) y merge en main (run 44438169735)

## Resultados
- [x] Local: Flutter 215/215 (analyze 42 s, test 69 s), Kotlin 14/14 por variante (107 s con lint de 3 apps). Cobertura 49.5 % total; `api_client` y `ble_protocolo` 100 %.
- [x] CI verde en push y PR: [run #1](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433685785), [#2](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433707000), [#3](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434252590), [#4](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434260779), [#5](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44435739612), [#6](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44435747347).
- [x] Errores corregidos: 3 de lint del companion, prueba BLE dependiente del tiempo, `gradlew` sin permiso de ejecución, acciones obsoletas (Node 20), secreto antiguo redactado del historial.
- [x] Reporte Word `evidencias/p13_14/Practicas 13-14 - Automatizacion de pruebas - CEOSMOS.docx` y entrada en el Reporte de avances.
- [x] PR #1 fusionado a `main` con merge commit (18/11); CI en main en verde: [run 44438169735](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44438169735) (3 min 17 s).

## Cierre (18/11 ~19:55, entregables terminados el 19/11)
Hecho en el cierre:
- [x] Inventario de secretos: `DATABASE_URL`, `DIRECT_URL` y `JWT_SECRET` se usan solo en las variables de Vercel de `ceosmos-api` y en `WEBANGULAR/.env` y `WEBANGULAR/ceosmos-api/.env`. No hay secrets de GitHub Actions en ningún repo; CEOSMOSV2 no tiene workflows (el `prisma migrate deploy` lo hace el build de Vercel). Los dos secretos filtrados **seguían vigentes**.
- [x] `.bundle` de respaldo borrado y objetos viejos purgados del `.git` local (`reflog expire` + `gc --prune=now`).
- [x] Claves API restringidas en Google Cloud (paquete `com.ceosmos.ceosmos_movil_integral` + SHA-1 de la llave de depuración, que también firma el release): practica7-8 (Android key → apps Android; Browser key → referentes `localhost`/`127.0.0.1`) y reportes-movil-20261019 (igual). Siguen con las 25 APIs de Firebase (no se acotó más).
- [x] Prueba en el S24 de reportes-movil con la clave restringida: alta, consulta en servidor y baja de REP001 correctas (`evidencias/p13_14/firebase_01_reportes_movil_restringida_ok.png`).

Falta:
- [ ] **Usuario:** Neon › proyecto CEOSMOS › rol `neondb_owner` › Reset password; actualizar `DATABASE_URL` (pooler) y `DIRECT_URL` en Vercel `ceosmos-api`; nuevo `JWT_SECRET` (usar un generador seguro, p. ej. `[Security.Cryptography.RandomNumberGenerator]`, no `Get-Random`); Redeploy; poner los 3 valores en los dos `.env` de WEBANGULAR.
- [ ] Después de la rotación: healthcheck de la API en producción; la sesión actual del S24 (token emitido con el secreto viejo) debe dar 401 y mandar al acceso; el usuario inicia sesión en el S24 (yo no escribo contraseñas reales) y luego registro/consulta de datos.
- [ ] P7 con la clave restringida: falta comprobar que Firebase Auth responde. El intento con `usuario1.ceosmos.p7@…` no llegó a Firebase porque la pantalla solo admite los correos `*.p7@example.com` del mapa `_correosPorRol` (no tocar la P7). Reintentar con `usuario1.p7@example.com` y una contraseña errónea: se espera «Correo o contraseña incorrectos», no un error de clave bloqueada. El S24 se desconectó del adb.
- [ ] **Usuario:** el proyecto `mesaayuda-p7` (P9/P10) no es accesible con 2023371167@uteq.edu.mx; restringir su clave desde la cuenta dueña (mismo paquete + SHA-1), o darme acceso.
- [ ] Cerrar las 4 alertas de *secret scanning* (`gh api -X PATCH repos/CE0S23/CEOSMOS-MovilIntegral/secret-scanning/alerts/<n> -f state=resolved -f resolution=revoked` o `used_in_tests` + comentario): #4 y #1 = practica7-8; #2/#3 = reportes-movil y mesaayuda-p7 (cerrar mesaayuda solo cuando esté restringida).
- [x] Logs del run de main (`ci_run_44438169735.txt`), #7 (`ci_run_44436386979.txt`) y #8 (`ci_run_44436395949.txt`) en `evidencias/p13_14/`, y captura de Actions con main en verde (`ci_04_actions_main_verde.png`) (19/11).
- [x] Reporte Word P13-14 completado (19/11): filas de los runs #5–#9 en Resultados, tiempo total, sección 6 «Evidencia de ejecución automática» con las URLs de los 9 runs (incluido main tras el merge), AUT-07/08 actualizadas; 2 páginas, 11 pt mínimo. Respaldo del original en el scratchpad de la sesión.
- [x] Commit + push a `main` de las evidencias, el Word, la memoria y la captura `firebase_01` (19/11); `firebase_02` (P7) quedó fuera porque estaba vacía (0 bytes).
- [ ] Marcar [x] en [[08 - Pendientes]] la rotación y las alertas cuando terminen.
- Nota: las prácticas de pruebas (P8, P11, P12, P13-14) no tienen entrada en la ventana Prácticas: no tienen pantalla propia.

- Informe completo: [[REPORTE_P13_14_AUTOMATIZACION]]

Volver: [[00 - Índice CEOSMOS]] · Pruebas: [[07 - Pruebas (Black, White, Red Box)]] · [[Práctica 11 - Pruebas White Box]] · [[Práctica 12 - Optimización, estrés y resiliencia]]
