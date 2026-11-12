// Práctica 11 · Fase 4 (DB-06): operaciones concurrentes sobre el mismo registro a
// través de la API real (entorno local). Cada escenario lanza N peticiones a la vez.
//   node fase4_concurrencia.js http://127.0.0.1:8080/api salida.json
// Credenciales: P11_USER / P11_PASS. Consulta la BD con psql para contar filas.
const { execFileSync } = require('child_process');
const BASE = process.argv[2] || 'http://127.0.0.1:8080/api';
const OUT = process.argv[3];
const PSQL = 'C:/Program Files/PostgreSQL/16/bin/psql.exe';
const sql = (q) => execFileSync(PSQL, ['-h', '127.0.0.1', '-p', '5433', '-U', 'ceosmos', '-d', 'ceosmos_dev', '-Atc', q]).toString().trim();
const N = 10;

async function json(metodo, ruta, token, body) {
  const r = await fetch(BASE + ruta, {
    method: metodo,
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    body: body && JSON.stringify(body),
  });
  const t = await r.text();
  return { status: r.status, body: t };
}
const conteo = (rs) => rs.reduce((m, r) => ((m[r.status] = (m[r.status] || 0) + 1), m), {});

(async () => {
  const login = await json('POST', '/auth/login', null, { email: process.env.P11_USER || 'p11_wb2@ceosmos.test', password: process.env.P11_PASS });
  const token = JSON.parse(login.body).token;
  if (!token) throw new Error('login: ' + login.status + ' ' + login.body);
  const uid = JSON.parse((await json('GET', '/users/me', token)).body).id;
  const salida = { fecha: new Date().toISOString(), usuario: uid, concurrencia: N, escenarios: [] };
  const tag = Date.now().toString(36);

  // C1: misma imagen en la biblioteca N veces a la vez (validación "ya existe" en la app, sin UNIQUE en BD)
  const url = `https://img.test/p11-${tag}.jpg`;
  let rs = await Promise.all(Array.from({ length: N }, () => json('POST', '/media', token, { type: 'IMAGE', url })));
  salida.escenarios.push({
    id: 'C1', operacion: `POST /media (misma url) x${N} simultáneas`, codigos: conteo(rs),
    filas_en_bd: +sql(`select count(*) from "MediaItem" where "userId"='${uid}' and url='${url}'`),
    esperado: 1,
  });

  // C2: mismo favorito N veces (upsert con índice UNIQUE userId+contentKey)
  const key = `p11:conc-${tag}`;
  rs = await Promise.all(Array.from({ length: N }, () => json('PUT', `/favorites/${encodeURIComponent(key)}`, token)));
  salida.escenarios.push({
    id: 'C2', operacion: `PUT /favorites/${key} x${N} simultáneas`, codigos: conteo(rs),
    filas_en_bd: +sql(`select count(*) from "Favorite" where "userId"='${uid}' and "contentKey"='${key}'`),
    esperado: 1, cuerpos500: rs.filter((r) => r.status >= 500).map((r) => r.body).slice(0, 1),
  });

  // C3: mismo dispositivo N veces (UNIQUE userId+type+address → P2002 → 409)
  const address = `10.9.${Math.floor(Math.random() * 200)}.1:5050`;
  rs = await Promise.all(Array.from({ length: N }, (_, i) => json('POST', '/devices', token, { name: `B${i}`, type: 'WEARABLE', transport: 'TCP', address })));
  salida.escenarios.push({
    id: 'C3', operacion: `POST /devices (misma dirección) x${N} simultáneas`, codigos: conteo(rs),
    filas_en_bd: +sql(`select count(*) from "LinkedDevice" where "userId"='${uid}' and address='${address}'`),
    esperado: 1,
  });

  // C4: N actualizaciones del mismo dispositivo (PATCH name) → última escritura gana
  const devId = sql(`select id from "LinkedDevice" where "userId"='${uid}' and address='${address}'`);
  rs = await Promise.all(Array.from({ length: N }, (_, i) => json('PATCH', `/devices/${devId}`, token, { name: `Nombre-${i}` })));
  salida.escenarios.push({
    id: 'C4', operacion: `PATCH /devices/:id (name) x${N} simultáneas`, codigos: conteo(rs),
    valor_final: sql(`select name from "LinkedDevice" where id='${devId}'`), esperado: 'un único valor de los enviados, sin error',
  });

  // Limpieza de los datos de prueba
  await json('DELETE', `/devices/${devId}`, token);
  await json('DELETE', `/favorites/${encodeURIComponent(key)}`, token);
  sql(`delete from "MediaItem" where "userId"='${uid}' and url='${url}'`);
  await json('POST', '/auth/logout', token);

  for (const e of salida.escenarios) console.log(JSON.stringify(e));
  if (OUT) require('fs').writeFileSync(OUT, JSON.stringify(salida, null, 2));
})();
