// Práctica 12 · Fase 2: muestrea CPU y memoria del proceso de la app en Android con adb
// mientras corre integration_test/p12_perfil_app_test.dart, y luego cruza las muestras
// con las fases que reporta la prueba.
//   node fase2_muestrear_app.js muestrear <id_adb> <muestras.json>     (Ctrl+C / archivo FIN para parar)
//   node fase2_muestrear_app.js resumir <muestras.json> <perfil_app.json> <salida.json>
// CPU: delta de utime+stime de /proc/<pid>/stat (ticks de 10 ms) por segundo real →
// % de UN núcleo (100 % = un núcleo completo). RAM: VmRSS de /proc/<pid>/status cada
// segundo y PSS total de `dumpsys meminfo` cada ~3 s.
const { execFile } = require('child_process');
const fs = require('fs');
const PKG = 'com.ceosmos.ceosmos_movil_integral';
const [modo, a1, a2, a3] = process.argv.slice(2);
const adb = (id, cmd) => new Promise((ok) => execFile('adb', ['-s', id, 'shell', cmd], { maxBuffer: 1 << 22 }, (e, so) => ok(e ? '' : so.toString())));
const r1 = (x) => Math.round(x * 10) / 10;

async function muestrear(id, out) {
  const muestras = [];
  let previo = null, n = 0;
  const fin = out + '.FIN';
  if (fs.existsSync(fin)) fs.unlinkSync(fin);
  const guardar = () => fs.writeFileSync(out, JSON.stringify(muestras));
  process.on('SIGINT', () => { guardar(); process.exit(0); });
  while (!fs.existsSync(fin)) {
    const t = Date.now();
    const pid = (await adb(id, `pidof ${PKG}`)).trim().split(/\s+/)[0];
    if (!pid) { previo = null; await new Promise((ok) => setTimeout(ok, 500)); continue; }
    const txt = await adb(id, `cat /proc/${pid}/stat /proc/${pid}/status`);
    const campos = txt.split(')')[1]?.trim().split(/\s+/) || [];
    const ticks = +campos[11] + +campos[12]; // utime + stime (campos 14 y 15 de stat)
    const rss = +(txt.match(/VmRSS:\s+(\d+)/) || [])[1] / 1024;
    const hilos = +(txt.match(/Threads:\s+(\d+)/) || [])[1];
    const m = { t, pid: +pid, rss_mb: r1(rss), hilos };
    if (previo && previo.pid === +pid) m.cpu_pct = r1(((ticks - previo.ticks) * 10 / (t - previo.t)) * 100);
    if (n++ % 3 === 0) {
      const mi = await adb(id, `dumpsys meminfo ${PKG}`);
      const total = mi.match(/TOTAL PSS:\s+(\d+)/) || mi.match(/TOTAL\s+(\d+)/);
      if (total) m.pss_mb = r1(+total[1] / 1024);
    }
    previo = { pid: +pid, ticks, t };
    muestras.push(m);
    if (n % 5 === 0) guardar();
    await new Promise((ok) => setTimeout(ok, Math.max(0, 1000 - (Date.now() - t))));
  }
  guardar();
}

function resumir(archMuestras, archPerfil, out) {
  const ms = JSON.parse(fs.readFileSync(archMuestras, 'utf8'));
  const perfil = JSON.parse(fs.readFileSync(archPerfil, 'utf8'));
  const fases = perfil.fases;
  const prom = (a) => (a.length ? r1(a.reduce((x, y) => x + y, 0) / a.length) : null);
  const max = (a) => (a.length ? r1(Math.max(...a)) : null);
  const porFase = fases.map((f) => {
    const m = ms.filter((x) => x.t >= f.inicio && x.t <= f.fin + 1000);
    const cpu = m.map((x) => x.cpu_pct).filter((x) => x !== undefined);
    const pss = m.map((x) => x.pss_mb).filter((x) => x !== undefined);
    return { fase: f.fase, duracion_s: r1((f.fin - f.inicio) / 1000), cpu_prom_pct: prom(cpu), cpu_max_pct: max(cpu),
      rss_max_mb: max(m.map((x) => x.rss_mb)), pss_max_mb: max(pss), max_retraso_hilo_ui_ms: r1(f.max_retraso_ms), bloqueos_sobre_50ms: f.bloqueos_sobre_50ms };
  });
  const ini = fases[0].inicio, fin = fases.at(-1).fin;
  const prueba = ms.filter((x) => x.t >= ini && x.t <= fin + 1000);
  const cpu = prueba.map((x) => x.cpu_pct).filter((x) => x !== undefined);
  const antesDe = ms.filter((x) => x.t < ini && x.pss_mb);
  const despues = ms.filter((x) => x.t > fin && x.pss_mb);
  const total = {
    cpu_prom_pct: prom(cpu), cpu_max_pct: max(cpu),
    ram_inicial_pss_mb: antesDe.at(-1)?.pss_mb ?? null, ram_max_pss_mb: max(ms.map((x) => x.pss_mb).filter(Boolean)),
    ram_final_pss_mb: despues.at(-1)?.pss_mb ?? ms.filter((x) => x.pss_mb).at(-1)?.pss_mb,
    rss_inicial_mb: ms.filter((x) => x.t < ini).at(-1)?.rss_mb ?? null, rss_max_mb: max(ms.map((x) => x.rss_mb)), rss_final_mb: ms.at(-1).rss_mb,
    muestras: ms.length,
  };
  const salida = { total, por_fase: porFase, datos_app: perfil.datos };
  fs.writeFileSync(out, JSON.stringify(salida, null, 2));
  console.log(JSON.stringify(total));
  console.table(porFase);
}

if (modo === 'muestrear') muestrear(a1, a2);
else if (modo === 'resumir') resumir(a1, a2, a3);
else console.log('uso: muestrear <id> <muestras.json> | resumir <muestras.json> <perfil.json> <salida.json>');
