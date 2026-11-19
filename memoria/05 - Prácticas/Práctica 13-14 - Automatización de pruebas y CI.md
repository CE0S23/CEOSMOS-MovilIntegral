---
tags: [ceosmos, practica, pruebas, ci]
estado: cumple
actualizado: 2026-11-18
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
- [x] AUT-08 CI · PR (run #2) y nuevos push tras las correcciones (runs #3–#6; #5–#6 sin avisos)

## Resultados
- [x] Local: Flutter 215/215 (analyze 42 s, test 69 s), Kotlin 14/14 por variante (107 s con lint de 3 apps). Cobertura 49.5 % total; `api_client` y `ble_protocolo` 100 %.
- [x] CI verde en push y PR: [run #1](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433685785), [#2](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44433707000), [#3](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434252590), [#4](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44434260779), [#5](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44435739612), [#6](https://github.com/CE0S23/CEOSMOS-MovilIntegral/actions/runs/44435747347).
- [x] Errores corregidos: 3 de lint del companion, prueba BLE dependiente del tiempo, `gradlew` sin permiso de ejecución, acciones obsoletas (Node 20), secreto antiguo redactado del historial.
- [x] Reporte Word `evidencias/p13_14/Practicas 13-14 - Automatizacion de pruebas - CEOSMOS.docx` y entrada en el Reporte de avances.
- [ ] Fusionar el PR #1 a `main` (decisión del usuario).
- Nota: las prácticas de pruebas (P8, P11, P12, P13-14) no tienen entrada en la ventana Prácticas: no tienen pantalla propia.

- Informe completo: [[REPORTE_P13_14_AUTOMATIZACION]]

Volver: [[00 - Índice CEOSMOS]] · Pruebas: [[07 - Pruebas (Black, White, Red Box)]] · [[Práctica 11 - Pruebas White Box]] · [[Práctica 12 - Optimización, estrés y resiliencia]]
