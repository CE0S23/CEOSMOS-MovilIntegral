# Prácticas 11 y 12 · CEOSMOS Móvil Integral

## Práctica 11 · Pruebas White Box (terminada el 11/11/2026; defectos corregidos y verificados)

- `p11/CEOSMOS_Practica11_Reporte_WhiteBox.docx` — informe para entregar (generado desde el .md).
- `p11/REPORTE_P11_WHITEBOX.md` — mismo informe en Markdown.
- `p11/evidencias/` — salidas originales por fase (análisis estático, cobertura, HTTP, SQL,
  concurrencia, ping, red del S24, carga, rendimiento de UI) y grafos de flujo (`grafos/`).
- `p11/evidencias/correcciones/` — diffs reales de las correcciones (app y API).
- Evidencias con prefijo `antes_` = resultados previos a las correcciones.
- `p11/scripts/` — scripts reproducibles de cada fase.
- `p11/codigo_pruebas/` — copia del código de las pruebas (originales en `test/whitebox/`,
  `integration_test/p11_*.dart`, `test_driver/` y en `ceosmos-api/src/**/*.spec.ts`).

Reproducir (base local `.devdb` y API en 8080, nunca Neon):

```
flutter test test/whitebox
flutter test --coverage --branch-coverage
node p11yp12/p11/scripts/cobertura_lcov.js coverage/lcov.info
bash p11yp12/p11/scripts/fase5_orquestar.sh <id_telefono> <correo> <clave> salida.txt
```

## Práctica 12 · Optimización, pruebas de estrés y resiliencia (12/11/2026)

- `p12/CEOSMOS_Practica12_Optimizacion_Estres_Resiliencia.docx` — informe para entregar.
- `p12/REPORTE_P12_OPTIMIZACION.md` — mismo informe en Markdown.
- `p12/evidencias/` — salidas originales por fase:
  - `fase2_profiling/` perfil de CPU de la API (`.cpuprofile`, se abre en Chrome DevTools o
    speedscope), `pg_stat_statements` y CPU/RAM/cuadros de la app en el emulador.
  - `fase3_estres/` prueba de estrés antes (y el intento con el limitador 429).
  - `fase4_db/` consultas, índices, concurrencia y login simultáneo.
  - `fase5_resiliencia/` matriz RES-01…RES-09 antes/después y log del proxy de fallos.
  - `fase6_optimizacion/` las mismas mediciones con el código optimizado, Jest, suite de
    Flutter, regresión HTTP de la P11 y diffs del código (`codigo/`).
  - `graficas/` latencia y RPS vs. usuarios.
- `p12/scripts/` — scripts reproducibles (estrés, BD, profiling, proxy de fallos, tablas, gráficas, Word).
- `p12/codigo/` — diffs original → optimizado (app y API) y copia de las pruebas nuevas.

Reproducir (todo local: base `.devdb` en 5433 y API en 8080; nunca Neon):

```
bash p11yp12/p12/scripts/api_local.sh api.log            # THROTTLE_LIMIT=10000000 para la prueba de capacidad
P12_PASS=... node p11yp12/p12/scripts/tokens_carga.js http://127.0.0.1:8080/api 50 tokens.json
node p11yp12/p12/scripts/fase3_estres.js http://127.0.0.1:8080/api <pid_api> tokens.json salida.json
node p11yp12/p12/scripts/fase4_db.js salida.json
node p11yp12/p12/scripts/fase5_proxy_fallos.js proxy.log emulator-5554
flutter test integration_test/p12_resiliencia_test.dart -d emulator-5554 --dart-define=CEOSMOS_API_URL=http://10.0.2.2:8081/api ...
flutter test test/p12
```
