---
tags: [ceosmos, practica]
estado: cumple
actualizado: 2026-11-19
---

# Práctica 12 · Optimización, estrés y resiliencia

**En CEOSMOS:** `p11yp12/p12/`; `lib/core/reintentos.dart` (backoff exponencial con fluctuación), `clientId` idempotente, historial paginado, reloj aislado.
- [x] Estrés de la API local, profiling, pruebas de BD, matriz RES-01…RES-09, comparación antes/después (commit del 18/11).
- [x] 19/11: confirmada sin rehacer (pruebas `test/p12` en `flutter test` 215/215; en el S24 la app queda «Sincronizado» con la API y la P7 sincroniza al volver la red).
- [x] Resiliencia también en BLE: reconexión con espera progresiva y sin gastar intentos sin Bluetooth.

- Informe completo: [[REPORTE_P12_OPTIMIZACION]]

Volver: [[00 - Índice CEOSMOS]] · Pruebas: [[07 - Pruebas (Black, White, Red Box)]]
