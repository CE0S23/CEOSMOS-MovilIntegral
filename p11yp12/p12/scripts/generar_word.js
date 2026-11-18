// Práctica 11 y 12 · Convierte el reporte .md en un .docx (encabezados, tablas,
// bloques de código, listas, imágenes y **negritas**/`código` en línea).
//   P11_TOOLS=<carpeta con node_modules/docx> node generar_word.js <reporte.md> <salida.docx>
const fs = require('fs');
const path = require('path');
const {
  AlignmentType, BorderStyle, Document, HeadingLevel, ImageRun, Packer, Paragraph,
  ShadingType, Table, TableCell, TableRow, TextRun, WidthType, Footer, PageNumber,
} = require(path.join(process.env.P11_TOOLS || '.', 'node_modules', 'docx'));

const [md, salida] = process.argv.slice(2);
const base = path.dirname(path.resolve(md));
const lineas = fs.readFileSync(md, 'utf8').split(/\r?\n/);
const FUENTE = 'Arial', NEGRO = '151515', GRIS = '535B68', BORDE = 'C9CFDA', FONDO = 'EEF1F6';

function enLinea(texto, extra = {}) {
  const partes = [];
  const re = /(\*\*[^*]+\*\*|`[^`]+`)/g;
  let i = 0, m;
  while ((m = re.exec(texto))) {
    if (m.index > i) partes.push(new TextRun({ text: texto.slice(i, m.index), font: FUENTE, color: NEGRO, ...extra }));
    const t = m[0];
    partes.push(t.startsWith('**')
      ? new TextRun({ text: t.slice(2, -2), bold: true, font: FUENTE, color: NEGRO, ...extra })
      : new TextRun({ text: t.slice(1, -1), font: 'Consolas', color: '1F3A68', ...extra, size: (extra.size || 20) - 2 }));
    i = m.index + t.length;
  }
  if (i < texto.length) partes.push(new TextRun({ text: texto.slice(i), font: FUENTE, color: NEGRO, ...extra }));
  return partes;
}

function tamPng(archivo) {
  const b = fs.readFileSync(archivo);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20), datos: b };
}

const celdas = (fila) => fila.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
function tabla(filas) {
  const cab = celdas(filas[0]);
  const cuerpo = filas.slice(2).map(celdas);
  const n = cab.length;
  const borde = { style: BorderStyle.SINGLE, size: 4, color: BORDE };
  const celda = (t, esCab) => new TableCell({
    shading: esCab ? { type: ShadingType.CLEAR, color: 'auto', fill: FONDO } : undefined,
    borders: { top: borde, bottom: borde, left: borde, right: borde },
    margins: { top: 40, bottom: 40, left: 70, right: 70 },
    children: [new Paragraph({ children: enLinea(t, { size: n > 8 ? 14 : n > 5 ? 16 : 18, bold: esCab || undefined }) })],
  });
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [new TableRow({ tableHeader: true, children: cab.map((t) => celda(t, true)) }),
      ...cuerpo.map((f) => new TableRow({ children: Array.from({ length: n }, (_, k) => celda(f[k] ?? '', false)) }))],
  });
}

const hijos = [];
for (let i = 0; i < lineas.length; i++) {
  const l = lineas[i];
  if (!l.trim()) continue;
  if (l.startsWith('```')) {
    const bloque = [];
    for (i++; i < lineas.length && !lineas[i].startsWith('```'); i++) bloque.push(lineas[i]);
    hijos.push(new Paragraph({
      shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F4F5F8' },
      spacing: { before: 60, after: 120 },
      children: bloque.flatMap((t, k) => [new TextRun({ text: t, font: 'Consolas', size: 15, color: NEGRO, break: k ? 1 : 0 })]),
    }));
    continue;
  }
  const h = l.match(/^(#{1,3}) (.*)$/);
  if (h) {
    const nivel = h[1].length;
    hijos.push(new Paragraph({
      heading: [HeadingLevel.TITLE, HeadingLevel.HEADING_1, HeadingLevel.HEADING_2][nivel - 1],
      alignment: nivel === 1 ? AlignmentType.CENTER : undefined,
      spacing: { before: nivel === 1 ? 0 : 220, after: 120 },
      children: [new TextRun({ text: h[2], font: FUENTE, bold: true, color: NEGRO, size: [36, 28, 23][nivel - 1] })],
    }));
    continue;
  }
  if (l.startsWith('|')) {
    const filas = [];
    for (; i < lineas.length && lineas[i].startsWith('|'); i++) filas.push(lineas[i]);
    i--;
    hijos.push(tabla(filas));
    hijos.push(new Paragraph({ spacing: { after: 80 }, children: [] }));
    continue;
  }
  const img = l.match(/^!\[([^\]]*)\]\(([^)]+)\)/);
  if (img) {
    const { w, h: alto, datos } = tamPng(path.join(base, img[2]));
    const escala = Math.min(560 / w, 620 / alto, 1);
    hijos.push(new Paragraph({ alignment: AlignmentType.CENTER, children: [new ImageRun({ type: 'png', data: datos, transformation: { width: Math.round(w * escala), height: Math.round(alto * escala) } })] }));
    hijos.push(new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 160 }, children: [new TextRun({ text: img[1], italics: true, size: 17, font: FUENTE, color: GRIS })] }));
    continue;
  }
  const li = l.match(/^- (.*)$/);
  if (li) {
    hijos.push(new Paragraph({ bullet: { level: 0 }, spacing: { after: 60 }, children: enLinea(li[1], { size: 20 }) }));
    continue;
  }
  hijos.push(new Paragraph({ spacing: { after: 110, line: 290 }, children: enLinea(l, { size: 20 }) }));
}

const doc = new Document({
  creator: 'CEOSMOS', title: 'Práctica 11 · Pruebas White Box de CEOSMOS Móvil Integral',
  styles: { default: { document: { run: { font: FUENTE, size: 20 } } } },
  sections: [{
    properties: { page: { margin: { top: 1000, bottom: 1000, left: 1000, right: 1000 } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['CEOSMOS · Práctica 11 · ', PageNumber.CURRENT], size: 16, color: GRIS, font: FUENTE })] })] }) },
    children: hijos,
  }],
});
Packer.toBuffer(doc).then((b) => { fs.writeFileSync(salida, b); console.log('DOCX', salida, b.length, 'bytes'); });
