// Práctica 12 · Fase 5: proxy de inyección de fallos entre la app y la API LOCAL.
//   app (emulador) → http://10.0.2.2:8081/api → este proxy → http://127.0.0.1:8080/api
// Panel de control (lo llama la propia prueba desde el emulador):
//   GET http://10.0.2.2:8082/modo?m=<modo>[&ms=N][&ruta=/focus-sessions][&metodo=POST][&veces=N]
//   GET http://10.0.2.2:8082/avion?s=N     → modo avión REAL en el emulador durante N s (adb)
//   GET http://10.0.2.2:8082/registro      → peticiones vistas (para medir reintentos)
//   GET http://10.0.2.2:8082/marca         → hora del equipo (evita el desfase de reloj del emulador)
// Modos: normal | colgar | http500 | http400 | http401 | http403 | lento (ms) | perder_respuesta | cortar
//   node fase5_proxy_fallos.js <archivo_log> [id_adb]
const http = require('http');
const { execFile } = require('child_process');
const fs = require('fs');
const LOG = process.argv[2];
const ADB_ID = process.argv[3] || 'emulator-5554';
const DESTINO = { host: '127.0.0.1', port: 8080 };
let modo = { m: 'normal' };
const registro = [];
const ahora = () => new Date().toISOString();
const escribir = (l) => { console.log(l); if (LOG) fs.appendFileSync(LOG, l + '\n'); };

function aplica(req) {
  if (modo.m === 'normal') return false;
  if (modo.ruta && !req.url.includes(modo.ruta)) return false;
  if (modo.metodo && req.method !== modo.metodo) return false;
  if (modo.veces !== undefined) {
    if (modo.veces <= 0) return false;
    modo.veces--;
  }
  return true;
}

function reenviar(req, res, cuerpo, alResponder) {
  const p = http.request({ ...DESTINO, method: req.method, path: req.url, headers: { ...req.headers, host: '127.0.0.1:8080' } }, (r) => {
    const partes = [];
    r.on('data', (d) => partes.push(d));
    r.on('end', () => alResponder(r, Buffer.concat(partes)));
  });
  p.on('error', (e) => { res.writeHead(502); res.end(JSON.stringify({ statusCode: 502, message: e.message, error: 'Bad Gateway' })); });
  p.end(cuerpo);
}

const errorJson = (res, code, message, error) => {
  const b = JSON.stringify({ statusCode: code, message, error });
  res.writeHead(code, { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(b) });
  res.end(b);
};

http.createServer((req, res) => {
  const partes = [];
  req.on('data', (d) => partes.push(d));
  req.on('end', () => {
    const cuerpo = Buffer.concat(partes);
    const fallo = aplica(req) ? modo.m : 'normal';
    let clientId = null;
    try { clientId = JSON.parse(cuerpo.toString() || '{}').clientId ?? null; } catch { /* no JSON */ }
    const ev = { t: ahora(), ms: Date.now(), metodo: req.method, ruta: req.url, fallo, clientId };
    registro.push(ev);
    escribir(`PROXY ${ev.t} ${req.method} ${req.url} fallo=${fallo}${clientId ? ' clientId=' + clientId : ''}`);
    switch (fallo) {
      case 'colgar': return; // nunca responde: el cliente debe cortar por timeout
      case 'cortar': return req.socket.destroy(); // conexión reiniciada antes de llegar al servidor
      case 'http500': return errorJson(res, 500, 'Internal server error', 'Internal Server Error');
      case 'http401': return errorJson(res, 401, 'Unauthorized', 'Unauthorized');
      case 'http403': return errorJson(res, 403, 'Forbidden resource', 'Forbidden');
      case 'http400': return errorJson(res, 400, ['endedAt no puede estar en el futuro'], 'Bad Request'); // rechazo permanente
      case 'perder_respuesta':
        // El servidor SÍ procesa la operación, pero la respuesta nunca llega al dispositivo.
        return reenviar(req, res, cuerpo, (r) => { escribir(`PROXY ${ahora()} servidor respondió ${r.statusCode}; se descarta la respuesta`); req.socket.destroy(); });
      case 'lento':
        return setTimeout(() => reenviar(req, res, cuerpo, (r, b) => { res.writeHead(r.statusCode, r.headers); res.end(b); }), modo.ms || 5000);
      default:
        return reenviar(req, res, cuerpo, (r, b) => { res.writeHead(r.statusCode, r.headers); res.end(b); });
    }
  });
}).listen(8081, '0.0.0.0', () => escribir(`PROXY ${ahora()} escuchando en 8081 → 8080`));

const adb = (args) => new Promise((ok) => execFile('adb', ['-s', ADB_ID, ...args], (e, so, se) => ok((so || '') + (se || '') + (e ? ' ERR ' + e.message : ''))));

http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x');
  if (u.pathname === '/modo') {
    modo = { m: u.searchParams.get('m') || 'normal' };
    for (const k of ['ruta', 'metodo']) if (u.searchParams.get(k)) modo[k] = u.searchParams.get(k);
    if (u.searchParams.get('ms')) modo.ms = +u.searchParams.get('ms');
    if (u.searchParams.get('veces')) modo.veces = +u.searchParams.get('veces');
    escribir(`CONTROL ${ahora()} modo=${JSON.stringify(modo)}`);
    return res.end(JSON.stringify(modo));
  }
  if (u.pathname === '/avion') {
    const s = +(u.searchParams.get('s') || 8);
    const tras = +(u.searchParams.get('tras') || 0); // retraso antes de cortar (para cortar A MITAD de una petición)
    res.end(JSON.stringify({ avion: true, s, tras, desde: Date.now() }));
    await new Promise((ok) => setTimeout(ok, tras));
    const salida = (await adb(['shell', 'cmd', 'connectivity', 'airplane-mode', 'enable'])).trim();
    registro.push({ t: ahora(), ms: Date.now(), evento: 'avion_on' });
    escribir(`CONTROL ${ahora()} modo avión ON (${s} s) ${salida}`);
    setTimeout(async () => {
      const o = (await adb(['shell', 'cmd', 'connectivity', 'airplane-mode', 'disable'])).trim();
      registro.push({ t: ahora(), ms: Date.now(), evento: 'avion_off' });
      escribir(`CONTROL ${ahora()} modo avión OFF ${o}`);
    }, s * 1000);
    return;
  }
  if (u.pathname === '/marca') return res.end(JSON.stringify({ ms: Date.now() })); // reloj del equipo
  if (u.pathname === '/registro') {
    const desde = +(u.searchParams.get('desde') || 0);
    return res.end(JSON.stringify(registro.filter((r) => r.ms >= desde)));
  }
  res.writeHead(404); res.end();
}).listen(8082, '0.0.0.0', () => escribir(`CONTROL ${ahora()} panel en 8082`));
