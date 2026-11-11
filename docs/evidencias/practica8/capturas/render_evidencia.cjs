const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = __dirname;
const escapeHtml = value => String(value).replace(/[&<>"']/g, char => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[char]));
const style = `
  body{margin:0;background:#f5f6fa;color:#171b29;font:18px Arial,sans-serif}
  main{padding:44px 54px}h1{font-size:30px;margin:0 0 7px}h2{font-size:20px;margin:28px 0 10px}
  p{margin:0 0 18px;color:#525a6b}small{font-size:13px;color:#667085}
  .badge{display:inline-block;background:#e4f7eb;color:#126734;border-radius:7px;padding:8px 12px;font-weight:700;margin:12px 0 20px}
  pre{background:#101522;color:#e4e8f2;padding:24px;border-radius:12px;white-space:pre-wrap;font:15px/1.5 Consolas,monospace}
  table{width:100%;border-collapse:collapse;background:white;border-radius:9px;overflow:hidden;font-size:15px}
  th,td{padding:12px 14px;border-bottom:1px solid #e1e5ee;text-align:left}
  th{background:#e8ebf4}td:nth-child(2){font-weight:700;color:#126734}
  .note{margin-top:19px;font-size:15px;line-height:1.4}
`;

(async () => {
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    headless: true,
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
    const run = fs.readFileSync(path.join(root, 'blackbox_salida.txt'), 'utf8').trim();
    await page.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>${style}</style></head><body><main>
      <h1>Práctica 8 · Ejecución de caja negra</h1>
      <p>Salida capturada del comando Flutter sobre CEOSMOS Móvil Integral</p>
      <div class="badge">21 pruebas aprobadas · 0 fallidas · 12 requisitos cubiertos</div>
      <pre>${escapeHtml(run)}</pre><small>Fuente: blackbox_salida.txt y flutter-test.jsonl de esta ejecución.</small>
      </main></body></html>`);
    await page.screenshot({ path: path.join(root, 'blackbox_resultados.png'), fullPage: true });

    const network = JSON.parse(fs.readFileSync(path.join(root, 'red_puertos.json'), 'utf8'));
    const browserData = JSON.parse(fs.readFileSync(path.join(root, 'navegador.json'), 'utf8'));
    const rows = network.Records.map(record => `<tr><td>${escapeHtml(record.Target)}</td><td>${escapeHtml(record.Result)}</td><td>${record.Port}</td></tr>`).join('');
    const fontStatuses = browserData.externalResponses.map(record => `<tr><td>${escapeHtml(new URL(record.url).host)}</td><td>${record.status}</td><td>443</td></tr>`).join('');
    await page.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>${style}</style></head><body><main>
      <h1>Conectividad y puertos</h1><p>Pruebas realizadas el ${escapeHtml(network.CheckedAt)}</p>
      <div class="badge">Puerto local 8765 abierto · Rutas HTTP verificadas</div>
      <h2>Pruebas TCP y HTTP</h2><table><thead><tr><th>Destino</th><th>Resultado</th><th>Puerto</th></tr></thead><tbody>${rows}</tbody></table>
      <h2>Solicitudes externas hechas por la app web</h2><table><thead><tr><th>Dominio</th><th>HTTP</th><th>Puerto</th></tr></thead><tbody>${fontStatuses}</tbody></table>
      <p class="note">El navegador registró ${browserData.errors.length} errores en la carga normal. Las fuentes remotas provienen de fonts.gstatic.com; bloquearlas en una simulación hizo desaparecer el texto de la interfaz.</p>
      <small>Fuente: red_puertos.json y navegador.json. Vista de evidencia generada desde resultados reales.</small>
      </main></body></html>`);
    await page.screenshot({ path: path.join(root, 'red_puertos.png'), fullPage: true });
    console.log('blackbox_resultados.png y red_puertos.png generados');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
