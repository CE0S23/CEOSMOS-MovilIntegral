---
tags: [ceosmos, pruebas]
estado: vigente
actualizado: 2026-11-18
---

# Pruebas (Black, White, Red Box)

## Resumen (18/11/2026)
- [x] `flutter analyze`: sin observaciones.
- [x] `flutter test`: **188/188** (unidad, widgets, Black Box P8, White Box P11/P12, BLE, prácticas).
- [x] Kotlin (compañeros): 9/9 (`ProtocoloTest`, vectores HMAC iguales a los de Dart).

## Black Box
- [x] Suite de la [[Práctica 08 - Pruebas de caja negra]] (12 requisitos, CP-01…CP-18).
- [x] En el S24: P4 (CRUD + correo + persistencia), P5 (7 requisitos, Logcat sin credenciales), BLE (todos los escenarios de [[06 - BLE Wearable y TV]]), Atrás en prácticas.
- [x] Entre S24 y tablet: P6 por Wi-Fi, matriz DB-01…DB-09 de la [[Práctica 09 - Base de datos compartida entre dispositivos]], SEG de la [[Práctica 10 - Seguridad y control de acceso]].

## White Box — cobertura (`flutter test --coverage --branch-coverage`)
| Módulo | Líneas | Ramas |
| --- | --- | --- |
| `core/ble/ble_protocolo.dart` | 100 % | 100 % |
| `core/ble/ecosistema_ble.dart` | 94.4 % | 85.3 % |
| `data/api_client.dart` | 96.5 % | 97.5 % |
| `core/app_state.dart` | 84.3 % | 74.3 % |
| Núcleo (`core`, `data`, `domain`) | 78.9 % | 72.0 % |

`ble_transporte_fbp.dart` (0 %) es el adaptador de la radio: se valida en hardware, no con pruebas unitarias.

## Red Box
- [x] API local, `scripts/redbox_api.sh` → **13/13** (`evidencias/redbox_api.txt`): sin token/alterado/`alg:none` → 401, inyección SQL en login, IDOR (leer/modificar/borrar dispositivo ajeno → 404), asignación masiva y validación → 400, cuerpo de 2 MB rechazado, USER en `/admin` → 403, sin hash en respuestas, token tras logout → 401.
- [x] APK release: no depurable, `allowBackup=false`, solo `MainActivity` (y las de Firebase Auth) exportadas, texto claro solo a `localhost`/`10.0.2.2`, sin tokens ni contraseñas en logs.
- [x] BLE: dispositivo no autorizado no puede escribir ni suscribirse (prueba automatizada y en hardware: «Escritura rechazada: central no autenticado»).
- [x] P10: suplantación pura de propietario, lectura/modificación/eliminación ajena y acceso sin sesión rechazados por las reglas de Firestore.

## Riesgos que quedan (con mitigación)
- [ ] APK firmado con llave de depuración → crear keystore propio (ver [[08 - Pendientes]]).
- [ ] Credencial de práctica `alumno/ClaveDemo2026` en Kotlin (P5, simulada por diseño de la práctica).
- [ ] Claves de cliente Firebase en el código de las prácticas (públicas por diseño; las protegen las reglas).
- [ ] Limitador de la API en memoria por instancia de Vercel → Upstash Redis.
- [ ] P10 «cesión»: A puede crear una incidencia a nombre de B si registra `cedidoPor` → exigir aceptación de B.
