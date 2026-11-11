#!/usr/bin/env node
/*
 * HERRAMIENTA DE PRUEBA — no forma parte de la app.
 *
 * Servidor TCP que habla el protocolo de CEOSMOS Band para probar la conexión
 * del wearable cuando no hay hardware físico. La app se conecta como cliente:
 *   - recibe "CEOSMOS HELLO 1\n" al conectarse,
 *   - envía una línea JSON por lectura: {"hr":<bpm>,"steps":<pasos>}\n
 *
 * Los valores que envía son de prueba (no provienen de un sensor). Con la banda
 * real, la app recibe exactamente el mismo formato.
 *
 * Uso:  node scripts/banda_tcp_prueba.js [puerto=5050]
 * Desde el emulador Android la dirección del equipo es 10.0.2.2:<puerto>.
 */
const net = require('node:net');

const port = Number(process.argv[2] || 5050);

const server = net.createServer((socket) => {
  const peer = `${socket.remoteAddress}:${socket.remotePort}`;
  console.log(`[banda] cliente conectado ${peer}`);
  let steps = 0;
  let t = 0;
  socket.setEncoding('utf8');
  socket.on('data', (d) => console.log(`[banda] recibido: ${String(d).trim()}`));
  const timer = setInterval(() => {
    t += 1;
    steps += 2 + (t % 3);
    const hr = Math.round(72 + 6 * Math.sin(t / 4)); // patrón de prueba
    socket.write(`${JSON.stringify({ hr, steps })}\n`);
  }, 1000);
  socket.on('close', () => {
    clearInterval(timer);
    console.log(`[banda] cliente desconectado ${peer}`);
  });
  socket.on('error', () => clearInterval(timer));
});

server.listen(port, '0.0.0.0', () => console.log(`[banda] escuchando en TCP ${port}`));
