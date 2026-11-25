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
| 18/11 | Repo propio y público para la app (`CEOSMOS-MovilIntegral`), no `CEOSMOSV2` | CEOSMOSV2 es la web/API con historia distinta y despliegue a Vercel/Neon; el profesor ve el repo sin invitación |
| 18/11 | CI sin secretos: servidor HTTP local, MockClient, BLE simulado y SQLite FFI | Las pruebas nunca deben tocar producción ([[Práctica 13-14 - Automatización de pruebas y CI]]) |
| 18/11 | Escaneo BLE en serie y reautenticación al recibir «sin autorización» | Defectos encontrados en hardware (ver [[06 - BLE Wearable y TV]]) |
| 24/11 | Service worker propio `web/sw.js` en vez del de Flutter | El de Flutter 3.41 se desregistra solo: sin modo offline |
| 24/11 | Modo sin conexión con perfil y pendientes en SharedPreferences/localStorage; token sigue en almacén seguro | Una sesión terminada sin red se perdía al cerrar la app |
| 24/11 | PWA servida en `localhost:4200` para la demostración | Origen ya admitido por CORS en producción y contexto seguro; un dominio propio exige tocar la lista CORS |
| 24/11 | El pulso del Reloj sigue simulado y se declara como límite | La tablet no tiene sensor de pulso; código de sensores sin hardware para probar sería un riesgo antes de la entrega |

---
Navegación: [[00 - Índice CEOSMOS]] · [[03 - Arquitectura y stack]] · [[06 - BLE Wearable y TV]] · [[10 - Bitácora]]
