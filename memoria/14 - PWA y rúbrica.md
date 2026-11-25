---
tags: [ceosmos, pwa, rubrica]
estado: vigente
actualizado: 2026-11-24
---

# 14 · PWA y rúbrica

Revisión del 24/11/2026 contra la rúbrica (A–F). Matriz completa: `evidencias/rubrica/Matriz de cumplimiento - CEOSMOS.md` (+ .docx/.pdf), con guion de demostración y preguntas probables.

## PWA
- Construir: `scripts/construir_pwa.ps1 [-Local] [-Servir]` → `flutter build web --no-web-resources-cdn` + `scripts/pwa_precache.py` (lista y versión por hash en `build/web/sw.js`).
- `web/flutter_bootstrap.js` carga Flutter sin su SW y registra `sw.js`; `web/index.html` con pantalla de carga y theme-color; `web/manifest.json` con id, scope, capturas (`web/capturas/`) y atajos `?pestana=`.
- `sw.js`: precarga (31 archivos, 19.1 MB), navegación red primero → index guardado, archivos propios caché primero, API/Firebase/no-GET nunca, imágenes externas máx. 60.
- Servir en `localhost:4200`: la API de producción ya lo admite por CORS. Dominio propio = agregar origen a CORS (decisión del usuario).

## Modo sin conexión
- `lib/data/cache_sin_conexion.dart` (perfil público + pendientes por usuario); `ApiException.sinRed`; `AppState._abrirSinConexion`, `_programarReconexion`. Se borra en `_cerrarLocal`.
- Pruebas: `test/sin_conexion_test.dart` (6), `test/pwa_test.dart` (7).

## Verificado y pendiente
- [x] Chromium 24/11 contra API local: SW activo, 0 errores de instalabilidad, offline abre, sesión offline enviada una vez (mismo clientId en BD), actualización de SW borra caché vieja.
- [ ] Web Bluetooth con Reloj/TV reales (solo se vio abrir el selector).
- [ ] APK 1.3.0 en los equipos.
- Límite declarado: pulso/pasos del Reloj simulados (la tablet no tiene sensor).

---
Navegación: [[00 - Índice CEOSMOS]] · [[09 - Decisiones técnicas]] · [[10 - Bitácora]] · [[13 - Blindaje]]
