const fs = require('fs');
const path = require('path');
const {
  AlignmentType, BorderStyle, Document, HeadingLevel, ImageRun, Packer,
  PageBreak, Paragraph, ShadingType, Table, TableCell, TableRow, TextRun,
  WidthType,
} = require('docx');

const root = path.resolve(__dirname, '..');
const evidence = path.join(root, 'docs', 'evidencias', 'practica8');
const captures = path.join(evidence, 'capturas');
const output = path.join(evidence, 'CEOSMOS_Practica8_Reporte_BlackBox_Red.docx');
const testLog = fs.readFileSync(path.join(captures, 'blackbox_salida.txt'), 'utf8');
const browser = JSON.parse(fs.readFileSync(path.join(captures, 'navegador.json'), 'utf8'));
const network = JSON.parse(fs.readFileSync(path.join(captures, 'red_puertos.json'), 'utf8'));
if (!testLog.includes('All tests passed!')) throw new Error('La evidencia de caja negra no confirma el aprobado.');
if (browser.errors.length) throw new Error('La carga normal de Chrome registra errores; revisar antes de generar el informe.');

const black = '151515', muted = '535B68', pale = 'EEF0F5', border = 'D7DCE5';
const para = (text, opts = {}) => new Paragraph({
  spacing: { after: 120, line: 300 },
  ...opts,
  children: [new TextRun({ text, font: 'Arial', size: 21, color: black })],
});
const heading = text => new Paragraph({
  heading: HeadingLevel.HEADING_1,
  spacing: { before: 120, after: 130 },
  children: [new TextRun({ text, font: 'Arial', size: 28, bold: true, color: black })],
});
const subheading = text => new Paragraph({
  heading: HeadingLevel.HEADING_2,
  spacing: { before: 110, after: 95 },
  children: [new TextRun({ text, font: 'Arial', size: 23, bold: true, color: black })],
});
const caption = text => new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 45, after: 150 },
  children: [new TextRun({ text, font: 'Arial', size: 17, italics: true, color: muted })],
});
const pageBreak = () => new Paragraph({ children: [new PageBreak()] });
const picture = (name, width, height) => new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { after: 55 },
  children: [new ImageRun({
    data: fs.readFileSync(path.join(captures, name)),
    transformation: { width, height },
    type: 'png',
  })],
});
const tableCell = (text, width, header = false) => new TableCell({
  width: { size: width, type: WidthType.DXA },
  margins: { top: 110, bottom: 110, left: 110, right: 110 },
  shading: header ? { type: ShadingType.CLEAR, fill: pale } : undefined,
  borders: {
    bottom: { style: BorderStyle.SINGLE, size: 4, color: border },
    top: { style: BorderStyle.NONE },
    left: { style: BorderStyle.NONE },
    right: { style: BorderStyle.NONE },
  },
  children: [new Paragraph({
    spacing: { after: 0 },
    children: [new TextRun({ text, font: 'Arial', size: 18, bold: header, color: black })],
  })],
});
const summaryTable = new Table({
  width: { size: 10240, type: WidthType.DXA },
  columnWidths: [3240, 1700, 5300],
  rows: [
    ['Verificación', 'Resultado', 'Alcance'],
    ['Caja negra', '21 de 21 PASS', 'Doce requisitos; flujos de acceso, datos, sesión y errores'],
    ['App web en Chrome', 'Carga correcta', 'Modo demo visible; cero errores en la carga normal'],
    ['Puerto local 8765', 'TCP abierto', 'Solo 127.0.0.1; recursos locales HTTP 200'],
    ['HTTPS externo 443', 'HTTP 200', 'Fuentes de fonts.gstatic.com y repositorios de Flutter'],
  ].map((row, index) => new TableRow({
    children: row.map((value, col) => tableCell(value, [3240, 1700, 5300][col], index === 0)),
  })),
});

const local = network.Records.filter(row => row.Port === 8765);
const externalFonts = browser.externalResponses.filter(row => new URL(row.url).hostname === 'fonts.gstatic.com');
const blocked = browser.simulatedFontBlock?.failures?.length ?? 0;
const children = [
  new Paragraph({
    style: 'Title',
    spacing: { after: 100 },
    children: [new TextRun({ text: 'Informe de pruebas de caja negra y conectividad de CEOSMOS Móvil Integral', font: 'Arial', size: 35, bold: true, color: black })],
  }),
  para('Práctica 8  |  Universidad Tecnológica de Querétaro  |  23 de octubre de 2026', { spacing: { after: 150 } }),
  para('Evaluador: César. Pruebas realizadas en el equipo y conexión actuales, indicados por el estudiante como entorno universitario.', { spacing: { after: 170 } }),
  heading('Dictamen'),
  para('La aplicación aprobó 21 de 21 ejecuciones de caja negra y cubrió los 12 requisitos documentados. En la conexión probada, la versión web cargó en Chrome sin errores y respondió por el puerto local 8765; las solicitudes HTTPS externas observadas recibieron HTTP 200.'),
  para('Se identificó una dependencia importante: la versión web descarga fuentes desde fonts.gstatic.com por TCP 443. Una simulación de bloqueo de ese dominio dejó la pantalla sin texto. Ese fallo fue inducido para medir el riesgo; no se observó como bloqueo real de la red universitaria.'),
  summaryTable,
  new Paragraph({ spacing: { after: 70 } }),
  picture('app_demo.png', 570, 401),
  caption('Figura 1. Pantalla de inicio del modo demo capturada en Chrome desde la compilación web local.'),

  pageBreak(),
  heading('Resultados de la prueba de caja negra'),
  para('El guion automatizado ejercitó autenticación, validaciones, búsqueda, filtros, favoritos, sesiones, historial, dispositivos simulados, aislamiento entre usuarios, caducidad, navegación adaptable y manejo de un fallo de audio inyectado. Las 21 ejecuciones terminaron sin fallos ni omisiones.'),
  picture('blackbox_resultados.png', 590, 445),
  caption('Figura 2. Captura de la salida real de Flutter; el registro termina con “All tests passed!”.'),
  subheading('Interpretación'),
  para('El caso de audio CP-16 provoca un error controlado del reproductor para verificar el mensaje al usuario y la continuidad de la sesión. Su aprobación no significa que haya ocurrido una falla real de audio o de la red.'),
  para('Registro auditable: flutter-test.jsonl, blackbox_salida.txt y casos.csv en la carpeta de evidencias de la Práctica 8.'),

  pageBreak(),
  heading('Conectividad y puertos'),
  para(`El puerto TCP 8765 en 127.0.0.1 estuvo abierto. Se verificaron ${local.length - 1} rutas locales con HTTP 200, incluidos la página principal, el arranque Flutter, CanvasKit y un MP3. En Chrome, ${externalFonts.length} archivos de fonts.gstatic.com devolvieron HTTP 200 por HTTPS/TCP 443 y se registraron ${browser.errors.length} errores durante la carga normal.`),
  picture('red_puertos.png', 590, 447),
  caption('Figura 3. Captura del visor de resultados, generada desde las respuestas TCP y HTTP registradas.'),
  para('El puerto 8765 fue elegido solo para servir la app en el mismo equipo. Esta prueba no demuestra que un servidor en ese puerto sea accesible desde otros dispositivos de la universidad.'),

  pageBreak(),
  heading('Riesgo si se bloquean las fuentes web'),
  para(`Se bloqueó deliberadamente fonts.gstatic.com dentro de una sesión de prueba de Chrome. El navegador registró ${blocked} fallos de solicitud por el bloqueo inyectado. La pantalla siguió dibujando gráficos y controles, pero sus textos no aparecieron. La captura siguiente muestra ese efecto; no representa la conexión normal.`),
  picture('app_fuentes_bloqueadas.png', 570, 401),
  caption('Figura 4. Bloqueo simulado de fonts.gstatic.com; los textos dejan de renderizarse.'),
  subheading('Solicitud concreta para TI'),
  para('Para usar la versión web en redes con filtrado estricto, mantener permitido fonts.gstatic.com mediante HTTPS saliente por TCP 443. En la conexión actual ya respondió HTTP 200. No hay evidencia de que sea necesario abrir el puerto local 8765 en el firewall institucional.'),
  subheading('Límites del resultado'),
  para('La prueba funcional fue de widgets Flutter y el arranque visual se verificó en Chrome local. No se probó Android físico, reproducción audible, rendimiento, persistencia tras reinicio ni integraciones futuras con API, JWT, passkeys, BLE o TCP/IP. El dictamen se limita a esta versión y a la conexión observada.'),
];

const doc = new Document({
  creator: 'César',
  title: 'Informe de pruebas de caja negra y conectividad de CEOSMOS Móvil Integral',
  styles: { default: { document: { run: { font: 'Arial', size: 21, color: black } } } },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 850, right: 1000, bottom: 850, left: 1000 } } },
    children,
  }],
});
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(output, buffer);
  console.log(output);
}).catch(error => { console.error(error); process.exitCode = 1; });
