// Práctica 12 · Profiling de CPU de la API (hilo de JavaScript de Node) sin detenerla.
//   node -r perfil_cpu_preload.js dist/main.js
// Cada vez que aparece el archivo P12_PERFIL_DISPARO inicia el profiler del inspector,
// lo detiene a los P12_PERFIL_S segundos y guarda P12_PERFIL_SALIDA (.cpuprofile; se
// abre en Chrome DevTools › Performance o en https://www.speedscope.app). Si el archivo
// de disparo contiene una ruta, el perfil se guarda en esa ruta.
const inspector = require('inspector');
const fs = require('fs');
const disparo = process.env.P12_PERFIL_DISPARO;
const salidaPorOmision = process.env.P12_PERFIL_SALIDA;
const segundos = +(process.env.P12_PERFIL_S || 20);
if (disparo && salidaPorOmision) {
  const s = new inspector.Session();
  s.connect();
  let ocupado = false;
  const vigilar = setInterval(() => {
    if (ocupado || !fs.existsSync(disparo)) return;
    ocupado = true;
    const destino = fs.readFileSync(disparo, 'utf8').trim() || salidaPorOmision;
    fs.unlinkSync(disparo);
    s.post('Profiler.enable', () => s.post('Profiler.setSamplingInterval', { interval: 200 }, () => s.post('Profiler.start', () => {
      console.log(`[perfil] CPU profiler iniciado (${segundos} s)`);
      setTimeout(() => s.post('Profiler.stop', (err, { profile }) => {
        try {
          fs.writeFileSync(destino, JSON.stringify(profile));
          console.log(`[perfil] guardado en ${destino}`);
        } catch (e) {
          console.error(`[perfil] no se pudo guardar ${destino}: ${e.message}`); // nunca tumba la API
        }
        ocupado = false;
      }), segundos * 1000);
    })));
  }, 250);
  vigilar.unref();
}
