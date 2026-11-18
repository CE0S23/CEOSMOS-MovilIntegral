// Práctica 12 · Gráficas del reporte (PNG) con Chrome sin interfaz.
//   P12_TOOLS=<carpeta con node_modules/puppeteer-core> node graficas_p12.js
// 1) Latencia promedio y P95 vs. usuarios (lectura y escritura, antes/después)
// 2) Solicitudes por segundo vs. usuarios (punto de saturación)
const fs = require('fs');
const path = require('path');
const puppeteer = require(path.join(process.env.P12_TOOLS || '.', 'node_modules', 'puppeteer-core'));
const EV = path.join(__dirname, '..', 'evidencias');
const SAL = path.join(EV, 'graficas');
fs.mkdirSync(SAL, { recursive: true });
const leer = (r) => JSON.parse(fs.readFileSync(path.join(EV, r), 'utf8'));
const series = {
  antes: leer('fase3_estres/antes_estres.json').filas,
  d50: leer('fase6_optimizacion/despues_estres.json').filas,
  d20: leer('fase6_optimizacion/despues_estres_app.json').filas,
};
const COL = { antes: '#B4472F', d50: '#2F6DB4', d20: '#2E8B57' };
const NOM = { antes: 'Antes', d50: 'Después (misma petición, 50)', d20: 'Después (app: página de 20)' };

function svg({ titulo, ejeY, escenario, campo, campo2, ancho = 760, alto = 380 }) {
  const m = { l: 64, r: 16, t: 44, b: 70 };
  const users = [1, 5, 10, 25, 50];
  const x = (u) => m.l + (users.indexOf(u) / (users.length - 1)) * (ancho - m.l - m.r);
  const datos = Object.entries(series).map(([k, f]) => [k, f.filter((r) => r.escenario === escenario)]).filter(([, f]) => f.length);
  const maxY = Math.max(...datos.flatMap(([, f]) => f.flatMap((r) => [r[campo], campo2 ? r[campo2] : 0]))) * 1.1;
  const y = (v) => alto - m.b - (v / maxY) * (alto - m.t - m.b);
  let s = `<svg xmlns="http://www.w3.org/2000/svg" width="${ancho}" height="${alto}" font-family="Arial" font-size="12"><rect width="100%" height="100%" fill="#fff"/>`;
  s += `<text x="${ancho / 2}" y="22" text-anchor="middle" font-size="15" font-weight="bold" fill="#151515">${titulo}</text>`;
  for (let i = 0; i <= 5; i++) {
    const v = (maxY / 5) * i;
    s += `<line x1="${m.l}" x2="${ancho - m.r}" y1="${y(v)}" y2="${y(v)}" stroke="#E3E6EC"/><text x="${m.l - 8}" y="${y(v) + 4}" text-anchor="end" fill="#535B68">${Math.round(v)}</text>`;
  }
  for (const u of users) s += `<text x="${x(u)}" y="${alto - m.b + 18}" text-anchor="middle" fill="#535B68">${u}</text>`;
  s += `<text x="${(ancho + m.l) / 2}" y="${alto - m.b + 36}" text-anchor="middle" fill="#151515">Usuarios concurrentes</text>`;
  s += `<text transform="translate(16 ${(alto - m.b + m.t) / 2}) rotate(-90)" text-anchor="middle" fill="#151515">${ejeY}</text>`;
  datos.forEach(([k, f], i) => {
    for (const [c, guion] of [[campo, ''], ...(campo2 ? [[campo2, '6 4']] : [])]) {
      const pts = f.map((r) => `${x(r.usuarios)},${y(r[c])}`).join(' ');
      s += `<polyline points="${pts}" fill="none" stroke="${COL[k]}" stroke-width="2.5" ${guion ? `stroke-dasharray="${guion}"` : ''}/>`;
      for (const r of f) s += `<circle cx="${x(r.usuarios)}" cy="${y(r[c])}" r="3.5" fill="${COL[k]}"/>`;
    }
    s += `<rect x="${m.l + i * 235}" y="${alto - 22}" width="14" height="4" fill="${COL[k]}"/><text x="${m.l + 20 + i * 235}" y="${alto - 16}" fill="#151515">${NOM[k]}</text>`;
  });
  if (campo2) s += `<text x="${ancho - m.r}" y="${m.t - 8}" text-anchor="end" fill="#535B68">continua = promedio · discontinua = P95</text>`;
  return s + '</svg>';
}

(async () => {
  const navegador = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
  const p = await navegador.newPage();
  const graficas = [
    ['latencia_lectura', { titulo: 'GET /focus-sessions: latencia vs. usuarios', ejeY: 'ms', escenario: 'lectura', campo: 'prom_ms', campo2: 'p95_ms' }],
    ['rps_lectura', { titulo: 'GET /focus-sessions: solicitudes por segundo vs. usuarios', ejeY: 'solicitudes/s', escenario: 'lectura', campo: 'rps' }],
    ['latencia_escritura', { titulo: 'POST /focus-sessions: latencia vs. usuarios', ejeY: 'ms', escenario: 'escritura', campo: 'prom_ms', campo2: 'p95_ms' }],
    ['rps_escritura', { titulo: 'POST /focus-sessions: solicitudes por segundo vs. usuarios', ejeY: 'solicitudes/s', escenario: 'escritura', campo: 'rps' }],
  ];
  for (const [nombre, cfg] of graficas) {
    const contenido = svg(cfg);
    fs.writeFileSync(path.join(SAL, nombre + '.svg'), contenido);
    await p.setViewport({ width: 760, height: 380, deviceScaleFactor: 2 });
    await p.setContent(`<html><body style="margin:0">${contenido}</body></html>`);
    await p.screenshot({ path: path.join(SAL, nombre + '.png'), clip: { x: 0, y: 0, width: 760, height: 380 } });
    console.log('PNG', nombre);
  }
  await navegador.close();
})();
