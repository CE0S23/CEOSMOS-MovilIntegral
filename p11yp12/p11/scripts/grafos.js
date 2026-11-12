// Práctica 11 · Grafos de flujo de control (CFG) de los métodos críticos.
// Escribe un .mmd y un .html por grafo y los convierte a PNG con Chrome sin interfaz.
//   node grafos.js <carpeta_salida>
const fs = require('fs');
const path = require('path');
// Captura con puppeteer-core (ruta en P11_TOOLS) usando el Chrome instalado.
const puppeteer = require(path.join(process.env.P11_TOOLS || '.', 'node_modules', 'puppeteer-core'));
const out = path.resolve(process.argv[2] || 'grafos');
fs.mkdirSync(out, { recursive: true });
const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';

const grafos = {
  'cfg_parse': `flowchart TD
  N1["N1 · l.17-18<br/>hr = json['hr']; steps = json['steps']"] --> C1{"C1 · l.19<br/>hr is! num"}
  C1 -- V --> R0["R0 · l.19<br/>return null"]
  C1 -- F --> C2{"C2 · l.19<br/>hr &lt; 30"}
  C2 -- V --> R0
  C2 -- F --> C3{"C3 · l.19<br/>hr &gt; 230"}
  C3 -- V --> R0
  C3 -- F --> C4{"C4 · l.20<br/>steps != null"}
  C4 -- F --> N5["N5 · l.21-25<br/>return WearableLectura(hr.round(), steps?.round())"]
  C4 -- V --> C5{"C5 · l.20<br/>steps is! num"}
  C5 -- V --> R1["R1 · l.20<br/>return null"]
  C5 -- F --> C6{"C6 · l.20<br/>steps &lt; 0"}
  C6 -- V --> R1
  C6 -- F --> N5
  R0 --> FIN(("fin"))
  R1 --> FIN
  N5 --> FIN`,
  'cfg_resumen_sesion': `flowchart TD
  A["A · l.49<br/>m = muestras"] --> C1{"C1 · l.50<br/>m.isEmpty"}
  C1 -- V --> R["R · l.50<br/>return {}"]
  C1 -- F --> C2{"C2 · l.50<br/>deviceId == null"}
  C2 -- V --> R
  C2 -- F --> B["B · l.51<br/>promedio = suma / n"]
  B --> MIN{"C3 · l.58 reduce<br/>a &lt; b"}
  MIN -- V --> MA["conserva a"]
  MIN -- F --> MB["conserva b"]
  MA --> MAX{"C4 · l.59 reduce<br/>a &gt; b"}
  MB --> MAX
  MAX -- V --> XA["conserva a"]
  MAX -- F --> XB["conserva b"]
  XA --> C5{"C5 · l.60<br/>ultima?.steps != null"}
  XB --> C5
  C5 -- V --> S["agrega lastSteps"]
  C5 -- F --> RET["RET · l.52-62<br/>return {'wearable': {...}}"]
  S --> RET
  R --> FIN(("fin"))
  RET --> FIN`,
  'cfg_send': `flowchart TD
  N1["N1 · l.48-50<br/>uri, Request, Accept: json"] --> D1{"D1 · l.51<br/>token != null"}
  D1 -- V --> N2["N2 · Authorization: Bearer"]
  D1 -- F --> D2{"D2 · l.52<br/>body != null"}
  N2 --> D2
  D2 -- V --> N3["N3 · l.53-54<br/>Content-Type + jsonEncode"]
  D2 -- F --> T{"T · l.57-60<br/>send().timeout()"}
  N3 --> T
  T -- TimeoutException --> E1["E1 · l.62<br/>throw ApiException(tiempo)"]
  T -- ClientException --> E2["E2 · l.67<br/>throw ApiException(sin conexión)"]
  T -- respuesta --> N4["N4 · l.72<br/>decoded = _decode(body)"]
  N4 --> C3a{"C3a · l.73<br/>status &gt;= 200"}
  C3a -- V --> C3b{"C3b · l.73<br/>status &lt; 300"}
  C3b -- V --> RET["RET · return decoded"]
  C3a -- F --> C4a{"C4a · l.74<br/>status == 401"}
  C3b -- F --> C4a
  C4a -- V --> C4b{"C4b · l.74<br/>token != null"}
  C4b -- V --> N5["N5 · onUnauthorized()"]
  C4b -- F --> THR["THR · l.75<br/>throw ApiException(traducirError)"]
  C4a -- F --> THR
  N5 --> THR
  E1 --> FIN(("fin"))
  E2 --> FIN
  RET --> FIN
  THR --> FIN`,
  'cfg_finish_session': `flowchart TD
  A["A · l.273<br/>media = currentMedia"] --> C1{"C1 · l.274<br/>media == null"}
  C1 -- V --> R0["return (sin sesión)"]
  C1 -- F --> C2{"C2 · l.274<br/>user == null"}
  C2 -- V --> R0
  C2 -- F --> B["B · l.275-294<br/>metadata + resumenSesion()<br/>FocusSession local (synced=false)<br/>history.insert(0, local)"]
  B --> T{"T · l.295-296<br/>await saveFocusSession()"}
  T -- éxito --> C3{"C3 · l.298<br/>i &gt;= 0"}
  C3 -- V --> S["reemplaza por la guardada"]
  C3 -- F --> N["N · l.304 _changed()"]
  S --> N
  T -- ApiException --> C4{"C4 · l.300<br/>e.unauthorized"}
  C4 -- V --> R1["return (sesión vencida)"]
  C4 -- F --> P["P · l.301-302<br/>_pendientes.add + aviso"]
  P --> N
  R0 --> FIN(("fin"))
  R1 --> FIN
  N --> FIN`,
  'cfg_backend_create': `flowchart TD
  A["A · l.19-20<br/>startedAt, endedAt = new Date()"] --> D1{"D1 · l.21<br/>endedAt &lt; startedAt"}
  D1 -- V --> E1["400 · endedAt debe ser posterior"]
  D1 -- F --> D2{"D2 · l.24<br/>endedAt &gt; ahora + 5 min"}
  D2 -- V --> E2["400 · no puede estar en el futuro"]
  D2 -- F --> D3{"D3 · l.27<br/>durationSeconds &gt; targetMinutes·60"}
  D3 -- V --> E3["400 · supera la duración objetivo"]
  D3 -- F --> C["C · l.30<br/>prisma.focusSession.create()"]
  E1 --> FIN(("fin"))
  E2 --> FIN
  E3 --> FIN
  C --> FIN`,
};

(async () => {
  const navegador = await puppeteer.launch({ executablePath: CHROME, headless: true });
  const pagina = await navegador.newPage();
  await pagina.setViewport({ width: 1400, height: 1000, deviceScaleFactor: 2 });
  for (const [nombre, def] of Object.entries(grafos)) {
    fs.writeFileSync(path.join(out, `${nombre}.mmd`), def + '\n');
    const html = `<!doctype html><html><head><meta charset="utf-8">
<style>body{margin:0;background:#fff;font-family:Arial} #g{display:inline-block;padding:16px}</style>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script></head>
<body><div id="g" class="mermaid">${def}</div>
<script>mermaid.initialize({startOnLoad:true,theme:'neutral',themeVariables:{fontSize:'15px'},flowchart:{curve:'basis',htmlLabels:true,useMaxWidth:false}});</script></body></html>`;
    const archivo = path.join(out, `${nombre}.html`);
    fs.writeFileSync(archivo, html);
    await pagina.goto('file:///' + archivo.replace(/\\/g, '/'), { waitUntil: 'networkidle0' });
    await pagina.waitForSelector('#g svg');
    const el = await pagina.$('#g');
    await el.screenshot({ path: path.join(out, nombre + '.png') });
    console.log('PNG', nombre);
  }
  await navegador.close();
})();
