---
tags: [ceosmos, modulos]
estado: vigente
actualizado: 2026-11-21
---

# Módulos de la app

| Pestaña | Qué hace | Persistencia |
| --- | --- | --- |
| Acceso | Registro + código de verificación, login, recuperación, mensajes del servidor traducidos | API `/auth/*`, token seguro |
| Inicio | Saludo, reflexión, accesos | — |
| Explorar | Catálogo (3 audios propios, 3 paisajes), búsqueda, filtros, favoritos | `/favorites` |
| Mi sesión | Temporizador 5–60 min, pausa, audio, fin; reintento sin red con backoff e idempotencia (`clientId`) | `/focus-sessions` |
| Equipos | **Reloj y TV por BLE** (PIN, lecturas, notificación, proyección, comandos), wearable TCP y **Mensajería entre equipos** | `/devices` (WEARABLE/TV, TCP/BLE); mensajería sin BD |
| Soporte | **Tickets y chat interno** (menú por rol), **Incidencias sin conexión** y grupo **Reportes e incidencias** (compartidos, Android, tiempo real, mis incidencias y acceso) | BD propia por función (Firebase con nombre, SharedPreferences) |
| Perfil | Nombre, preferencias, historial paginado, sesiones activas, caché, eliminar cuenta, administración (ADMIN) y **Cuenta y herramientas** (Seguridad de la cuenta, Directorio de alumnos, Citas de bienestar) | `/users/*`, `/admin/*`; SQLite y API propia en herramientas |

Desde el 21/11 ya no existe la ventana «Prácticas»: cada práctica es una función con nombre funcional. Detalle, roles, origen y BD en [[12 - Mapa de funciones]].

- [x] Botón Atrás dentro de una función vuelve a su sección (Soporte, Equipos o Perfil) en Android 16/17 (antes cerraba la app; corregido el 18/11, ver [[09 - Decisiones técnicas]]).
- [x] Pausa/fin/cambio de ambiente pedidos desde el Reloj o la TV también detienen el audio.

---
Navegación: [[00 - Índice CEOSMOS]] · [[02 - Requerimientos]] · [[03 - Arquitectura y stack]] · [[06 - BLE Wearable y TV]] · [[12 - Mapa de funciones]]
