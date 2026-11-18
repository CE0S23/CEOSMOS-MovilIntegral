---
tags: [ceosmos, decisiones]
estado: vigente
actualizado: 2026-11-18
---

# Decisiones técnicas

| Fecha | Decisión | Motivo |
| --- | --- | --- |
| 08/10 | Primera revisión local sin BD | Solicitud de esa entrega (luego superada) |
| 11/11 | API NestJS + PostgreSQL/Neon en lugar de Firestore como BD de CEOSMOS | Es el backend real del proyecto; Firestore queda solo en las prácticas que lo usan. *Contradice* la memoria histórica de CEOSMOS Flutter (Firestore + onSnapshot): gana el código actual |
| 11/11 | CSRF solo para auth por cookie; límite 120/min (auth 10/min) | Un cliente Bearer no es atacable por CSRF; la app hace ~6 peticiones al abrir |
| 11/11 | Cada práctica con BD/espacio propio (apps Firebase con nombre, archivos y prefijos propios) | Aislar datos y sesiones |
| 12/11 | Reintento con backoff + `clientId` idempotente para sesiones (P12) | Evitar duplicados al reintentar |
| 18/11 | BLE: central en Flutter con `flutter_blue_plus` y periféricos nativos | Android permite servidor GATT y anuncio desde apps nativas |
| 18/11 | TV como app Android nativa (no PWA) | El profesor no exige PWA para la TV y Web Bluetooth no puede actuar como periférico; *sustituye* a la PWA TV de la memoria histórica |
| 18/11 | Dos apps (Reloj y TV) en la tablet, más un sabor «companion» de respaldo | Se comprobó que ambas anuncian y sirven GATT a la vez |
| 18/11 | Autenticación BLE por reto + HMAC con PIN de 6 dígitos | No enviar el PIN por el aire; sin diálogo de emparejamiento del sistema |
| 18/11 | La dirección BLE guardada en la API es `CE:05:<id>` | La MAC del periférico rota (privacidad) |
| 18/11 | Prácticas Flutter informan `onNavigationNotification` a favor de CEOSMOS | En Android 14+ (atrás predictivo) el `MaterialApp` interno cerraba la app al pulsar Atrás |
| 18/11 | Escaneo BLE en serie y reautenticación al recibir «sin autorización» | Defectos encontrados en hardware (ver [[06 - BLE Wearable y TV]]) |

---
Navegación: [[00 - Índice CEOSMOS]] · [[03 - Arquitectura y stack]] · [[06 - BLE Wearable y TV]] · [[10 - Bitácora]]
