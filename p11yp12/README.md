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

## Práctica 12

Pendiente.
