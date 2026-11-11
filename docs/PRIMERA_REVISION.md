# Matriz de entrega · Primera revisión

Fecha de preparación: 8 de octubre de 2026.

Fuente principal: `Reporte de avances - CEOSMOS.docx`, sección «Primer parcial: Arquitectura base y fusión de interfaces».

## Ajuste de alcance solicitado

La solicitud más reciente indica una app Flutter sencilla sin base de datos. Por tanto, se implementan los flujos ejecutables con estado local y se identifican los puntos del reporte que necesitan un servicio real. No se modifica el Word original ni se presenta la simulación como conexión real.

| Punto del reporte | Resultado | Evidencia |
| --- | --- | --- |
| Proyecto Flutter unificado | Implementado | Proyecto Android, iOS, Web y Windows; código compartido en `lib/` |
| Migración UI de feeds visuales/auditivos | Implementado con catálogo local | Inicio, Explorar, búsqueda, filtros, favoritos, paisajes y MP3 incluidos |
| Conexión con API NestJS/Prisma y PostgreSQL/Neon | Pendiente por alcance local | Interfaz de autenticación reemplazable y contratos documentados; no se envían peticiones |
| Flujo email/contraseña | Implementado en memoria | Registro, validación, login, aislamiento de cuentas, caducidad y logout |
| JWT, políticas del servidor y passkeys WebAuthn | Pendiente de integración real | Explicación visible en acceso; sin falsas verificaciones biométricas |
| Unificación de modelos | Implementada en Dart; esquema servidor propuesto | AppUser, AuthSession, FocusSession, MediaItem, LinkedDevice; metadatos JSON |
| Esquema relacional y JSONB en servidor | Diseñado, no desplegado | Mapeo en `ARQUITECTURA.md`; sin migraciones ejecutadas |

## Funciones de apoyo a la demostración

- Sesiones cronometradas con historial accesible y preferencia de duración.
- Un único reproductor, sin las barras superpuestas descritas en las memorias.
- Búsqueda central y favoritos accesibles desde Explorar y Perfil.
- Dispositivos con estados consistentes y acciones visibles de simulación.
- Al finalizar/cerrar sesión se detiene el audio y se guarda la actividad local.
- Ninguna métrica de bienestar se presenta como lectura de un sensor.

## Qué queda para los siguientes avances

1. Conectar el repositorio remoto y validar la sesión auténtica del servidor; acordar cookies/CSRF y soporte móvil de passkeys.
2. Extender el backend para sesiones de enfoque y dispositivos. El esquema actual distingue `Session` de autenticación; no reutilizarlo como historial de enfoque.
3. Integrar TCP/IP como canal primario del wearable, siguiendo el reporte más reciente; BLE/GATT como alternativa. Probar en hardware físico.
4. Persistir favoritos, sesiones, preferencias y métricas vía una API única.
5. En el tercer parcial: audio de fondo, admisión WebP/JPEG ≤ 2 MB y MP3/AAC ≤ 10 MB, caché LRU de 150–200 MB, profiling y pruebas integradas con dispositivos reales.

## Validación

Las pruebas en `test/` cubren autenticación y errores, aislamiento de cuentas, caducidad, tiempo pausado, terminación única, reemplazo de sesión, búsqueda y recorridos de interfaz. El estado final de compilación se registra en `VALIDACION.md`.
