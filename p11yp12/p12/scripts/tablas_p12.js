// Práctica 12 · Genera las tablas Markdown del reporte a partir de las evidencias JSON.
//   node tablas_p12.js > ../evidencias/tablas_generadas.md
const fs = require('fs');
const path = require('path');
const EV = path.join(__dirname, '..', 'evidencias');
const leer = (r) => JSON.parse(fs.readFileSync(path.join(EV, r), 'utf8'));
const f1 = (x) => (x === null || x === undefined ? '–' : (Math.round(x * 10) / 10).toLocaleString('es-MX'));
const pct = (a, b) => (a && b !== undefined ? `${b - a >= 0 ? '+' : ''}${f1(((b - a) / a) * 100)} %` : '–');
const out = [];

function tablaEstres(titulo, archivo) {
  const d = leer(archivo);
  out.push(`### ${titulo}`, '', `Archivo: \`${archivo}\` · ${d.duracion_por_escenario_s} s por escenario · lectura \`${d.ruta_lectura || '/focus-sessions?limit=50'}\``, '');
  out.push('| Escenario | Usuarios | Solicitudes | RPS | Prom. (ms) | P50 | P90 | P95 | P99 | Máx. | Errores | Códigos | CPU API prom./máx. (%) | RAM API máx. (MB) | Consultas SQL por solicitud |');
  out.push('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (const r of d.filas) {
    out.push(`| ${r.escenario} | ${r.usuarios} | ${r.solicitudes.toLocaleString('es-MX')} | ${f1(r.rps)} | ${f1(r.prom_ms)} | ${f1(r.p50_ms)} | ${f1(r.p90_ms)} | ${f1(r.p95_ms)} | ${f1(r.p99_ms)} | ${f1(r.max_ms)} | ${f1(r.errores_pct)} % | ${Object.entries(r.codigos).map(([k, v]) => `${k}×${v}`).join(', ')} | ${f1(r.cpu_api_prom_pct)} / ${f1(r.cpu_api_max_pct)} | ${f1(r.ram_api_max_mb)} | ${f1(r.pg_tx_por_solicitud)} |`);
  }
  if (d.integridad) out.push('', `Integridad: ${d.integridad.respuestas_201} respuestas 201 = ${d.integridad.filas_insertadas} filas insertadas; clientId duplicados: ${d.integridad.clientId_duplicados}.`);
  out.push('');
  return d;
}

const antes = tablaEstres('Antes (código original)', 'fase3_estres/antes_estres.json');
const d50 = tablaEstres('Después, misma petición (`?limit=50`)', 'fase6_optimizacion/despues_estres.json');
const d20 = tablaEstres('Después, petición que hace la app optimizada (`?limit=20`)', 'fase6_optimizacion/despues_estres_app.json');

out.push('### Comparación por escenario (antes → después)', '');
out.push('| Escenario | Usuarios | RPS antes → después (50) → app (20) | Prom. ms | P95 ms | Errores |');
out.push('| --- | --- | --- | --- | --- | --- |');
for (const a of antes.filas) {
  const b = d50.filas.find((x) => x.escenario === a.escenario && x.usuarios === a.usuarios);
  const c = d20.filas.find((x) => x.escenario === a.escenario && x.usuarios === a.usuarios);
  out.push(`| ${a.escenario} | ${a.usuarios} | ${f1(a.rps)} → ${f1(b?.rps)} (${pct(a.rps, b?.rps)})${c ? ` → ${f1(c.rps)} (${pct(a.rps, c.rps)})` : ''} | ${f1(a.prom_ms)} → ${f1(b?.prom_ms)}${c ? ` → ${f1(c.prom_ms)}` : ''} | ${f1(a.p95_ms)} → ${f1(b?.p95_ms)}${c ? ` → ${f1(c.p95_ms)}` : ''} | ${f1(a.errores_pct)} → ${f1(b?.errores_pct)} % |`);
}
out.push('');

for (const [t, r] of [['antes', 'fase2_profiling/antes_app_resumen.json'], ['después', 'fase6_optimizacion/despues_app_resumen.json']]) {
  if (!fs.existsSync(path.join(EV, r))) continue;
  const a = leer(r);
  out.push(`### App en el emulador (${t})`, '', `CPU prom. ${f1(a.total.cpu_prom_pct)} %, máx. ${f1(a.total.cpu_max_pct)} % · PSS inicial ${f1(a.total.ram_inicial_pss_mb)} MB, máx. ${f1(a.total.ram_max_pss_mb)} MB, final ${f1(a.total.ram_final_pss_mb)} MB`, '');
  out.push('| Fase | Duración (s) | CPU prom. (%) | CPU máx. (%) | PSS máx. (MB) | Mayor bloqueo del hilo UI (ms) | Bloqueos > 50 ms |');
  out.push('| --- | --- | --- | --- | --- | --- | --- |');
  for (const p of a.por_fase) out.push(`| ${p.fase} | ${f1(p.duracion_s)} | ${f1(p.cpu_prom_pct)} | ${f1(p.cpu_max_pct)} | ${f1(p.pss_max_mb)} | ${f1(p.max_retraso_hilo_ui_ms)} | ${p.bloqueos_sobre_50ms} |`);
  const d = a.datos_app;
  out.push('', `Carga inicial ${d.carga_inicial_ms} ms (${d.sesiones_cargadas} sesiones) · recarga prom. ${f1(d.recarga_workspace_ms.prom)} ms (P95 ${f1(d.recarga_workspace_ms.p95)}) · historial prom. ${f1(d.consulta_historial_ms.prom)} ms · guardar sesión prom. ${f1(d.guardar_sesion_ms.prom)} ms · procesar 100 sesiones ${f1(d.procesar_100_sesiones_ms.prom)} ms · navegación ${d.navegacion_cuadros.cuadros} cuadros (build prom. ${f1(d.navegacion_cuadros.build_ms.prom)} ms, raster prom. ${f1(d.navegacion_cuadros.raster_ms.prom)} ms) · reposo con sesión: ${d.reposo_cuadros.cuadros} cuadros, build prom. ${f1(d.reposo_cuadros.build_ms.prom)} ms, total ${f1(d.reposo_cuadros.build_total_ms)} ms`, '');
}
console.log(out.join('\n'));
