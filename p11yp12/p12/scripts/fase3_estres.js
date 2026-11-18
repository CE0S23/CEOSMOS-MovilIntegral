// Práctica 12 · Fase 3: prueba de estrés reproducible de la API de CEOSMOS (SOLO local).
// Usuarios virtuales en lazo cerrado (cada uno manda la siguiente petición al recibir la
// anterior) durante una duración fija por escenario, con 1, 5, 10, 25 y 50 usuarios
// (cada uno con su propia cuenta p12_vuNN y su propio token).
//   node fase3_estres.js <base> <pid_api> <tokens.json> <salida.json> [etiqueta]
// Variables: P12_LECTURA (ruta GET), P12_DUR (s por escenario, 20), P12_VUS ("1,5,10,25,50"), P12_SOLO (lectura|escritura)
const { spawn, execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const crypto = require('crypto');

const [BASE = 'http://127.0.0.1:8080/api', PID, TOKENS, OUT, ETIQUETA = 'sin-etiqueta'] = process.argv.slice(2);
const DUR = +(process.env.P12_DUR || 20);
// Ruta de lectura: la que usa la app (antes ?limit=50; después de P12-O1, la primera página).
const LECTURA = process.env.P12_LECTURA || '/focus-sessions?limit=50';
const VUS = (process.env.P12_VUS || '1,5,10,25,50').split(',').map(Number);
const PSQL = 'C:/Program Files/PostgreSQL/16/bin/psql.exe';
const sql = (q) => execFileSync(PSQL, ['-h', '127.0.0.1', '-p', '5433', '-U', 'ceosmos', '-d', 'ceosmos_dev', '-AtF', '|', '-c', q]).toString().trim();
const r1 = (x) => Math.round(x * 10) / 10;
const pctl = (s, p) => s[Math.min(s.length - 1, Math.max(0, Math.ceil((p / 100) * s.length) - 1))];

const tokens = Object.values(JSON.parse(fs.readFileSync(TOKENS, 'utf8')));
if (tokens.length < Math.max(...VUS)) throw new Error(`hacen falta ${Math.max(...VUS)} tokens`);

// Muestreador del proceso de la API y de PostgreSQL: UN solo PowerShell que imprime una
// línea por segundo (lanzar un proceso por muestra cargaría la misma laptop).
function muestreador() {
  const ps = `
    $api=${PID}; $n=[Environment]::ProcessorCount
    while($true){
      $a=Get-Process -Id $api -ErrorAction SilentlyContinue
      $pgms=0; foreach($p in (Get-Process postgres -ErrorAction SilentlyContinue)){ $pgms += $p.TotalProcessorTime.TotalMilliseconds }
      "{0};{1};{2};{3};{4}" -f [DateTimeOffset]::Now.ToUnixTimeMilliseconds(), $a.TotalProcessorTime.TotalMilliseconds, $a.WorkingSet64, $pgms, $a.Threads.Count
      Start-Sleep -Milliseconds 1000
    }`;
  const p = spawn('powershell', ['-NoProfile', '-Command', ps]);
  const muestras = [];
  let resto = '';
  p.stderr.on('data', (d) => process.stderr.write('[muestreador] ' + d));
  p.on('exit', (c) => console.log('[muestreador] terminó con código', c));
  p.stdout.on('data', (d) => {
    resto += d.toString();
    const lineas = resto.split(/\r?\n/);
    resto = lineas.pop();
    for (const l of lineas) {
      const [t, cpu, ws, pg, hilos] = l.split(';').map(Number);
      if (!Number.isNaN(t) && !Number.isNaN(cpu)) muestras.push({ t, cpu, ws, pg, hilos });
    }
  });
  return { muestras, parar: () => p.kill() };
}

function serieCpu(muestras, desde, hasta) {
  const m = muestras.filter((x) => x.t >= desde - 1100 && x.t <= hasta + 1100);
  const cpu = [], pg = [];
  for (let i = 1; i < m.length; i++) {
    const dt = m[i].t - m[i - 1].t;
    cpu.push(((m[i].cpu - m[i - 1].cpu) / dt) * 100);
    pg.push(((m[i].pg - m[i - 1].pg) / dt) * 100);
  }
  if (m.length < 2) return { cpu_api_prom_pct: null, cpu_api_max_pct: null, cpu_pg_prom_pct: null, ram_api_max_mb: null, ram_api_fin_mb: null, muestras: m.length };
  const prom = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : null);
  return {
    cpu_api_prom_pct: r1(prom(cpu)), cpu_api_max_pct: r1(Math.max(...cpu)),
    cpu_pg_prom_pct: r1(prom(pg)),
    ram_api_max_mb: r1(Math.max(...m.map((x) => x.ws)) / 1048576),
    ram_api_fin_mb: r1(m.at(-1).ws / 1048576),
  };
}

async function pedir(metodo, ruta, token, body) {
  const t0 = performance.now();
  try {
    const r = await fetch(BASE + ruta, {
      method: metodo,
      headers: { Authorization: `Bearer ${token}`, ...(body && { 'Content-Type': 'application/json' }) },
      body: body && JSON.stringify(body),
      signal: AbortSignal.timeout(30_000),
    });
    const buf = Buffer.from(await r.arrayBuffer());
    return { s: r.status, ms: performance.now() - t0, b: buf.length };
  } catch (e) {
    return { s: e.name === 'TimeoutError' ? 'timeout' : 'red', ms: performance.now() - t0, b: 0 };
  }
}

// Mismos metadatos que envía la app (resumen del wearable, ~230 B).
const metadatos = { source: 'p12-estres', kind: 'audio', wearable: { deviceId: 'banda', transport: 'TCP', samples: 1500, avgHeartRate: 72.4, minHeartRate: 58, maxHeartRate: 121, lastSteps: 1240 } };
let secuencia = 0;
const nuevaSesion = () => {
  const fin = Date.now() - 60_000 - (secuencia++ % 100000) * 1000;
  return { contentKey: 'orbit', mode: 'FOCUS', startedAt: new Date(fin - 300_000).toISOString(), endedAt: new Date(fin).toISOString(), durationSeconds: 300, targetMinutes: 5, completed: true, metadata: metadatos, clientId: crypto.randomUUID() };
};

async function escenario(nombre, vus, hacer, mon, durObjetivo = DUR) {
  const pg0 = sql(`select xact_commit, tup_fetched, tup_inserted, blks_hit, blks_read from pg_stat_database where datname='ceosmos_dev'`).split('|').map(Number);
  const res = [];
  const t0 = Date.now(), fin = t0 + durObjetivo * 1000;
  await Promise.all(Array.from({ length: vus }, async (_, v) => {
    while (Date.now() < fin) res.push(await hacer(tokens[v]));
  }));
  const t1 = Date.now();
  await new Promise((ok) => setTimeout(ok, 1500)); // pg_stat se publica cada ~1 s
  const pg1 = sql(`select xact_commit, tup_fetched, tup_inserted, blks_hit, blks_read from pg_stat_database where datname='ceosmos_dev'`).split('|').map(Number);
  const ms = res.map((r) => r.ms).sort((a, b) => a - b);
  const ok = res.filter((r) => typeof r.s === 'number' && r.s >= 200 && r.s < 300).length;
  const codigos = res.reduce((m, r) => ((m[r.s] = (m[r.s] || 0) + 1), m), {});
  const dur = (t1 - t0) / 1000;
  const fila = {
    escenario: nombre, usuarios: vus, duracion_s: r1(dur), solicitudes: res.length, exitosas: ok,
    errores: res.length - ok, errores_pct: r1(((res.length - ok) / res.length) * 100), codigos,
    rps: r1(res.length / dur), rps_exitosas: r1(ok / dur),
    prom_ms: r1(ms.reduce((a, b) => a + b, 0) / ms.length), p50_ms: r1(pctl(ms, 50)), p90_ms: r1(pctl(ms, 90)),
    p95_ms: r1(pctl(ms, 95)), p99_ms: r1(pctl(ms, 99)), min_ms: r1(ms[0]), max_ms: r1(ms.at(-1)),
    bytes_resp_prom: Math.round(res.reduce((s, r) => s + r.b, 0) / res.length),
    ...serieCpu(mon.muestras, t0, t1),
    pg_transacciones: pg1[0] - pg0[0], pg_tx_por_solicitud: r1((pg1[0] - pg0[0]) / res.length),
    pg_filas_leidas: pg1[1] - pg0[1], pg_filas_insertadas: pg1[2] - pg0[2],
  };
  console.log(`${nombre.padEnd(9)} vus=${String(vus).padStart(2)} rps=${fila.rps} prom=${fila.prom_ms} p90=${fila.p90_ms} p95=${fila.p95_ms} max=${fila.max_ms} err=${fila.errores_pct}% cpuAPI=${fila.cpu_api_prom_pct}% ram=${fila.ram_api_max_mb}MB tx/sol=${fila.pg_tx_por_solicitud} ${JSON.stringify(codigos)}`);
  return fila;
}

(async () => {
  // Precarga idéntica en cada corrida: 50 sesiones por cuenta con los metadatos reales.
  sql(`delete from "FocusSession" where metadata->>'source' in ('p12-estres','p12-base')`);
  sql(`insert into "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
       select 'p12-b-'||u.id||'-'||g, u.id, 'orbit', 'FOCUS', now()-(g||' hour')::interval, now()-(g||' hour')::interval+interval '25 min', 1500, 25, true,
              '${JSON.stringify({ ...metadatos, source: 'p12-base' })}'::jsonb
       from "User" u, generate_series(1,50) g where u.email like 'p12\\_vu%'`);
  sql('analyze "FocusSession"');
  const mon = muestreador();
  await new Promise((ok) => setTimeout(ok, 2500));
  const filas = [];
  const solo = process.env.P12_SOLO;
  // Calentamiento (no se reporta): JIT de Node, pool de Prisma y caché de PostgreSQL.
  await escenario('calentar', 5, (tk) => pedir('GET', LECTURA, tk), mon, 5);
  if (!solo || solo === 'lectura') for (const v of VUS) {
    filas.push(await escenario('lectura', v, (tk) => pedir('GET', LECTURA, tk), mon));
    await new Promise((ok) => setTimeout(ok, 2000));
  }
  if (!solo || solo === 'escritura') for (const v of VUS) {
    filas.push(await escenario('escritura', v, (tk) => pedir('POST', '/focus-sessions', tk, nuevaSesion()), mon));
    await new Promise((ok) => setTimeout(ok, 2000));
  }
  mon.parar();
  // Integridad: filas insertadas vs. 201 recibidos, y sin clientId repetido.
  const insertadas = +sql(`select count(*) from "FocusSession" where metadata->>'source'='p12-estres'`);
  const dup = +sql(`select count(*) from (select "clientId" from "FocusSession" where metadata->>'source'='p12-estres' group by 1 having count(*)>1) d`);
  const creadas201 = filas.filter((f) => f.escenario === 'escritura').reduce((s, f) => s + (f.codigos['201'] || 0), 0);
  const borradas = sql(`with d as (delete from "FocusSession" where metadata->>'source' in ('p12-estres','p12-base') returning 1) select count(*) from d`);
  const maquina = { cpu: os.cpus()[0].model, hilos: os.cpus().length, ram_gb: r1(os.totalmem() / 2 ** 30), so: `${os.type()} ${os.release()}`, node: process.version };
  const salida = { etiqueta: ETIQUETA, fecha: new Date().toISOString(), base: BASE, duracion_por_escenario_s: DUR, ruta_lectura: LECTURA, maquina, filas,
    integridad: { respuestas_201: creadas201, filas_insertadas: insertadas, clientId_duplicados: dup }, limpieza_filas_borradas: +borradas };
  if (OUT) fs.writeFileSync(OUT, JSON.stringify(salida, null, 2));
  console.log('integridad', salida.integridad, 'borradas', borradas);
})();
