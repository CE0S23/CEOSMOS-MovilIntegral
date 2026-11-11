# Práctica 8 · Reporte de ejecución de caja negra

**Proyecto:** CEOSMOS Móvil Integral  
**Fecha local:** 2026-10-23 17:47:07 -06:00  
**Comando:** `flutter test test/practica8_black_box_test.dart --no-pub --reporter json`  
**Salida:** 0  
**Resultado:** ACEPTACIÓN del alcance local evaluado

**Ejecuciones:** 21; PASS: 21; FAIL: 0; omitidas: 0. **Requisitos cubiertos:** 12/12.

| Caso | Requisito | Comportamiento observable | Estado |
|---|---|---|---|
| CP-01 | REQ-VAL-01 | nombre de un carácter se rechaza | PASS |
| CP-02 | REQ-VAL-01 | contraseña de siete caracteres se rechaza | PASS |
| CP-03 | REQ-VAL-01 | correo sin arroba se rechaza | PASS |
| CP-04 | REQ-VAL-01 | registro válido normaliza el correo | PASS |
| CP-05 | REQ-VAL-02 | correo duplicado se rechaza | PASS |
| CP-06 | REQ-VAL-02 | contraseña incorrecta no concede acceso | PASS |
| CP-07 | REQ-OP-02 | búsqueda normaliza acentos y muestra vacío | PASS |
| CP-08 | REQ-OP-02 | filtros de modo y tipo se combinan | PASS |
| CP-09 | REQ-OP-03 | favoritos se agregan y eliminan | PASS |
| CP-10 | REQ-OP-01 | sesión pausa, continúa y termina una vez | PASS |
| CP-11 | REQ-OP-04 | Band y TV se vinculan y desvinculan | PASS |
| CP-12 | REQ-DAT-01 | espacios de dos cuentas permanecen aislados | PASS |
| CP-13 | REQ-DAT-02 | historial conserva una finalización | PASS |
| CP-14 | REQ-NAV-01 | acceso privado se revoca al vencer | PASS |
| CP-15-320 | REQ-NAV-02 | navegación sin overflow a 320 px | PASS |
| CP-15-390 | REQ-NAV-02 | navegación sin overflow a 390 px | PASS |
| CP-15-768 | REQ-NAV-02 | navegación sin overflow a 768 px | PASS |
| CP-15-1440 | REQ-NAV-02 | navegación sin overflow a 1440 px | PASS |
| CP-16 | REQ-ERR-01 | fallo de audio muestra aviso y conserva sesión | PASS |
| CP-17 | REQ-VAL-03 | duración inválida se rechaza sin cambiar preferencia | PASS |
| CP-18 | REQ-DAT-02 | sesión completa guarda 05:00 una sola vez | PASS |

## Alcance y límites de la evidencia

- La suite envía acciones a formularios, botones, filtros y navegación Flutter; observa textos, controles y errores visibles. El reloj y un fallo del canal de audio se inyectan como condiciones externas controladas.
- CP-17 prueba valores de duración inválidos en la interfaz pública de estado, pues la UI solo ofrece 5, 15, 25 y 45 minutos.
- Los datos se conservan solo mientras vive la instancia de la app. No se acredita persistencia tras reinicio, API, JWT, WebAuthn, BLE, TCP/IP ni sensores físicos.
- La prueba de widgets no demuestra comportamiento en un dispositivo Android real, rendimiento, audio audible ni ausencia de fugas de memoria.
- Los eventos JSONL y el CSV de casos en esta carpeta permiten auditar el dictamen. Si Flutter no emitió resultados, el dictamen es rechazo por falta de evidencia.
