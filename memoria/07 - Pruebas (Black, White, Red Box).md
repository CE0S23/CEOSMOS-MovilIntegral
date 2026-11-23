---
tags: [ceosmos, pruebas]
estado: vigente
actualizado: 2026-11-19
---

# Pruebas (Black, White, Red Box)

## Resumen (18/11/2026)
- [x] `flutter analyze`: sin observaciones.
- [x] `flutter test`: **215/215** (unidad, widgets, Black Box P8, White Box P11/P12, BLE, prácticas y 27 de la P13-14).
- [x] Kotlin (compañeros): 14/14 por app (`ProtocoloTest` + `AutomatizacionProtocoloTest`); lint de Reloj, TV y Companion sin errores.
- [x] CI en GitHub Actions en cada push y PR → [[Práctica 13-14 - Automatización de pruebas y CI]].

## Black Box
- [x] Suite de la [[Práctica 08 - Pruebas de caja negra]] (12 requisitos, CP-01…CP-18).
- [x] En el S24: P4 (CRUD + correo + persistencia), P5 (7 requisitos, Logcat sin credenciales), BLE (todos los escenarios de [[06 - BLE Wearable y TV]]), Atrás en prácticas.
- [x] Entre S24 y tablet: P6 por Wi-Fi, matriz DB-01…DB-09 de la [[Práctica 09 - Base de datos compartida entre dispositivos]], SEG de la [[Práctica 10 - Seguridad y control de acceso]] (las dos reconfirmadas el 19/11).
- [x] P7 con los 4 roles entre S24 y tablet: matriz TC01–TC08 aprobada, chat en tiempo real, adjuntos ≤ 300 KB, asignación agente ↔ admin y presencia (19/11) → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]].

## White Box — cobertura (`flutter test --coverage --branch-coverage`)
| Módulo | Líneas | Ramas |
| --- | --- | --- |
| `core/ble/ble_protocolo.dart` | 100 % | 100 % |
| `core/ble/ecosistema_ble.dart` | 94.4 % | 85.3 % |
| `data/api_client.dart` | 96.5 % | 97.5 % |
| `core/app_state.dart` | 84.3 % | 74.3 % |
| Núcleo (`core`, `data`, `domain`) | 78.9 % | 72.0 % |

`ble_transporte_fbp.dart` (0 %) es el adaptador de la radio: se valida en hardware, no con pruebas unitarias.

## Automatización y CI (P13-14)
- [x] Matriz AUT-01…AUT-08 aprobada; regresión DEF-BLE-01 demostrada (falla con el código viejo).
- [x] Integración con red real local (servidor HTTP en 127.0.0.1), mensaje sin servidor en pantalla y SQLite FFI con migración de la P4.
- [x] Riesgo resuelto: pruebas BLE con espera fija fallaban bajo `--coverage` → espera por condición.

## Red Box
- [x] API local, `scripts/redbox_api.sh` → **13/13** (`evidencias/redbox_api.txt`): sin token/alterado/`alg:none` → 401, inyección SQL en login, IDOR (leer/modificar/borrar dispositivo ajeno → 404), asignación masiva y validación → 400, cuerpo de 2 MB rechazado, USER en `/admin` → 403, sin hash en respuestas, token tras logout → 401.
- [x] APK release: no depurable, `allowBackup=false`, solo `MainActivity` (y las de Firebase Auth) exportadas, texto claro solo a `localhost`/`10.0.2.2`, sin tokens ni contraseñas en logs.
- [x] BLE: dispositivo no autorizado no puede escribir ni suscribirse (prueba automatizada y en hardware: «Escritura rechazada: central no autenticado»).
- [x] P10: suplantación pura de propietario, lectura/modificación/eliminación ajena y acceso sin sesión rechazados por las reglas de Firestore.
- [x] P7: usuario2 no puede leer el ticket de usuario1; la cuenta debe tener documento de rol y coincidir con la URL; la API key restringida a paquete + SHA-1 sigue funcionando.

## Blindaje (21–22/11)
- [x] **331/331** pruebas Flutter; API 79/79; companion test + lint; CI verde.
- [x] Red Box 13/13 + 37/37 (local) y **27/27 en producción** sin credenciales (`scripts/redbox_produccion.sh`); las 6 correcciones de la API están en producción.
- [x] Reloj y TV de punta a punta en S24 + Tab S9 (6/7; reconexión sin PIN corregida con latido BLE, 4 pruebas de regresión); F-05 con admin, agente y usuario1.
- Resumen, cifras, límites y no verificados: [[13 - Blindaje]] · `evidencias/blindaje/masvs.md`

## Riesgos que quedan (con mitigación)
- [ ] APK firmado con llave de depuración → crear keystore propio (ver [[08 - Pendientes]]).
- Riesgo aceptado: credencial de práctica `alumno/ClaveDemo2026` en Kotlin (P5, simulada por diseño de la práctica).
- Riesgo aceptado: claves de cliente Firebase en el código de las prácticas (públicas por diseño; las protegen las reglas).
- [ ] Limitador de la API en memoria por instancia de Vercel → Upstash Redis (ver [[08 - Pendientes]]).
- [ ] P10 «cesión»: A puede crear una incidencia a nombre de B si registra `cedidoPor` → exigir aceptación de B (ver [[08 - Pendientes]]).

---
Navegación: [[00 - Índice CEOSMOS]] · [[Práctica 08 - Pruebas de caja negra]] · [[Práctica 11 - Pruebas White Box]] · [[Práctica 12 - Optimización, estrés y resiliencia]] · [[Práctica 13-14 - Automatización de pruebas y CI]] · [[08 - Pendientes]]
