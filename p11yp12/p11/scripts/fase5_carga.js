// Práctica 11 · Fase 5 (NET-07): prueba de carga controlada contra la API LOCAL
// (PostgreSQL .devdb). Nunca contra Neon/Resend. Escenarios: 1, 5 y 10 usuarios
// concurrentes; cada usuario virtual (cuenta propia p11_vuNN) hace R solicitudes.
//   node fase5_carga.js http://127.0.0.1:8080/api <pid_api> salida.json
// Contraseña de las cuentas: P11_PASS.
const { execFile, execFileSync } = require('child_process');
const os = require('os');
const BASE = process.argv[2] || 'http://127.0.0.1:8080/api';
const PID = process.argv[3];
const OUT = process.argv[4];
const R = +(process.env.P11_REQ_POR_USUARIO || 30);
const PSQL = 'C:/Program Files/PostgreSQL/16/bin/psql.exe';
const sql = (q) => execFileSync(PSQL, ['-h', '127.0.0.1', '-p', '5433', '-U', 'ceosmos', '-d', 'ceosmos_dev', '-AtF', '|', '-c', q]).toString().trim();

const pctl = (arr, p) => { const s = [...arr].sort((a, b) => a - b); return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)]; };
const r1 = (x) => Math.round(x * 10) / 10;

function cpuMem() {
  if (!PID) return null;
  const o = execFileSync('powershell', ['-NoProfile', '-c', `$p=Get-Process -Id ${PID}; "$($p.TotalProcessorTime.TotalMilliseconds);$($p.WorkingSet64)"`]).toString().trim();
  const [cpu, mem] = o.split(';').map(Number);
  return { cpuMs: cpu, mem };
}
function muestrearMemoria() {
  let pico = 0, activo = true;
  const tick = () => {
    if (!activo || !PID) return;
    execFile('powershell', ['-NoProfile', '-c', `(Get-Process -Id ${PID}).WorkingSet64`], (e, so) => {
      if (!e) pico = Math.max(pico, +so.toString().trim());
      setTimeout(tick, 300);
    });
  };
  tick();
  return () => { activo = false; return pico; };
}
function pgStats() {
  const [commit, rollback, ins, ret, fetched] = sql(`select xact_commit, xact_rollback, tup_inserted, tup_returned, tup_fetched from pg_stat_database where datname='ceosmos_dev'`).split('|').map(Number);
  return { commit, rollback, ins, ret, fetched };
}

async function pedir(metodo, ruta, token, body) {
  const t0 = performance.now();
  try {
    const r = await fetch(BASE + ruta, {
      method: metodo,
      headers: { Authorization: `Bearer ${token}`, ...(body && { 'Content-Type': 'application/json' }) },
      body: body && JSON.stringify(body),
    });
    const buf = Buffer.from(await r.arrayBuffer());
    return { ok: r.status >= 200 && r.status < 300, status: r.status, ms: performance.now() - t0, bytes: buf.length, enviados: body ? Buffer.byteLength(JSON.stringify(body)) : 0 };
  } catch (e) {
    return { ok: false, status: 'red', ms: performance.now() - t0, bytes: 0, enviados: 0 };
  }
}

const sesion = (i) => {
  const fin = Date.now() - 60_000 - i * 1000;
  return { contentKey: 'orbit', mode: 'FOCUS', startedAt: new Date(fin - 300_000).toISOString(), endedAt: new Date(fin).toISOString(), durationSeconds: 300, targetMinutes: 5, completed: true, metadata: { source: 'p11-carga' }, clientId: require('crypto').randomUUID() };
};

async function escenario(nombre, tokens, vus, crear) {
  const antesCpu = cpuMem();
  const antesPg = pgStats();
  const antesIns = +sql(`select count(*) from "FocusSession" where metadata->>'source'='p11-carga'`);
  const fin = muestrearMemoria();
  const resultados = [];
  const t0 = performance.now();
  await Promise.all(tokens.slice(0, vus).map(async (tk, v) => {
    for (let i = 0; i < R; i++) resultados.push(await crear(tk, v * R + i));
  }));
  const dur = (performance.now() - t0) / 1000;
  const memPico = fin();
  const despuesCpu = cpuMem();
  await new Promise((ok) => setTimeout(ok, 1500)); // pg_stat se publica cada ~1 s
  const despuesPg = pgStats();
  const insertadas = +sql(`select count(*) from "FocusSession" where metadata->>'source'='p11-carga'`) - antesIns;
  const ms = resultados.map((r) => r.ms);
  const bytes = resultados.reduce((s, r) => s + r.bytes, 0);
  const enviados = resultados.reduce((s, r) => s + r.enviados, 0);
  const codigos = resultados.reduce((m, r) => ((m[r.status] = (m[r.status] || 0) + 1), m), {});
  const fila = {
    escenario: nombre, usuarios: vus, solicitudes: resultados.length,
    exitosas: resultados.filter((r) => r.ok).length, fallidas: resultados.filter((r) => !r.ok).length, codigos,
    promedio_ms: r1(ms.reduce((a, b) => a + b, 0) / ms.length), p50_ms: r1(pctl(ms, 50)), p95_ms: r1(pctl(ms, 95)),
    min_ms: r1(Math.min(...ms)), max_ms: r1(Math.max(...ms)),
    duracion_s: r1(dur), rps: r1(resultados.length / dur),
    mbps_respuesta: +((bytes * 8) / dur / 1e6).toFixed(3), mbps_envio: +((enviados * 8) / dur / 1e6).toFixed(3),
    bytes_respuesta_prom: Math.round(bytes / resultados.length),
    cpu_api_pct: antesCpu ? r1(((despuesCpu.cpuMs - antesCpu.cpuMs) / (dur * 1000)) * 100) : null,
    cpu_api_pct_de_maquina: antesCpu ? r1(((despuesCpu.cpuMs - antesCpu.cpuMs) / (dur * 1000 * os.cpus().length)) * 100) : null,
    mem_api_mb: despuesCpu ? r1(Math.max(memPico || 0, despuesCpu.mem) / 1048576) : null,
    pg_transacciones: despuesPg.commit - antesPg.commit, pg_rollbacks: despuesPg.rollback - antesPg.rollback,
    filas_focus_insertadas: insertadas, pg_filas_leidas: despuesPg.fetched - antesPg.fetched,
  };
  console.log(JSON.stringify(fila));
  return fila;
}

(async () => {
  const tokens = [];
  for (let i = 1; i <= 10; i++) {
    const email = `p11_vu${String(i).padStart(2, '0')}@ceosmos.test`;
    const entrar = () => fetch(BASE + '/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: process.env.P11_PASS }) });
    let r = await entrar();
    if (r.status === 429) { // /auth limita a 10 inicios de sesión por minuto e IP
      console.log(`429 en el login de ${email}: se espera 61 s`);
      await new Promise((ok) => setTimeout(ok, 61_000));
      r = await entrar();
    }
    const j = await r.json();
    if (!j.token) throw new Error(`login ${email}: ${r.status} ${JSON.stringify(j)}`);
    tokens.push(j.token);
  }
  // Precarga: 50 sesiones por cuenta (mismo tamaño de respuesta en todos los escenarios de lectura).
  sql(`insert into "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
       select 'p11-cb-'||u.id||'-'||g, u.id, 'orbit', 'FOCUS', now()-(g||' hour')::interval, now()-(g||' hour')::interval+interval '25 min', 1500, 25, true,
              jsonb_build_object('source','p11-carga-base','kind','audio','wearable',jsonb_build_object('deviceId','band','transport','TCP','samples',1500,'avgHeartRate',72.4,'minHeartRate',58,'maxHeartRate',121))
       from "User" u, generate_series(1,50) g where u.email like 'p11\_vu%' on conflict do nothing`);
  const maquina = { cpu: os.cpus()[0].model, nucleos: os.cpus().length, ram_gb: r1(os.totalmem() / 2 ** 30), so: `${os.type()} ${os.release()}`, node: process.version };
  const filas = [];
  // Calentamiento (no se reporta): JIT de Node, pool de Prisma y caché de PostgreSQL.
  await escenario('calentamiento', tokens, 1, (tk) => pedir('GET', '/focus-sessions?limit=50', tk));
  for (const vus of [1, 5, 10]) {
    filas.push(await escenario('Lectura GET /focus-sessions?limit=50', tokens, vus, (tk) => pedir('GET', '/focus-sessions?limit=50', tk)));
  }
  for (const vus of [1, 5, 10]) {
    filas.push(await escenario('Escritura POST /focus-sessions', tokens, vus, (tk, i) => pedir('POST', '/focus-sessions', tk, sesion(i))));
  }
  const borradas = sql(`with d as (delete from "FocusSession" where metadata->>'source' in ('p11-carga','p11-carga-base') returning 1) select count(*) from d`);
  for (const tk of tokens) await fetch(BASE + '/auth/logout', { method: 'POST', headers: { Authorization: `Bearer ${tk}` } });
  const salida = { fecha: new Date().toISOString(), base: BASE, solicitudes_por_usuario: R, maquina, filas, limpieza_filas_borradas: +borradas };
  if (OUT) require('fs').writeFileSync(OUT, JSON.stringify(salida, null, 2));
  console.log('Limpieza: sesiones de carga borradas =', borradas);
})();
