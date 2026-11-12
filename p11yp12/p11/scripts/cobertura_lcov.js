// Práctica 11 · Cobertura a partir de coverage/lcov.info (flutter test --coverage --branch-coverage).
// Imprime la cobertura de instrucciones (líneas ejecutables, DA) y de ramas (BRDA)
// por archivo del núcleo y por método crítico. Uso: node cobertura_lcov.js [lcov.info]
const fs = require('fs');
const lcov = fs.readFileSync(process.argv[2] || 'coverage/lcov.info', 'utf8');

const archivos = {};
let actual = null;
for (const l of lcov.split(/\r?\n/)) {
  if (l.startsWith('SF:')) actual = archivos[l.slice(3).replace(/\\/g, '/')] = { da: {}, br: [] };
  else if (l.startsWith('DA:')) { const [n, h] = l.slice(3).split(',').map(Number); actual.da[n] = h; }
  else if (l.startsWith('BRDA:')) {
    const [n, b, r, t] = l.slice(5).split(',');
    actual.br.push({ n: +n, id: `${b}.${r}`, t: t === '-' ? 0 : +t });
  }
}

const pct = (a, b) => (b ? ((100 * a) / b).toFixed(1) : '—');
function resumen(f, desde = 0, hasta = 1e9) {
  const a = Object.entries(f.da).filter(([n]) => n >= desde && n <= hasta);
  const br = f.br.filter((b) => b.n >= desde && b.n <= hasta);
  const ln = a.filter(([, h]) => h > 0).length;
  const sinEjecutar = a.filter(([, h]) => h === 0).map(([n]) => n);
  return { lineas: `${ln}/${a.length}`, pl: pct(ln, a.length), ramas: `${br.filter((b) => b.t > 0).length}/${br.length}`, pb: pct(br.filter((b) => b.t > 0).length, br.length), sinEjecutar };
}

// Rango de un método: desde su firma hasta la llave que lo cierra.
function rango(ruta, inicio) {
  const lineas = fs.readFileSync(ruta, 'utf8').split('\n');
  let prof = 0, empezo = false;
  for (let i = inicio - 1; i < lineas.length; i++) {
    const t = lineas[i].replace(/'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"/g, "''");
    for (const c of t) { if (c === '{') { prof++; empezo = true; } if (c === '}') prof--; }
    if (!empezo && /=>.*;\s*$/.test(t)) return [inicio, i + 1];
    if (empezo && prof <= 0) return [inicio, i + 1];
  }
  return [inicio, lineas.length];
}

const nucleo = Object.keys(archivos).filter((f) => /lib\/(core|data|domain)\//.test(f)).sort();
console.log('== Cobertura por archivo del núcleo (lib/core, lib/data, lib/domain) ==');
console.log('archivo | instrucciones (líneas) | % | ramas | %');
let tl = 0, tlh = 0, tb = 0, tbh = 0;
for (const f of nucleo) {
  const r = resumen(archivos[f]);
  const [lh, lt] = r.lineas.split('/').map(Number); const [bh, bt] = r.ramas.split('/').map(Number);
  tl += lt; tlh += lh; tb += bt; tbh += bh;
  console.log(`${f} | ${r.lineas} | ${r.pl} | ${r.ramas} | ${r.pb}`);
}
console.log(`TOTAL núcleo | ${tlh}/${tl} | ${pct(tlh, tl)} | ${tbh}/${tb} | ${pct(tbh, tb)}`);

const todos = Object.keys(archivos);
let al = 0, alh = 0, ab = 0, abh = 0;
for (const f of todos) {
  const r = resumen(archivos[f]);
  const [lh, lt] = r.lineas.split('/').map(Number); const [bh, bt] = r.ramas.split('/').map(Number);
  al += lt; alh += lh; ab += bt; abh += bh;
}
console.log(`TOTAL app (lib/, incluye UI y prácticas) | ${alh}/${al} | ${pct(alh, al)} | ${abh}/${ab} | ${pct(abh, ab)}\n`);

const metodos = [
  ['Validación', 'WearableLectura.parse', 'lib/core/wearable.dart', 16],
  ['Validación', 'WearableClientImpl._alRecibir', 'lib/core/wearable_io.dart', 72],
  ['Validación', 'AuthRepository.validarContrasenaNueva', 'lib/data/auth_repository.dart', 23],
  ['Cálculo', 'WearableClient.resumenSesion', 'lib/core/wearable.dart', 48],
  ['Cálculo', 'traducirError', 'lib/data/api_client.dart', 94],
  ['Comunicación', 'ApiClient._send', 'lib/data/api_client.dart', 42],
  ['Comunicación', 'AppState.finishSession', 'lib/core/app_state.dart', 272],
];
console.log('== Cobertura por método crítico ==');
console.log('tipo | método | líneas del código | instrucciones | % | ramas | % | líneas sin ejecutar');
for (const [tipo, nombre, ruta, ini] of metodos) {
  const [a, b] = rango(ruta, ini);
  const r = resumen(archivos[ruta], a, b);
  console.log(`${tipo} | ${nombre} | ${a}-${b} | ${r.lineas} | ${r.pl} | ${r.ramas} | ${r.pb} | ${r.sinEjecutar.join(',') || '—'}`);
}
