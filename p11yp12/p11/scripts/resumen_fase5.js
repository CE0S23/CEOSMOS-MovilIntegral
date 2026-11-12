// Práctica 11 · Fase 5: resume las líneas P11_JSON de las corridas en el teléfono.
//   node resumen_fase5.js <salida_corrida.txt> [más corridas...]
const fs = require('fs');
const media = (a) => a.reduce((s, x) => s + x, 0) / a.length;
const desv = (a) => { const m = media(a); return Math.sqrt(a.reduce((s, x) => s + (x - m) ** 2, 0) / (a.length - 1)); };
const f = (x, d = 1) => Number(x).toFixed(d);

for (const archivo of process.argv.slice(2)) {
  const filas = fs.readFileSync(archivo, 'utf8').split(/\r?\n/)
    .filter((l) => l.startsWith('P11_JSON ')).map((l) => JSON.parse(l.slice(9)));
  const de = (t) => filas.filter((x) => x.tipo === t);
  console.log(`\n### ${archivo}`);
  const env = de('entorno')[0];
  if (env) console.log(`Fecha ${env.fecha} · ${env.so} ${env.version_so} · API ${env.api}`);

  const h = de('http_10');
  console.log('\n| Solicitud | Código HTTP | Tiempo (ms) | Tamaño (bytes) |\n|---|---|---|---|');
  for (const x of h) console.log(`| ${x.n} | ${x.status} | ${f(x.ms)} | ${x.bytes} |`);
  const ms = h.map((x) => x.ms);
  console.log(`\nPromedio ${f(media(ms))} ms · mín ${f(Math.min(...ms))} · máx ${f(Math.max(...ms))} · desv. estándar ${f(desv(ms))} · ` +
    `sin la 1.ª (conexión nueva) ${f(media(ms.slice(1)))} ms · éxito ${h.filter((x) => x.status === 200).length}/${h.length} · ` +
    `tamaño prom. ${f(media(h.map((x) => x.bytes)), 0)} B (${f(media(h.map((x) => x.bytes)) / 1024)} KB)`);

  for (const t of ['descarga', 'subida']) {
    console.log(`\n| ${t} | origen/destino | bytes | tiempo (s) | Mbps |\n|---|---|---|---|---|`);
    const grupos = {};
    for (const x of de(t)) {
      console.log(`| ${x.n} | ${x.origen || x.destino} | ${x.bytes} | ${f(x.s, 3)} | ${f(x.mbps, 2)} |`);
      (grupos[x.origen || x.destino] ||= []).push(x);
    }
    for (const [g, xs] of Object.entries(grupos)) {
      const bytes = xs.reduce((s, x) => s + x.bytes, 0), seg = xs.reduce((s, x) => s + x.s, 0);
      console.log(`Promedio ${g}: ${f(media(xs.map((x) => x.mbps)), 2)} Mbps (agregado ${f((bytes * 8) / seg / 1e6, 2)} Mbps; ${f(media(xs.map((x) => x.s)), 3)} s por transferencia)`);
    }
  }
  for (const t of ['interrupcion', 'reintento_sin_red', 'recuperacion']) for (const x of de(t)) console.log(`${t}: ${JSON.stringify(x)}`);
}
