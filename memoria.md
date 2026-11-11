# Memoria del proyecto · CEOSMOS Móvil Integral

**Actualizada:** 11 de noviembre de 2026
**Proyecto:** aplicación móvil Flutter para CEOSMOS, en español.

## Estado actual

La app ya no es una demo local. Se conecta a la API real de CEOSMOS (NestJS 11 +
Prisma 5, `WEBANGULAR/ceosmos-api`, rama `movil-integral`) con JWT Bearer. Los
datos del usuario (favoritos, preferencias, historial de sesiones de enfoque,
dispositivos vinculados y biblioteca multimedia) se guardan en PostgreSQL.

- Acceso: registro + verificación de correo, login, recuperación de contraseña,
  logout que revoca en el servidor, restauración de sesión (token en
  `flutter_secure_storage`, espacio `ceosmos_secure_storage`). Sin modo demo.
- Wearable por TCP/IP (protocolo: una línea JSON `{"hr":..,"steps":..}` por
  lectura); el resumen de métricas se guarda en `FocusSession.metadata` (JSONB).
- Biblioteca `/api/media` con caché LRU en disco de 150 MB (JPEG/WebP ≤ 2 MB).
- Panel de administración para cuentas ADMIN.
- Ventana **Prácticas** con 10 prácticas integradas, cada una con su propia BD
  (Firebase con app con nombre, SQLite, SharedPreferences o API propia).

## Backend

- Railway (`ceosmosv2-production.up.railway.app`) respondía 404 el 11/11/2026.
- Rama `movil-integral` de la API: módulos `/focus-sessions`, `/favorites`,
  `/devices`; migración aditiva `20261111170000_movil_integral`; CSRF solo para
  autenticación por cookie; límite general 120/min (auth 10/min).
- La migración **no se aplicó a Neon** (la política de permisos lo bloqueó por
  ser producción). Pruebas hechas con PostgreSQL 16 local (`.devdb`, puerto 5433).
- Resend: la `RESEND_API_KEY` actual es inválida; los códigos de verificación no
  se envían hasta configurarla.

## Verificación registrada (11/11/2026)

- `flutter analyze`: sin problemas. `flutter test`: 56/56.
- E2E en emulador Pixel 6 API 34 contra la API real: aprobado.
- Recorrido manual en el emulador de CEOSMOS y de cada práctica; capturas en
  `capturas/`. Detalle en `REPORTE_FINAL.md`.

## Pendientes conocidos

Passkeys WebAuthn móviles, CEOSMOS TV, BLE, notificación de audio en segundo
plano (servicio en primer plano), prueba con wearable físico y Android físico,
contraseñas de las cuentas de prueba de la Práctica 7. Ver `REPORTE_FINAL.md`.
