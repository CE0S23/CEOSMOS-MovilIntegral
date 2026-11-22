# Auditoría de dependencias · 22/11/2026

| Componente | Herramienta | Resultado | Acción |
|---|---|---|---|
| App Flutter (`pubspec.lock`) | OSV-Scanner 2.7.1 | **0 vulnerabilidades** | — |
| App Flutter | `flutter pub outdated` | 13 directas con versiones nuevas (p. ej. Firebase 7.x, `file_picker` 13, `flutter_secure_storage` 11); ninguna con aviso de seguridad | Se dejan: son cambios mayores a días de la entrega (aceptado) |
| API, dependencias de producción | `npm audit --omit=dev` | **0** | — |
| API, herramientas de desarrollo | `npm audit` / OSV | 26 (1 alta `brace-expansion` ReDoS, 25 moderadas) → **19 moderadas** tras `npm audit fix` compatible | La alta quedó corregida (rama `blindaje-api`, commit `3617c0d`, 79/79). Las 19 restantes exigen Jest 29 y Nest CLI 12 (mayores); solo corren en la máquina del desarrollador y en la build, no en la función desplegada (aceptado) |
| Companion (Reloj y TV), dependencias directas | OSV API (consulta por coordenada Maven) | `org.json:20180813` (solo pruebas) con 3 avisos DoS; el resto 0 | Actualizado a `20260719` (0 avisos); `./gradlew test lint` en verde. No cambia los APK (es dependencia de pruebas) |
| Companion, dependencias transitivas | — | **no verificado** (OWASP dependency-check exige descargar la base NVD; no se hizo por memoria y tiempo) | Pendiente opcional |
