#!/usr/bin/env node
/*
 * HERRAMIENTA DE PRUEBA (blindaje, red mínima) — no forma parte de la app.
 *
 * Proxy TCP que degrada la red entre curl (o la app) y un servidor real:
 *   --lat <ms>    retardo añadido en CADA sentido (RTT añadido = 2 × lat)
 *   --kbps <n>    ancho de banda máximo por sentido
 *   --perdida <p> fracción 0..1 de fragmentos que llegan tarde un RTO (1 s),
 *                 como una retransmisión TCP tras perder un paquete (emulado)
 *   --corte <s>   corta la conexión cada <s> segundos (cortes intermitentes)
 * El cifrado TLS pasa intacto de punta a punta (el proxy no lo descifra).
 *
 * Uso: node scripts/red_degradada.js <puertoLocal> <host> <puerto> [opciones]
 *      curl --connect-to ceosmos-api.vercel.app:443:127.0.0.1:<puertoLocal> https://ceosmos-api.vercel.app/api/health
 */
const net = require('node:net');

const [puerto, host, puertoRemoto, ...resto] = process.argv.slice(2);
const op = { lat: 0, kbps: 0, perdida: 0, corte: 0 };
for (let i = 0; i < resto.length; i += 2) op[resto[i].replace(/^--/, '')] = Number(resto[i + 1]);
const RTO_MS = 1000;
const TROZO = 512; // bytes por fragmento

function tubo(origen, destino) {
  // Cola con reloj propio: respeta orden, retardo, ancho de banda y «pérdidas».
  let libre = Date.now();
  origen.on('data', (datos) => {
    for (let i = 0; i < datos.length; i += TROZO) {
      const trozo = datos.subarray(i, i + TROZO);
      const transmision = op.kbps > 0 ? (trozo.length * 8) / op.kbps : 0; // ms
      const perdido = Math.random() < op.perdida ? RTO_MS : 0;
      libre = Math.max(libre, Date.now()) + transmision + perdido;
      const entrega = libre + op.lat;
      setTimeout(() => destino.writable && destino.write(trozo), Math.max(0, entrega - Date.now()));
    }
  });
  origen.on('end', () => setTimeout(() => destino.end(), Math.max(0, libre + op.lat - Date.now())));
  origen.on('error', () => destino.destroy());
}

net
  .createServer((cliente) => {
    const servidor = net.connect(Number(puertoRemoto), host);
    // El saludo TCP también paga la latencia: se retrasa la conexión 2 × lat.
    cliente.pause();
    setTimeout(() => cliente.resume(), 2 * op.lat);
    tubo(cliente, servidor);
    tubo(servidor, cliente);
    if (op.corte > 0) {
      const t = setTimeout(() => { cliente.destroy(); servidor.destroy(); }, op.corte * 1000);
      cliente.on('close', () => clearTimeout(t));
    }
  })
  .listen(Number(puerto), '127.0.0.1', () =>
    console.log(`red degradada ${puerto} → ${host}:${puertoRemoto} ${JSON.stringify(op)}`),
  );
