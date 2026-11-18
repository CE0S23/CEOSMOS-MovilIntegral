// Práctica 12 · Fase 4: pruebas avanzadas de base de datos (PostgreSQL 16 LOCAL, .devdb).
// Consulta crítica: el historial de sesiones de enfoque (GET /focus-sessions), más las
// consultas que la API hace en CADA petición autenticada (JwtStrategy.validate).
//   node fase4_db.js <salida.json>
// Crea volumen sintético marcado con el prefijo 'p12-db-' y lo BORRA al final.
const path = require('path');
const API = process.env.CEOSMOS_API || 'C:/Users/cesar/OneDrive/Escritorio/8°/DesarrolloWEB/WEBANGULAR/ceosmos-api';
const { Pool } = require(path.join(API, 'node_modules', 'pg'));
const fs = require('fs');
const OUT = process.argv[2];
const URL = 'postgresql://ceosmos@127.0.0.1:5433/ceosmos_dev';
const pool = new Pool({ connectionString: URL, max: 25 });
const r3 = (x) => Math.round(x * 1000) / 1000;
const pctl = (a, p) => { const s = [...a].sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.ceil((p / 100) * s.length) - 1)]; };
const salida = { fecha: new Date().toISOString(), pruebas: [] };
const log = (...a) => console.log(...a);

async function medir(id, nombre, sqlTxt, params, n = 30) {
  const c = await pool.connect();
  try {
    await c.query(sqlTxt, params); // calentamiento (plan en caché, páginas en memoria)
    const t = []; let filas = 0, bytes = 0;
    for (let i = 0; i < n; i++) {
      const t0 = performance.now();
      const r = await c.query(sqlTxt, params);
      t.push(performance.now() - t0);
      filas = r.rowCount; bytes = Buffer.byteLength(JSON.stringify(r.rows));
    }
    const plan = (await c.query('EXPLAIN (ANALYZE, BUFFERS) ' + sqlTxt, params)).rows.map((x) => x['QUERY PLAN']);
    const ejec = +(plan.find((l) => l.startsWith('Execution Time')) || '').replace(/[^\d.]/g, '');
    const indice = plan.filter((l) => /Index|Seq Scan|Sort/.test(l)).map((l) => l.trim().split('  (')[0]);
    const fila = { id, nombre, sql: sqlTxt.replace(/\s+/g, ' '), repeticiones: n, filas, bytes_json: bytes,
      prom_ms: r3(t.reduce((a, b) => a + b, 0) / n), p95_ms: r3(pctl(t, 95)), max_ms: r3(Math.max(...t)),
      ejecucion_pg_ms: ejec, nodos_plan: indice, plan };
    log(`${id} ${nombre}: ${fila.filas} filas, prom ${fila.prom_ms} ms (cliente), ${ejec} ms en PG, ${indice.join(' > ')}`);
    salida.pruebas.push(fila);
    return fila;
  } finally { c.release(); }
}

async function esperasDeBloqueo(fn) {
  // Muestrea cada 5 ms cuántas conexiones esperan un bloqueo (wait_event_type = 'Lock').
  const mon = await pool.connect();
  let activo = true, max = 0, muestras = 0, conEspera = 0;
  const bucle = (async () => {
    while (activo) {
      const r = await mon.query(`select count(*)::int n from pg_stat_activity where datname='ceosmos_dev' and wait_event_type='Lock'`);
      muestras++; if (r.rows[0].n > 0) conEspera++; max = Math.max(max, r.rows[0].n);
      await new Promise((ok) => setTimeout(ok, 5));
    }
  })();
  const t0 = performance.now();
  const res = await fn();
  const ms = performance.now() - t0;
  activo = false; await bucle; mon.release();
  return { ...res, duracion_ms: r3(ms), muestras_monitor: muestras, muestras_con_espera: conEspera, max_conexiones_esperando: max };
}

(async () => {
  const q = (s, p) => pool.query(s, p);
  await q(`delete from "User" where id like 'p12-db-%'`);
  // Volumen: 1 000 usuarios ficticios con 100 sesiones cada uno + 1 usuario "pesado" con 20 000.
  log('Generando volumen sintético...');
  await q(`insert into "User"(id,email,username,"passwordHash","updatedAt")
           select 'p12-db-u-'||g, 'p12-db-u-'||g||'@vol.test', 'p12dbu'||g, 'x', now() from generate_series(0,1000) g`);
  await q(`insert into "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
           select 'p12-db-f-'||g, 'p12-db-u-'||(g%1000+1), (array['orbit','rain','forest'])[g%3+1], (array['FOCUS','RELAX','SLEEP_SOUNDS'])[g%2+1]::"FocusMode",
                  now()-(g||' min')::interval, now()-(g||' min')::interval+interval '5 min', 300, 5, g%4<>0,
                  '{"source":"p12-db","kind":"audio","wearable":{"deviceId":"banda","transport":"TCP","samples":300,"avgHeartRate":71.2,"minHeartRate":58,"maxHeartRate":110}}'::jsonb
           from generate_series(1,100000) g`).catch(async (e) => {
    // El enum puede no tener SLEEP_SOUNDS: se usan solo los valores existentes.
    const modos = (await q(`select unnest(enum_range(null::"FocusMode"))::text m`)).rows.map((r) => r.m);
    log('modos del enum:', modos.join(','), '(', e.message, ')');
    await q(`insert into "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
             select 'p12-db-f-'||g, 'p12-db-u-'||(g%1000+1), (array['orbit','rain','forest'])[g%3+1], (array[${modos.map((m) => `'${m}'`).join(',')}])[g%${modos.length}+1]::"FocusMode",
                    now()-(g||' min')::interval, now()-(g||' min')::interval+interval '5 min', 300, 5, g%4<>0,
                    '{"source":"p12-db","kind":"audio","wearable":{"deviceId":"banda","transport":"TCP","samples":300,"avgHeartRate":71.2,"minHeartRate":58,"maxHeartRate":110}}'::jsonb
             from generate_series(1,100000) g`);
  });
  const modo = (await q(`select mode::text from "FocusSession" where id='p12-db-f-1'`)).rows[0].mode;
  await q(`insert into "FocusSession"(id,"userId","contentKey",mode,"startedAt","endedAt","durationSeconds","targetMinutes",completed,metadata)
           select 'p12-db-h-'||g, 'p12-db-u-0', 'orbit', '${modo}', now()-(g||' min')::interval, now()-(g||' min')::interval+interval '5 min', 300, 5, g%4<>0,
                  '{"source":"p12-db","kind":"audio","wearable":{"deviceId":"banda","transport":"TCP","samples":300,"avgHeartRate":71.2,"minHeartRate":58,"maxHeartRate":110}}'::jsonb
           from generate_series(1,20000) g`);
  await q(`insert into "Session"(id,"userId",token,"expiresAt") select 'p12-db-s-'||g, 'p12-db-u-'||(g%1000+1), md5('p12'||g), now()+interval '7 days' from generate_series(1,20000) g`);
  await q('analyze "FocusSession"; analyze "Session"; analyze "User"');
  const tam = (await q(`select relname, n_live_tup from pg_stat_user_tables where relname in ('FocusSession','Session','User') order by 1`)).rows;
  salida.volumen = tam; log('volumen', JSON.stringify(tam));
  const hasta = (await q(`select "startedAt" from "FocusSession" where "userId"='p12-db-u-0' order by "startedAt" desc offset 19000 limit 1`)).rows[0].startedAt;

  // 1-4: tiempos, filas e índices
  await medir('DB-01', 'Consulta individual por id (PK)', `select * from "FocusSession" where id = $1`, ['p12-db-f-777']);
  await medir('DB-02', 'Conjunto pequeño: últimas 10 sesiones del usuario', `select * from "FocusSession" where "userId" = $1 order by "startedAt" desc limit 10`, ['p12-db-u-7']);
  await medir('DB-03a', 'Conjunto grande: historial completo del usuario pesado (20 000, sin LIMIT)', `select * from "FocusSession" where "userId" = $1 order by "startedAt" desc`, ['p12-db-u-0'], 10);
  await medir('DB-03b', 'Conjunto grande paginado: primera página de 50 (lo que hace la API)', `select * from "FocusSession" where "userId" = $1 order by "startedAt" desc limit 50`, ['p12-db-u-0']);
  await medir('DB-03c', 'Página profunda con OFFSET 19 000', `select * from "FocusSession" where "userId" = $1 order by "startedAt" desc offset 19000 limit 50`, ['p12-db-u-0'], 10);
  await medir('DB-03d', 'Página profunda por cursor (keyset: startedAt < cursor)', `select * from "FocusSession" where "userId" = $1 and "startedAt" < $2 order by "startedAt" desc limit 50`, ['p12-db-u-0', hasta]);
  await medir('DB-04', 'Con filtros: usuario + modo + completada + rango de fechas', `select * from "FocusSession" where "userId" = $1 and mode = $2 and completed = true and "startedAt" >= now() - interval '7 days' order by "startedAt" desc limit 50`, ['p12-db-u-0', modo]);
  await medir('DB-04b', 'Agregado: minutos totales del usuario pesado (SUM en el servidor)', `select count(*)::int sesiones, coalesce(sum("durationSeconds"),0)::int segundos from "FocusSession" where "userId" = $1`, ['p12-db-u-0']);
  // Consultas de autenticación que se repiten en CADA petición (JwtStrategy.validate)
  const tok = (await q(`select token from "Session" where id='p12-db-s-77'`)).rows[0].token;
  await medir('DB-AUTH-a', 'Auth actual (1/2): sesión por token', `select * from "Session" where token = $1 limit 1`, [tok]);
  await medir('DB-AUTH-b', 'Auth actual (2/2): usuario por id', `select * from "User" where id = $1 limit 1`, ['p12-db-u-78']);
  await medir('DB-AUTH-c', 'Auth optimizada: sesión + usuario en una sola consulta (JOIN)', `select u.* , s."expiresAt" as "sessionExpiresAt" from "Session" s join "User" u on u.id = s."userId" where s.token = $1`, [tok]);

  // P12-O1: consultas del historial tal como las genera la API optimizada.
  const CAMPOS = `id, "clientId", "contentKey", mode::text, "startedAt", "endedAt", "durationSeconds", "targetMinutes", completed, metadata`;
  await medir('DB-OPT-1', 'Optimizada: primera página de 20, solo los campos que usa la app', `select ${CAMPOS} from "FocusSession" where "userId" = $1 order by "startedAt" desc, id desc limit 20`, ['p12-db-u-0']);
  const cursorId = (await q(`select id from "FocusSession" where "userId"='p12-db-u-0' order by "startedAt" desc, id desc offset 19000 limit 1`)).rows[0].id;
  // DB-OPT-2a: forma que genera el `cursor` nativo de Prisma (OR sin rango en el índice).
  await medir('DB-OPT-2a', 'Cursor nativo de Prisma: página profunda (después de la sesión 19 000)',
    `select ${CAMPOS} from "FocusSession" where "userId" = $1 and ("startedAt" < (select "startedAt" from "FocusSession" where id = $2)
       or ("startedAt" = (select "startedAt" from "FocusSession" where id = $2) and id < $2)) order by "startedAt" desc, id desc limit 20`, ['p12-db-u-0', cursorId]);
  // DB-OPT-2b: keyset que usa la API corregida: `startedAt <= ref` es rango del índice.
  const ref = (await q(`select "startedAt" from "FocusSession" where id = $1`, [cursorId])).rows[0].startedAt;
  await medir('DB-OPT-2b', 'Keyset de la API: startedAt <= ref (rango del índice) y desempate por id',
    `select ${CAMPOS} from "FocusSession" where "userId" = $1 and "startedAt" <= $2 and ("startedAt" < $2 or id < $3) order by "startedAt" desc, id desc limit 20`, ['p12-db-u-0', ref, cursorId]);
  if (process.env.P12_DB_INDICE_RESUMEN) {
    // Experimento: índice cubriente para que el resumen (COUNT/SUM) no lea la tabla.
    await q(`create index if not exists "p12_tmp_resumen_idx" on "FocusSession"("userId") include ("durationSeconds")`);
    await q(`vacuum analyze "FocusSession"`);
    await medir('DB-04c', 'Resumen con índice cubriente (userId) INCLUDE (durationSeconds) — experimento', `select count(*)::int sesiones, coalesce(sum("durationSeconds"),0)::int segundos from "FocusSession" where "userId" = $1`, ['p12-db-u-0']);
    await q(`drop index "p12_tmp_resumen_idx"`);
  }

  // 5. Actualizaciones concurrentes sobre filas DISTINTAS del mismo usuario
  const filasU = (await q(`select id from "FocusSession" where "userId"='p12-db-u-0' order by "startedAt" desc limit 400`)).rows.map((r) => r.id);
  const t5 = await esperasDeBloqueo(async () => {
    const lat = [];
    await Promise.all(filasU.map(async (id, i) => {
      const t0 = performance.now();
      await q(`update "FocusSession" set completed = not completed where id = $1`, [id]);
      lat.push(performance.now() - t0);
    }));
    const p = (await q(`select count(*)::int n from "FocusSession" where id = any($1)`, [filasU])).rows[0].n;
    return { actualizaciones: filasU.length, conexiones_pool: 25, prom_ms: r3(lat.reduce((a, b) => a + b, 0) / lat.length), p95_ms: r3(pctl(lat, 95)), filas_intactas: p };
  });
  salida.concurrencia_filas_distintas = t5; log('DB-05', JSON.stringify(t5));

  // 6. Escrituras simultáneas sobre la MISMA fila (20 clientes × 25 incrementos = 500)
  const objetivo = 'p12-db-h-1';
  // targetMinutes 180 para que el CHECK durationSeconds <= targetMinutes*60 admita los 500 incrementos.
  const reiniciar = () => q(`update "FocusSession" set "durationSeconds" = 0, "targetMinutes" = 180 where id = $1`, [objetivo]);
  const N = 20, K = 25;
  const variantes = {
    'a) leer y luego escribir (patrón de ORM sin bloqueo)': async () => {
      const r = await q(`select "durationSeconds" from "FocusSession" where id=$1`, [objetivo]);
      await q(`update "FocusSession" set "durationSeconds"=$2 where id=$1`, [objetivo, r.rows[0].durationSeconds + 1]);
    },
    'b) incremento atómico en una sola sentencia': async () => {
      await q(`update "FocusSession" set "durationSeconds"="durationSeconds"+1 where id=$1`, [objetivo]);
    },
    'c) transacción con SELECT … FOR UPDATE': async () => {
      const c = await pool.connect();
      try {
        await c.query('begin');
        const r = await c.query(`select "durationSeconds" from "FocusSession" where id=$1 for update`, [objetivo]);
        await c.query(`update "FocusSession" set "durationSeconds"=$2 where id=$1`, [objetivo, r.rows[0].durationSeconds + 1]);
        await c.query('commit');
      } catch (e) { await c.query('rollback'); throw e; } finally { c.release(); }
    },
  };
  salida.misma_fila = [];
  for (const [nombre, op] of Object.entries(variantes)) {
    await reiniciar();
    const r = await esperasDeBloqueo(async () => {
      let errores = 0;
      await Promise.all(Array.from({ length: N }, async () => { for (let k = 0; k < K; k++) await op().catch(() => errores++); }));
      const final = (await q(`select "durationSeconds" v from "FocusSession" where id=$1`, [objetivo])).rows[0].v;
      return { esperado: N * K, final, actualizaciones_perdidas: N * K - final, errores };
    });
    salida.misma_fila.push({ variante: nombre, ...r }); log('DB-06', nombre, JSON.stringify(r));
  }
  // Integridad después de todo
  salida.integridad = (await q(`select count(*)::int filas, count(distinct id)::int ids_unicos,
      count(*) filter (where "endedAt" < "startedAt")::int fechas_invalidas,
      count(*) filter (where "durationSeconds" > "targetMinutes"*60)::int duracion_invalida
      from "FocusSession" where "userId" like 'p12-db-%' and id <> $1`, [objetivo])).rows[0];
  log('integridad', JSON.stringify(salida.integridad));
  const b = await q(`with d as (delete from "User" where id like 'p12-db-%' returning 1) select count(*)::int n from d`);
  salida.limpieza = { usuarios_borrados_en_cascada: b.rows[0].n, focus_restantes: (await q(`select count(*)::int n from "FocusSession" where id like 'p12-db-%'`)).rows[0].n };
  log('limpieza', JSON.stringify(salida.limpieza));
  if (OUT) fs.writeFileSync(OUT, JSON.stringify(salida, null, 2));
  await pool.end();
})().catch(async (e) => { console.error(e); await pool.query(`delete from "User" where id like 'p12-db-%'`).catch(() => {}); process.exit(1); });
