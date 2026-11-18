---
tags: [ceosmos, vision]
estado: vigente
actualizado: 2026-11-18
---

# Visión general

CEOSMOS es una app de **concentración, relajación e inspiración**: feeds visuales y auditivos,
sesiones de enfoque cronometradas y métricas de un wearable. Une los dos proyectos anteriores
(CEOSMOS WEB — Angular/NestJS/PostgreSQL — y CEOSMOS para Dispositivos Inteligentes — Flutter con
wearable y TV) en **una sola app móvil Flutter** conectada a la API real. Por indicación del
profesor, la app incluye la ventana **Prácticas** con las prácticas del curso, cada una con su BD.

Dispositivo central: smartphone Android (Samsung Galaxy S24). Periféricos: **CEOSMOS Reloj** y
**CEOSMOS TV** (apps compañeras en la Galaxy Tab S9) por Bluetooth LE, y wearable por TCP/IP.

## Estado al 18/11/2026
- [x] App real contra la API de producción (`https://ceosmos-api.vercel.app/api`, Neon) — login probado en el S24.
- [x] Sin modo demo ni datos ficticios en la app principal (ver [[02 - Requerimientos]]).
- [x] 13 prácticas/actividades dentro de la app, cada una con su propio almacenamiento (ver [[00 - Índice CEOSMOS]]).
- [x] Reloj y TV por BLE real S24 ↔ tablet (ver [[06 - BLE Wearable y TV]]).
- [x] `flutter analyze` sin observaciones · 188 pruebas Flutter + 9 Kotlin en verde (ver [[07 - Pruebas (Black, White, Red Box)]]).
- [ ] Pendientes en [[08 - Pendientes]].
