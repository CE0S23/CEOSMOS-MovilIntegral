// Práctica 12 · Inicia sesión con las cuentas locales p12_vu01..NN y guarda los JWT
// en un archivo FUERA del repositorio (los reutilizan las pruebas de estrés antes y
// después). /auth limita a 10 inicios de sesión por minuto e IP: ante un 429 espera 61 s.
//   P12_PASS=... node tokens_carga.js http://127.0.0.1:8080/api 50 <archivo_tokens.json>
const BASE = process.argv[2] || 'http://127.0.0.1:8080/api';
const N = +(process.argv[3] || 50);
const OUT = process.argv[4];
if (!OUT || !process.env.P12_PASS) throw new Error('uso: P12_PASS=... node tokens_carga.js <base> <n> <salida>');
const fs = require('fs');
const previos = fs.existsSync(OUT) ? JSON.parse(fs.readFileSync(OUT, 'utf8')) : {};

(async () => {
  const tokens = { ...previos };
  for (let i = 1; i <= N; i++) {
    const email = `p12_vu${String(i).padStart(2, '0')}@ceosmos.test`;
    if (tokens[email]) {
      const r = await fetch(BASE + '/users/me', { headers: { Authorization: `Bearer ${tokens[email]}` } });
      if (r.status === 200) continue; // el token sigue vigente
    }
    for (;;) {
      const r = await fetch(BASE + '/auth/login', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password: process.env.P12_PASS }),
      });
      if (r.status === 429) { console.log(`${email}: 429, espera 61 s`); await new Promise((ok) => setTimeout(ok, 61_000)); continue; }
      const j = await r.json();
      if (!j.token) throw new Error(`${email}: ${r.status} ${JSON.stringify(j)}`);
      tokens[email] = j.token;
      console.log(`${email}: ok`);
      break;
    }
    fs.writeFileSync(OUT, JSON.stringify(tokens, null, 1));
  }
  console.log('tokens vigentes:', Object.keys(tokens).length);
})();
