# -*- coding: utf-8 -*-
"""Convierte un .md sencillo (títulos, párrafos, tablas, listas) a .docx con el estilo de CEOSMOS.
Uso: python tool/documentacion/md_a_docx.py entrada.md "Título corto" """
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from docgen import Doc  # noqa: E402

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
md, corto = sys.argv[1], sys.argv[2]
lineas = open(md, encoding='utf-8').read().splitlines()
d = Doc(os.path.join(R, 'Manual de usuario - CEOSMOS.docx'), corto)
d.margenes(1.9, 1.9, 1.8, 1.8)
titulo = lineas[0].lstrip('# ').strip()
d.propiedades(os.path.splitext(os.path.basename(md))[0], titulo, 'CEOSMOS; rúbrica')
d.encabezado_pie(corto + ' · versión 1.3.0')
d.d.sections[0].different_first_page_header_footer = False
d.p(titulo, 'Heading 1')
i = 1
ancho = 17.8
while i < len(lineas):
    l = lineas[i]
    if l.startswith('## '):
        d.h2(l[3:])
    elif l.startswith('|'):
        filas = []
        while i < len(lineas) and lineas[i].startswith('|'):
            celdas = [c.strip() for c in lineas[i].strip().strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?', c) for c in celdas):
                filas.append(celdas)
            i += 1
        n = len(filas[0])
        pesos = [max(len(f[j]) for f in filas) ** 0.6 for j in range(n)]
        anchos = [max(2.6, ancho * p / sum(pesos)) for p in pesos]
        anchos = [a * ancho / sum(anchos) for a in anchos]
        d.tabla(filas, anchos, tam=8.5)
        continue
    elif re.match(r'\d+\. ', l):
        d.p(l, despues=3).paragraph_format.left_indent = 0
    elif l.startswith('- '):
        d.p(l[2:], 'List Bullet', despues=3)
    elif l.strip():
        d.p(l, despues=4)
    i += 1
salida = os.path.splitext(md)[0] + '.docx'
d.guardar(salida)
print(salida)
