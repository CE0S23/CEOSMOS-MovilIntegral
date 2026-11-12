// Práctica 11 · Fase 1: complejidad ciclomática (McCabe) aproximada de funciones Dart.
// V(G) = puntos de decisión + 1. Decisiones: if, for, while, case, catch,
// &&, ||, ??, ?? = y el operador ternario. Se eliminan cadenas y comentarios antes
// de contar. Uso: node complejidad_dart.js lib/core lib/data lib/domain
const fs = require('fs');
const path = require('path');

function archivos(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) return archivos(p);
    return p.endsWith('.dart') && !p.endsWith('.g.dart') ? [p] : [];
  });
}

function limpiar(src) {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, ' '))
    .replace(/\/\/.*$/gm, '')
    .replace(/r?'''[\s\S]*?'''|r?"""[\s\S]*?"""/g, (m) => m.replace(/[^\n]/g, ' '))
    .replace(/r?'(?:\\.|[^'\\\n])*'|r?"(?:\\.|[^"\\\n])*"/g, "''");
}

const firma =
  /^\s*(?:static\s+|@override\s+|factory\s+|Future<[^>]*>\s+|[\w<>?,\s]+\s+)?([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)\s*\([^;]*?\)\s*(?:async\*?|sync\*)?\s*(\{|=>)/;

function decisiones(cuerpo) {
  const n = (re) => (cuerpo.match(re) || []).length;
  const ternarios = n(/\s\?\s/g); // "x ? a : b" (no cuenta tipos anulables "String?")
  return (
    n(/\bif\s*\(/g) + n(/\bfor\s*\(/g) + n(/\bwhile\s*\(/g) + n(/\bcase\b/g) +
    n(/\bcatch\b|\bon\s+\w+(?:Exception|Error)\b/g) + n(/&&/g) + n(/\|\|/g) +
    n(/\?\?/g) + Math.max(0, ternarios)
  );
}

const reservadas = new Set(['if', 'for', 'while', 'switch', 'catch', 'return', 'super', 'this']);
const filas = [];
for (const raiz of process.argv.slice(2)) {
  for (const f of archivos(raiz)) {
    const src = limpiar(fs.readFileSync(f, 'utf8'));
    const lineas = src.split('\n');
    for (let i = 0; i < lineas.length; i++) {
      // Firmas en varias líneas: se unen hasta encontrar '{' o '=>'.
      let cabecera = lineas[i];
      if (/\w\(/.test(cabecera) && !/[;{]|=>/.test(cabecera)) {
        for (let k = 1; k < 10 && i + k < lineas.length && !/\)\s*(?:async\*?|sync\*)?\s*(?:\{|=>)|;/.test(cabecera); k++) {
          cabecera += ' ' + lineas[i + k].trim();
        }
      }
      const m = cabecera.match(firma);
      if (!m || reservadas.has(m[1])) continue;
      // Llamadas a constructores de widgets (Text(...), SizedBox(...)) no son funciones.
      if (/^[A-Z]/.test(m[1]) && !m[1].includes('.')) continue;
      // Une la firma con el cuerpo: por llaves o, en "=>", hasta el ';' final.
      let j = i, cuerpo = '';
      if (m[2] === '{') {
        let prof = 0, empezo = false;
        for (; j < lineas.length; j++) {
          for (const c of lineas[j]) {
            if (c === '{') { prof++; empezo = true; }
            if (c === '}') prof--;
          }
          cuerpo += lineas[j] + '\n';
          if (empezo && prof <= 0) break;
        }
      } else {
        for (; j < lineas.length; j++) {
          cuerpo += lineas[j] + '\n';
          if (/;\s*$/.test(lineas[j])) break;
        }
      }
      filas.push({ cc: decisiones(cuerpo) + 1, f: f.replace(/\\/g, '/'), l: i + 1, n: m[1] });
    }
  }
}
filas.sort((a, b) => b.cc - a.cc);
console.log('V(G) | archivo:línea | función');
for (const r of filas.filter((r) => r.cc >= 4)) console.log(`${r.cc} | ${r.f}:${r.l} | ${r.n}`);
console.log(`\nFunciones analizadas: ${filas.length}; con V(G) >= 10: ${filas.filter((r) => r.cc >= 10).length}`);
