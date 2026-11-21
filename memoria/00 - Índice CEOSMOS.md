---
tags: [ceosmos, moc]
estado: vigente
actualizado: 2026-11-19
---

# CEOSMOS · Índice (Map of Content)

Memoria única del proyecto **CEOSMOS Móvil Integral** (Flutter + API NestJS + PostgreSQL,
con Reloj y TV compañeros por BLE). Revisión completa del 2026-11-18: lo marcado `- [x]` se comprobó
en el código, en las pruebas automatizadas o en los dispositivos (Samsung S24 y Galaxy Tab S9).

## Estado de un vistazo (19/11/2026)
**Funciona y está verificado**
- [x] App real contra la API de producción y Neon (S24) → [[01 - Visión general]] · [[04 - Módulos de la app]]
- [x] Requerimientos de los 3 parciales (salvo passkeys) → [[02 - Requerimientos]]
- [x] Reloj y TV por BLE, probados en S24 + Tab S9 → [[06 - BLE Wearable y TV]]
- [x] Prácticas 3–12, Examen 1, BD Firestore y Evaluación 2 → sección Prácticas (P7 cerrada el 19/11 con los 4 roles)
- [x] Black/White/Red Box: 215 + 14 pruebas, Red Box 13/13 → [[07 - Pruebas (Black, White, Red Box)]]
- [x] P13-14: pruebas automatizadas + CI en GitHub Actions (verde en push y PR) → [[Práctica 13-14 - Automatización de pruebas y CI]]
- [x] Repositorio público: https://github.com/CE0S23/CEOSMOS-MovilIntegral (PR #1 fusionado; CI en `main`)
- [x] Reporte de avances (Word) actualizado; memoria reestructurada con respaldo
- [x] Reestructura (21/11): las prácticas son funciones (Soporte, Equipos, Perfil) sin «Práctica» visible → [[12 - Mapa de funciones]]
- [x] Rediseño estético (21/11): sistema de diseño guinda/cian con modo oscuro, Bricolage + DM Sans → [[11 - Sistema de diseño]]

**Falta** (detalle en [[08 - Pendientes]])
- [x] P7 cerrada (documentos de rol, 4 roles en S24 + tablet, TC01–TC08) → [[Práctica 07 - Roles y mensajería (Sistema de tickets)]]
- [ ] Rotación de Neon/`JWT_SECRET`, clave de `mesaayuda-p7` y alertas de GitHub (los hace el usuario)
- [ ] Tareas que requieren al usuario y mejoras opcionales

## Notas
- [[01 - Visión general]] — qué es CEOSMOS y en qué estado está.
- [[02 - Requerimientos]] — requisitos del reporte de avances (3 parciales) y su estado.
- [[03 - Arquitectura y stack]] — app, API, bases de datos, despliegue y cómo se ejecuta.
- [[04 - Módulos de la app]] — pestañas y funciones de la app.
- [[06 - BLE Wearable y TV]] — apps «CEOSMOS Reloj» y «CEOSMOS TV», UUID y protocolo.
- [[07 - Pruebas (Black, White, Red Box)]] — resultados, cobertura y riesgos.
- [[08 - Pendientes]] — **todo lo que falta**, con enlace a su nota.
- [[09 - Decisiones técnicas]]
- [[10 - Bitácora]]
- [[13 - Blindaje]] — blindaje antes de la evaluación (etapa 3 hecha; etapas 1-2 sin registro; no consolidado).
- [[12 - Mapa de funciones]] — cada práctica como función de la app: ubicación, rol, origen, código y BD; botón ⓘ.
- [[11 - Sistema de diseño]] — paleta guinda/cian, reglas de contraste, tipografía y escala (app, prácticas, Reloj y TV).
- [[Notas varias]]

## Prácticas (05 - Prácticas)
- [[Práctica 03 - Consumo de servicio web]] · [[Práctica 04 - Almacenamiento estructurado]] · [[Práctica 05 - Código seguro (AccesoSeguro)]] · [[Práctica 06 - Interacción entre dispositivos (MobileConnect)]]
- [[Examen 1 - Incidencias de soporte]] · [[Práctica BD - Reportes Firestore]] · [[Práctica 07 - Roles y mensajería (Sistema de tickets)]] · [[Práctica 08 - Pruebas de caja negra]]
- [[Práctica 09 - Base de datos compartida entre dispositivos]] · [[Práctica 10 - Seguridad y control de acceso]] · [[Práctica 11 - Pruebas White Box]] · [[Práctica 12 - Optimización, estrés y resiliencia]] · [[Práctica 13-14 - Automatización de pruebas y CI]] · [[Evaluación 2 - MediConnect]]

## Histórico (11 - Histórico)
Auditorías anteriores a la integración, conservadas tal cual (ya no describen el código actual):
- [[Histórico - CEOSMOS Flutter (auditoría)]]
- [[Histórico - CEOSMOS Web (auditoría)]]
- [[Histórico - Arquitectura integral (propuesta)]]

## Documentos de entrega (fuera de la memoria)
- `README.md` del repositorio (cómo ejecutar).
- `docs/PRACTICA_8_BLACK_BOX_TESTING.md`, `p11yp12/p11/REPORTE_P11_WHITEBOX.md`, `p11yp12/p12/REPORTE_P12_OPTIMIZACION.md`, `evidencias/p13_14/REPORTE_P13_14_AUTOMATIZACION.md` (+ Word en la misma carpeta).
- `lib/practicas/README.md` (adaptaciones `[CEOSMOS]` de cada práctica).
- `Reporte de avances - CEOSMOS revicion.docx`.
- Evidencias de esta revisión: carpeta `evidencias/`.
