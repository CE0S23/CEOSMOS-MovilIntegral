---
tags: [ceosmos, modulos]
estado: vigente
actualizado: 2026-11-18
---

# Módulos de la app

| Pestaña | Qué hace | Persistencia |
| --- | --- | --- |
| Acceso | Registro + código de verificación, login, recuperación, mensajes del servidor traducidos | API `/auth/*`, token seguro |
| Inicio | Saludo, reflexión, accesos | — |
| Explorar | Catálogo (3 audios propios, 3 paisajes), búsqueda, filtros, favoritos | `/favorites` |
| Mi sesión | Temporizador 5–60 min, pausa, audio, fin; reintento sin red con backoff e idempotencia (`clientId`) | `/focus-sessions` |
| Equipos | **Reloj y TV por BLE** (PIN, lecturas, notificación, proyección, comandos) y wearable TCP | `/devices` (WEARABLE/TV, TCP/BLE) |
| Prácticas | Ventana con las prácticas, cada una en su ruta/actividad con barra «← Prácticas» | BD propia por práctica |
| Perfil | Nombre, preferencias, historial paginado, sesiones activas, caché, eliminar cuenta, administración (ADMIN) | `/users/*`, `/admin/*` |

- [x] Botón Atrás dentro de una práctica vuelve a «Prácticas» en Android 16/17 (antes cerraba la app; corregido el 18/11, ver [[09 - Decisiones técnicas]]).
- [x] Pausa/fin/cambio de ambiente pedidos desde el Reloj o la TV también detienen el audio.

---
Navegación: [[00 - Índice CEOSMOS]] · [[02 - Requerimientos]] · [[03 - Arquitectura y stack]] · [[06 - BLE Wearable y TV]]
