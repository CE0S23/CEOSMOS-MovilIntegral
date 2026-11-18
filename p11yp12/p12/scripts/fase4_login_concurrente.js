// Práctica 12 · Fase 4 (escrituras simultáneas sobre un MISMO registro, a través de la API):
// N intentos de inicio de sesión con contraseña incorrecta, a la vez, sobre la misma cuenta
// LOCAL p12_lock@ceosmos.test. La regla de negocio es bloquear la cuenta al 5.º fallo.
//   node fase4_login_concurrente.js http://127.0.0.1:8080/api <salida.json> [N=10]
// /auth admite 10 peticiones por minuto e IP, por eso N ≤ 10.
const { execFileSync } = require('child_process');
const fs = require('fs');
const [BASE = 'http://127.0.0.1:8080/api', OUT, Ntxt = '10'] = process.argv.slice(2);
const N = +Ntxt;
const PSQL = 'C:/Program Files/PostgreSQL/16/bin/psql.exe';
const sql = (q) => execFileSync(PSQL, ['-h', '127.0.0.1', '-p', '5433', '-U', 'ceosmos', '-d', 'ceosmos_dev', '-AtF', '|', '-c', q]).toString().trim();
const EMAIL = 'p12_lock@ceosmos.test';

(async () => {
  // Cuenta de prueba con la misma contraseña (hash) de p12_vu01 y el contador a cero.
  sql(`insert into "User"(id,email,username,"passwordHash","emailVerified",role,active,"createdAt","updatedAt")
       select 'p12-lock', '${EMAIL}', 'p12_lock', "passwordHash", true, 'USER', true, now(), now() from "User" where email='p12_vu01@ceosmos.test'
       on conflict (id) do update set "failedLoginAttempts" = 0, "lockedUntil" = null`);
  const t0 = performance.now();
  const res = await Promise.all(Array.from({ length: N }, async (_, i) => {
    const r = await fetch(BASE + '/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: EMAIL, password: `Incorrecta#${i}x` }) });
    const j = await r.json().catch(() => ({}));
    return { intento: i + 1, status: r.status, mensaje: Array.isArray(j.message) ? j.message.join('; ') : j.message, ms: Math.round(performance.now() - t0) };
  }));
  const [fallidos, bloqueo] = sql(`select "failedLoginAttempts", coalesce("lockedUntil"::text,'') from "User" where id='p12-lock'`).split('|');
  const bloqueada = !!bloqueo;
  const salida = {
    fecha: new Date().toISOString(), intentos_simultaneos: N, respuestas: res,
    mensajes: res.reduce((m, r) => ((m[r.mensaje] = (m[r.mensaje] || 0) + 1), m), {}),
    bd_failedLoginAttempts: +fallidos, bd_lockedUntil: bloqueo || null,
    cuenta_bloqueada: bloqueada,
    esperado: `con ${N} fallos la cuenta debe quedar bloqueada (regla: 5 fallos)`,
  };
  console.log(JSON.stringify(salida, null, 2));
  if (OUT) fs.writeFileSync(OUT, JSON.stringify(salida, null, 2));
  // Deja la cuenta como estaba (sin bloqueo) para repetir la prueba.
  sql(`update "User" set "failedLoginAttempts" = 0, "lockedUntil" = null where id='p12-lock'`);
})();
