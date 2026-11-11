# Memoria del proyecto · CEOSMOS Móvil Integral

**Actualizada:** 30 de octubre de 2026  
**Proyecto:** aplicación móvil Flutter para CEOSMOS, en español.

## Estado actual

El proyecto contiene una aplicación Flutter funcional para concentración, relajación e inspiración. La interfaz comparte código entre Android, iOS, Web y Windows. El alcance actual es una demostración local: no hay base de datos, API de producción ni sincronización externa.

La aplicación permite entrar en modo demo o crear/iniciar una cuenta local; explorar seis experiencias (tres audios MP3 locales y tres paisajes dibujados con Flutter); buscar y combinar filtros; gestionar favoritos; iniciar sesiones de 5, 15, 25 o 45 minutos con pausa, continuación e historial; y simular la vinculación de CEOSMOS Band y TV. Las métricas de dispositivos son ficticias. El audio usa un reproductor global y es de primer plano.

Las cuentas, favoritos, preferencias, sesiones e historial viven en memoria. Se conservan al cerrar sesión mientras el proceso de la app siga activo, pero se pierden al reiniciarlo. La autenticación local no equivale a la autenticación del backend. Passkeys/WebAuthn se explican, pero no se verifican; tampoco hay sensores, BLE, TCP/IP ni dispositivos físicos conectados.

## Estructura y tecnología

- Flutter 3.41.9 / Dart 3.11.5 indicados en la documentación; SDK Dart `^3.11.5`.
- Dependencias principales: `audioplayers`, `crypto` y Flutter Localizations.
- `lib/core/app_state.dart`: estado de aplicación, cuentas, sesiones y espacios de usuario.
- `lib/data/auth_repository.dart` y `lib/data/catalog.dart`: autenticación local y catálogo.
- `lib/domain/models.dart`: modelos unificados de usuario, acceso, sesión, contenido y dispositivo.
- `lib/core/sound_controller.dart`: controlador de audio.
- `lib/ui/`: pantallas, widgets y tema.
- `assets/audio/`: audio local; `test/`: pruebas unitarias/widget; `integration_test/`: recorrido crítico de extremo a extremo.

## Verificación registrada

- **23 de octubre:** la suite de caja negra de Práctica 8 registró 21/21 casos aprobados y 12/12 requisitos cubiertos. El reporte y sus datos de ejecución están en `docs/evidencias/practica8/`.
- **23 de octubre:** el reporte de red documenta compilación web correcta, análisis estático sin problemas y carga local en Chrome. En la prueba normal no hubo errores de red; bloquear deliberadamente `fonts.gstatic.com` hizo desaparecer el texto. Esto es una dependencia observada, no evidencia de que la red universitaria la bloquee.
- **8 de octubre:** `docs/VALIDACION.md` registra 11 pruebas, compilación web y APK debug correctos, además de un recorrido funcional en navegador. Es evidencia histórica anterior al reporte de Práctica 8.
- **29 de octubre:** se añadió `integration_test/critical_flow_test.dart`, que describe un flujo demo → sesión → historial. La existencia del archivo no confirma que ese test se haya ejecutado ni que se haya probado en un dispositivo Android físico.
- Hay artefactos PDF bajo `output/pdf/`, con fechas de creación del 29 de octubre.

La validación más reciente con resultados explícitos que se encontró es la de caja negra del 23 de octubre. No se ejecutaron comandos durante esta actualización de memoria.

## Decisiones y pendientes conocidos

- Mantener el alcance local sin afirmar que existe conexión a producción.
- El backend NestJS/PostgreSQL, JWT, cookies/CSRF y WebAuthn reales requieren integración futura. Consultar `docs/ARQUITECTURA.md` antes de definir contratos; en particular, el esquema Prisma documentado no incluye todavía el tipo de medio de audio.
- Diseñar e implementar persistencia de sesiones de enfoque, favoritos, preferencias y dispositivos en una API común.
- La integración de hardware prevista prioriza TCP/IP y deja BLE como respaldo; falta probarla con hardware.
- Persistencia al reiniciar, audio de fondo, carga/caché de medios, sensores reales y pruebas en Android físico siguen fuera de lo acreditado por la evidencia disponible.
- La aplicación web solicita fuentes a `fonts.gstatic.com`; si se requiere independencia de esa conexión, las fuentes y su configuración deben revisarse.

## Documentación de referencia

- `README.md`: ejecución, funciones y límites de la demo.
- `docs/ARQUITECTURA.md`: decisiones, modelos, contratos y plan de integración.
- `docs/PRIMERA_REVISION.md`: matriz de entrega y trabajo pendiente.
- `docs/VALIDACION.md`: validación inicial del 8 de octubre.
- `docs/PRACTICA_8_BLACK_BOX_TESTING.md` y `docs/evidencias/practica8/`: especificación e informe más reciente de caja negra.
- `docs/DEMO.md`: guion de demostración.
