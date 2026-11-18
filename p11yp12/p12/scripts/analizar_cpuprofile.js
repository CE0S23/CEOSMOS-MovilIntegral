// Práctica 12 · Resume un .cpuprofile de la API: tiempo propio (self) por función y por
// componente (Prisma, Express/Nest, Passport/JWT, JSON, GC, inactivo…).
//   node analizar_cpuprofile.js <perfil.cpuprofile> [salida.txt]
const fs = require('fs');
const [, , ARCH, OUT] = process.argv;
const p = JSON.parse(fs.readFileSync(ARCH, 'utf8'));
const dt = {};
for (let i = 0; i < p.samples.length; i++) dt[p.samples[i]] = (dt[p.samples[i]] || 0) + (p.timeDeltas[i] || 0);
const total = Object.values(dt).reduce((a, b) => a + b, 0);
const porNodo = new Map(p.nodes.map((n) => [n.id, n]));
const padre = new Map();
for (const n of p.nodes) for (const c of n.children || []) padre.set(c, n.id);

function componente(n) {
  const u = n.callFrame.url || '', f = n.callFrame.functionName;
  if (f === '(idle)') return 'Inactivo (esperando E/S)';
  if (f === '(garbage collector)') return 'Recolector de basura (GC)';
  if (f === '(program)') return 'Motor V8 / nativo';
  if (/@prisma|\.prisma[\\/]client|prisma[\\/]client/.test(u)) return 'Prisma (cliente JS + motor)';
  if (/passport|jsonwebtoken|jws|jwa/.test(u)) return 'Passport / verificación JWT';
  if (/class-validator|class-transformer/.test(u)) return 'ValidationPipe (class-validator/transformer)';
  if (/@nestjs/.test(u)) return 'NestJS (enrutado, guards, interceptores)';
  if (/express|body-parser|router|finalhandler|send|cookie|helmet|cors|on-finished|raw-body|qs/.test(u)) return 'Express y middlewares (helmet, cors, cookies)';
  if (/@nestjs\/throttler|throttler/.test(u)) return 'Throttler';
  if (/ceosmos-api[\\/]dist/.test(u)) return 'Código de la API (dist/)';
  if (/^node:|internal/.test(u) || u === '') {
    if (/stringify|parse/i.test(f)) return 'JSON (serializar/parsear)';
    return 'Node interno (red, streams, timers, crypto)';
  }
  return 'Otras dependencias';
}
const porComp = {}, porFn = {};
for (const [id, t] of Object.entries(dt)) {
  const n = porNodo.get(+id);
  const c = componente(n);
  porComp[c] = (porComp[c] || 0) + t;
  const k = `${n.callFrame.functionName || '(anónima)'}  ${(n.callFrame.url || '').split(/[\\/]node_modules[\\/]/).pop().slice(-70)}:${n.callFrame.lineNumber + 1}`;
  porFn[k] = (porFn[k] || 0) + t;
}
// Tiempo inclusivo (self + hijos) de funciones clave
const incl = {};
function inclusivo(id) { const n = porNodo.get(id); let t = dt[id] || 0; for (const c of n.children || []) t += inclusivo(c); n._incl = t; return t; }
inclusivo(p.nodes[0].id);
for (const n of p.nodes) {
  const f = n.callFrame.functionName;
  if (['validate', 'list', 'create', 'stringify', 'serialize', 'canActivate', 'transform', 'deserialize'].includes(f) || /JwtStrategy|FocusSessions/.test(n.callFrame.url)) {
    const k = `${f} ${(n.callFrame.url || '').split(/[\\/]/).slice(-2).join('/')}`;
    incl[k] = (incl[k] || 0) + n._incl;
  }
}
const pct = (t) => ((t / total) * 100).toFixed(1).padStart(5) + ' %';
const ms = (t) => (t / 1000).toFixed(0).padStart(7) + ' ms';
const lineas = [];
lineas.push(`Perfil: ${ARCH}`, `Duración muestreada: ${(total / 1e6).toFixed(2)} s, ${p.samples.length} muestras`, '', '== Tiempo propio por componente ==');
for (const [c, t] of Object.entries(porComp).sort((a, b) => b[1] - a[1])) lineas.push(`${pct(t)} ${ms(t)}  ${c}`);
const ocupado = total - (porComp['Inactivo (esperando E/S)'] || 0);
lineas.push('', `Hilo JS ocupado: ${pct(ocupado)} del tiempo`, '', '== 25 funciones con más tiempo propio ==');
for (const [f, t] of Object.entries(porFn).sort((a, b) => b[1] - a[1]).slice(0, 25)) lineas.push(`${pct(t)} ${ms(t)}  ${f}`);
lineas.push('', '== Tiempo inclusivo de funciones de la API ==');
for (const [f, t] of Object.entries(incl).sort((a, b) => b[1] - a[1]).slice(0, 15)) lineas.push(`${pct(t)} ${ms(t)}  ${f}`);
const txt = lineas.join('\n');
console.log(txt);
if (OUT) fs.writeFileSync(OUT, txt + '\n');
