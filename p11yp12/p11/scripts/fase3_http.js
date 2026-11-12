const crypto = require('crypto');
// Práctica 11 · Fase 3: White Box de endpoints de la API de CEOSMOS (NestJS) en el
// entorno LOCAL (PostgreSQL .devdb). Comprueba código HTTP, estructura JSON,
// cabeceras y que no se expongan secretos. Uso:
//   node fase3_http.js http://127.0.0.1:8080/api salida.json
// Credenciales por variables de entorno: P11_USER, P11_ADMIN, P11_PASS, P11_ADMIN_PASS.
const BASE = process.argv[2] || 'http://127.0.0.1:8080/api';
const OUT = process.argv[3];
const USER = process.env.P11_USER || 'p11_wb@ceosmos.test';
const PASS = process.env.P11_PASS;
const ADMIN = process.env.P11_ADMIN || 'admin@ceosmos.test';
const ADMIN_PASS = process.env.P11_ADMIN_PASS;
if (!PASS || !ADMIN_PASS) throw new Error('Define P11_PASS y P11_ADMIN_PASS');

const resultados = [];
const SENSIBLES = /"(password|passwordHash|hash|token|sessionToken|refreshToken|secret|code)"\s*:/i;

async function pedir(metodo, ruta, { token, body, raw, headers = {} } = {}) {
  const h = { Accept: 'application/json', ...headers };
  if (token) h.Authorization = `Bearer ${token}`;
  if (body !== undefined || raw !== undefined) h['Content-Type'] = 'application/json';
  const t0 = performance.now();
  const r = await fetch(BASE + ruta, { method: metodo, headers: h, body: raw ?? (body === undefined ? undefined : JSON.stringify(body)) });
  const texto = await r.text();
  const ms = performance.now() - t0;
  let json = null;
  try { json = texto ? JSON.parse(texto) : null; } catch { /* no JSON */ }
  return { status: r.status, ms, bytes: Buffer.byteLength(texto), texto, json, headers: r.headers };
}

function caso(id, endpoint, situacion, esperado, r, extra = {}) {
  const okCodigo = Array.isArray(esperado) ? esperado.includes(r.status) : r.status === esperado;
  const estructura = extra.estructura ? extra.estructura(r) : true;
  const sinSecretos = extra.permitirToken ? true : !SENSIBLES.test(r.texto);
  const errorUniforme = r.status >= 400 ? (r.json && 'statusCode' in r.json && 'message' in r.json && 'error' in r.json) : true;
  const sinTraza = !/at \w+ \(|node_modules|Prisma\w*Error|\.ts:\d+/.test(r.texto);
  const aprobado = okCodigo && estructura && sinSecretos && errorUniforme && sinTraza;
  resultados.push({
    id, endpoint, situacion, esperado, obtenido: r.status, ms: +r.ms.toFixed(1), bytes: r.bytes,
    estructura, sinSecretos, errorUniforme, sinTraza, aprobado, nota: extra.nota || '',
    cuerpo: r.texto.length > 220 ? r.texto.slice(0, 220) + '…' : r.texto,
  });
  console.log(`${aprobado ? 'OK  ' : 'FALLA'} ${id} ${endpoint} → ${r.status} (esperado ${esperado}) ${r.ms.toFixed(0)} ms ${extra.nota || ''}`);
}

(async () => {
  // ---- Autenticación -----------------------------------------------------
  let r = await pedir('POST', '/auth/login', { body: { email: USER, password: PASS } });
  const token = r.json?.token;
  caso('H01', 'POST /auth/login', 'Credenciales válidas', [200, 201], r, {
    permitirToken: true,
    estructura: (x) => typeof x.json?.token === 'string' && !('password' in x.json),
    nota: `Set-Cookie: ${(x => x ? x.replace(/=[^;]+/, '=<jwt>') : 'no')(r.headers.get('set-cookie'))}`,
  });
  caso('H02', 'POST /auth/login', 'Contraseña incorrecta', 401,
    await pedir('POST', '/auth/login', { body: { email: USER, password: 'Incorrecta#1' } }));
  caso('H03', 'POST /auth/login', 'JSON mal formado', 400,
    await pedir('POST', '/auth/login', { raw: '{"email": "a@b.c", "password": ' }));
  caso('H04', 'POST /auth/login', 'Falta password', 400,
    await pedir('POST', '/auth/login', { body: { email: USER } }));

  // ---- Usuario ------------------------------------------------------------
  caso('H05', 'GET /users/me', 'Sin token', 401, await pedir('GET', '/users/me'));
  caso('H06', 'GET /users/me', 'Token alterado', 401, await pedir('GET', '/users/me', { token: token.slice(0, -3) + 'abc' }));
  r = await pedir('GET', '/users/me', { token });
  caso('H07', 'GET /users/me', 'Token válido', 200, r, {
    estructura: (x) => ['id', 'email', 'username', 'role', 'preferences'].every((k) => k in x.json),
  });
  const cabeceras = {
    'x-powered-by': r.headers.get('x-powered-by'),
    'x-frame-options': r.headers.get('x-frame-options'),
    'x-content-type-options': r.headers.get('x-content-type-options'),
    'strict-transport-security': r.headers.get('strict-transport-security'),
    'content-type': r.headers.get('content-type'),
    'ratelimit-limit / x-ratelimit-limit': r.headers.get('x-ratelimit-limit') ?? r.headers.get('ratelimit-limit'),
  };
  caso('H08', 'GET /users/me/sessions', 'No expone el token de sesión', 200,
    await pedir('GET', '/users/me/sessions', { token }), {
      estructura: (x) => Array.isArray(x.json) && x.json.every((s) => !('token' in s) && 'id' in s),
    });

  // ---- Autorización (403 ≠ 401) ------------------------------------------
  caso('H09', 'GET /admin/users', 'USER autenticado sin rol ADMIN', 403, await pedir('GET', '/admin/users', { token }));
  caso('H10', 'GET /admin/users', 'Sin autenticar', 401, await pedir('GET', '/admin/users'));

  // ---- Dispositivos (escritura) -------------------------------------------
  const addr = `10.0.2.2:${5000 + Math.floor(Math.random() * 4000)}`;
  r = await pedir('POST', '/devices', { token, body: { name: 'Banda P11', type: 'WEARABLE', transport: 'TCP', address: addr } });
  const devId = r.json?.id;
  caso('H11', 'POST /devices', 'Registro válido', 201, r, {
    estructura: (x) => ['id', 'userId', 'name', 'type', 'transport', 'address', 'lastSeenAt', 'createdAt'].every((k) => k in x.json),
  });
  caso('H12', 'POST /devices', 'Misma dirección (UNIQUE)', 409,
    await pedir('POST', '/devices', { token, body: { name: 'Otra', type: 'WEARABLE', transport: 'TCP', address: addr } }));
  caso('H13', 'POST /devices', 'Dirección inválida', 400,
    await pedir('POST', '/devices', { token, body: { name: 'X', type: 'WEARABLE', transport: 'TCP', address: '10.0.2.2' } }));
  caso('H14', 'POST /devices', 'Campo no permitido (asignación masiva userId)', 400,
    await pedir('POST', '/devices', { token, body: { name: 'X', type: 'WEARABLE', transport: 'TCP', address: '1.1.1.1:80', userId: 'otro' } }));
  caso('H15', 'PATCH /devices/:id', 'UUID inexistente', 404,
    await pedir('PATCH', '/devices/00000000-0000-4000-8000-000000000000', { token, body: { seen: true } }));
  caso('H16', 'PATCH /devices/:id', 'Id que no es UUID', 400,
    await pedir('PATCH', '/devices/123', { token, body: { seen: true } }));
  caso('H17', 'PATCH /devices/:id', 'Actualización válida (seen)', 200,
    await pedir('PATCH', `/devices/${devId}`, { token, body: { seen: true } }), {
      estructura: (x) => x.json?.lastSeenAt !== null,
    });
  r = await pedir('DELETE', `/devices/${devId}`, { token });
  caso('H18', 'DELETE /devices/:id', 'Eliminación sin cuerpo', 204, r, { estructura: (x) => x.bytes === 0 });
  caso('H19', 'DELETE /devices/:id', 'Eliminar de nuevo (ya no existe)', 404, await pedir('DELETE', `/devices/${devId}`, { token }));

  // ---- Sesiones de enfoque -------------------------------------------------
  const ahora = Date.now();
  const sesion = {
    contentKey: 'orbit', mode: 'FOCUS', startedAt: new Date(ahora - 600_000).toISOString(),
    endedAt: new Date(ahora - 300_000).toISOString(), durationSeconds: 300, targetMinutes: 5, completed: true,
    metadata: { source: 'p11-fase3' },
  };
  caso('H20', 'POST /focus-sessions', 'Registro válido', 201, await pedir('POST', '/focus-sessions', { token, body: sesion }), {
    estructura: (x) => typeof x.json?.id === 'string' && x.json.metadata?.source === 'p11-fase3',
  });
  caso('H21', 'POST /focus-sessions', 'Validación semántica: endedAt < startedAt', [422, 400],
    await pedir('POST', '/focus-sessions', { token, body: { ...sesion, endedAt: new Date(ahora - 700_000).toISOString() } }),
    { nota: 'La API usa 400 para validación semántica (no 422)' });
  caso('H22', 'POST /focus-sessions', 'Duración > objetivo', [422, 400],
    await pedir('POST', '/focus-sessions', { token, body: { ...sesion, durationSeconds: 301 } }));
  caso('H23', 'GET /focus-sessions', 'limit fuera de rango (101)', 400,
    await pedir('GET', '/focus-sessions?limit=101', { token }));
  caso('H24', 'GET /focus-sessions', 'Consulta exitosa', 200,
    await pedir('GET', '/focus-sessions?limit=5', { token }), { estructura: (x) => Array.isArray(x.json) && x.json.length <= 5 });

  // ---- Correcciones P11-D01 / D04 / D05 ----
  const clientId = crypto.randomUUID();
  const conId = { ...sesion, clientId, startedAt: new Date(ahora - 900_000).toISOString(), endedAt: new Date(ahora - 800_000).toISOString(), durationSeconds: 100 };
  const p1 = await pedir('POST', '/focus-sessions', { token, body: conId });
  caso('H35', 'POST /focus-sessions', 'P11-D01: primer envío con clientId', 201, p1, { estructura: (x) => x.json?.clientId === clientId });
  const p2 = await pedir('POST', '/focus-sessions', { token, body: conId });
  caso('H36', 'POST /focus-sessions', 'P11-D01: reintento con el mismo clientId → misma sesión, sin duplicar', 201, p2,
    { estructura: (x) => x.json?.id === p1.json?.id, nota: `id1=${p1.json?.id} id2=${p2.json?.id}` });
  caso('H37', 'POST /focus-sessions', 'P11-D04: metadata de más de 4 KB', 400,
    await pedir('POST', '/focus-sessions', { token, body: { ...sesion, metadata: { muestras: Array(3000).fill(72) } } }));
  // Regresión detectada en el S24: metadata válida para la API (≤ 4 KB compactos) que
  // la BD rechazaba por medir metadata::text (con espacios) → 500.
  const muestras = []; while (JSON.stringify({ muestras: [...muestras, 1] }).length <= 4096) muestras.push(1);
  caso('H40', 'POST /focus-sessions', `Regresión: metadata de ${JSON.stringify({ muestras }).length} B compactos (límite exacto)`, 201,
    await pedir('POST', '/focus-sessions', { token, body: { ...sesion, startedAt: new Date(ahora - 1_200_000).toISOString(), endedAt: new Date(ahora - 1_000_000).toISOString(), durationSeconds: 200, metadata: { muestras } } }));
  caso('H38', 'POST /focus-sessions', 'P11-D05: cuerpo de 300 KB → 413 con formato uniforme', 413,
    await pedir('POST', '/focus-sessions', { token, raw: JSON.stringify({ x: 'a'.repeat(300_000) }) }));
  caso('H39', 'GET /users/me', 'P11-D05: token mal formado no expone el mensaje de la librería', 401,
    await pedir('GET', '/users/me', { token: 'no-es-un-jwt' }), { estructura: (x) => x.json?.message === 'Unauthorized' });

  // ---- Favoritos / biblioteca ----------------------------------------------
  caso('H25', 'PUT /favorites/:key', 'Clave con caracteres de inyección', 400,
    await pedir('PUT', `/favorites/${encodeURIComponent("orbit' OR '1'='1")}`, { token }));
  const yt = `p11${Math.random().toString(36).slice(2, 9)}`;
  r = await pedir('POST', '/media', { token, body: { type: 'YOUTUBE', externalId: yt, title: 'P11' } });
  const mediaId = r.json?.id;
  caso('H26', 'POST /media', 'Registro válido', 201, r);
  caso('H27', 'POST /media', 'Duplicado (conflicto)', 409,
    await pedir('POST', '/media', { token, body: { type: 'YOUTUBE', externalId: yt } }),
    { nota: 'Corrección P11-D05 (antes 400)' });
  caso('H28', 'DELETE /media/:id', 'Id inexistente', 404, await pedir('DELETE', '/media/no-existe', { token }));
  caso('H29', 'DELETE /media/:id', 'Eliminación sin cuerpo (corrección P11-D05)', 204, await pedir('DELETE', `/media/${mediaId}`, { token }),
    { estructura: (x) => x.bytes === 0 });

  // ---- ADMIN: error inesperado del servidor ---------------------------------
  const a = await pedir('POST', '/auth/login', { body: { email: ADMIN, password: ADMIN_PASS } });
  const tAdmin = a.json?.token;
  caso('H30', 'PATCH /admin/users/:id/status', 'ADMIN sobre usuario inexistente', 404,
    await pedir('PATCH', '/admin/users/00000000-0000-4000-8000-000000000000/status', { token: tAdmin, body: { active: false } }),
    { nota: 'Si responde 500 es un error no controlado' });
  caso('H31', 'PATCH /admin/users/:id', 'ADMIN con id que no es UUID', [400, 404],
    await pedir('PATCH', '/admin/users/abc', { token: tAdmin, body: { username: 'zz_p11' } }));
  caso('H32', 'GET /admin/users', 'ADMIN: lista sin contraseñas', 200, await pedir('GET', '/admin/users', { token: tAdmin }), {
    estructura: (x) => Array.isArray(x.json) || Array.isArray(x.json?.users) || Array.isArray(x.json?.data),
  });
  await pedir('POST', '/auth/logout', { token: tAdmin });

  // ---- Sesión revocada -----------------------------------------------------
  await pedir('POST', '/auth/logout', { token });
  caso('H33', 'GET /users/me', 'Token tras logout (revocado)', 401, await pedir('GET', '/users/me', { token }));

  // ---- Límite de intentos (429) --------------------------------------------
  let ultimo;
  for (let i = 0; i < 12; i++) ultimo = await pedir('POST', '/auth/login', { body: { email: 'nadie@ceosmos.test', password: 'Mala#1234' } });
  caso('H34', 'POST /auth/login', '12 intentos en < 1 min (limitador 10/min)', 429, ultimo);

  const resumen = {
    fecha: new Date().toISOString(), base: BASE, cabeceras,
    total: resultados.length, aprobados: resultados.filter((x) => x.aprobado).length, resultados,
  };
  console.log(`\nAprobados ${resumen.aprobados}/${resumen.total}`);
  console.log('Cabeceras de seguridad:', cabeceras);
  if (OUT) require('fs').writeFileSync(OUT, JSON.stringify(resumen, null, 2));
})();
