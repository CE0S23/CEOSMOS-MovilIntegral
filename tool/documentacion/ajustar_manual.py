# -*- coding: utf-8 -*-
"""Ajustes del Manual de usuario sin rehacerlo: índice automático, lista de figuras, pies «Figura N»,
texto alternativo, encabezado, propiedades y fecha. Idempotente sobre la versión del 24/11."""
import copy
import os
import sys

import docx
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor
from docx.text.paragraph import Paragraph

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from docgen import Doc  # noqa: E402

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RUTA = os.path.join(R, 'Manual de usuario - CEOSMOS.docx')
d = docx.Document(RUTA)
campo = Doc._campo.__get__(type('X', (), {})())  # reutiliza el generador de campos


def nuevo_par_despues(el, estilo=None):
    p = OxmlElement('w:p')
    el.addnext(p)
    par = Paragraph(p, d._body)
    if estilo:
        par.style = d.styles[estilo]
    return par


def sin_repetir(t):
    # Las imágenes con llamadas guardan el texto también en su versión alternativa: «AAA» → «A».
    for n in range(1, len(t) // 2 + 1):
        if len(t) % n == 0 and t[:n] * (len(t) // n) == t:
            return t[:n]
    return t


def titulo_seccion(el):
    prev = el.getprevious()
    while prev is not None:
        if prev.tag == qn('w:p'):
            par = Paragraph(prev, d._body)
            if par.style.name.startswith('Heading'):
                t = par.text.strip()
                return 'CEOSMOS instalada como PWA en el navegador' if 'PWA' in t else t
        prev = prev.getprevious()
    return 'Pantalla de CEOSMOS'


# Caption con la tipografía de la marca
try:
    cap = d.styles['Caption']
except KeyError:
    cap = d.styles.add_style('Caption', 1)
cap.font.name = 'DM Sans'; cap.font.size = Pt(9); cap.font.bold = False; cap.font.italic = True
cap.font.color.rgb = RGBColor(0x6B, 0x5A, 0x60)

ya = any(p.text.startswith('Figura ') for p in d.paragraphs if p.style.name == 'Caption')
body = d.element.body

# 1. Fecha de portada
for p in d.paragraphs[:12]:
    for r in p.runs:
        if '24 de noviembre de 2026' in r.text:
            r.text = r.text.replace('24 de noviembre de 2026', '25 de noviembre de 2026')

if not ya:
    # 2. Índice automático en lugar de la lista escrita a mano
    pars = d.paragraphs
    i = next(k for k, p in enumerate(pars) if p.style.name == 'Heading 1' and p.text.strip() == 'Contenido')
    k = i + 1
    while pars[k].text[:2].strip().rstrip('.').isdigit():
        k += 1
    for p in pars[i + 1:k]:
        p._p.getparent().remove(p._p)
    pars[i].runs[0].text = 'Índice'
    toc = nuevo_par_despues(pars[i]._p)
    campo(toc, 'TOC \\o "1-2" \\h \\z \\u')
    lf = nuevo_par_despues(toc._p, 'Heading 2')
    lf.add_run('Lista de figuras')
    tf = nuevo_par_despues(lf._p)
    campo(tf, 'TOC \\h \\z \\c "Figura"')

    # 3. Pies de figura y texto alternativo
    n = 0
    for el in list(body.iterchildren()):
        if not el.xpath('.//pic:pic'):
            continue
        if el.tag == qn('w:tbl'):
            textos = [t for t in (sin_repetir(''.join(x.text or '' for x in par.iter(qn('w:t'))).strip())
                                  for par in el.iter(qn('w:p'))) if t]
            titulo = textos[0] if textos else 'Pantalla de CEOSMOS'
        else:
            prev = el.getprevious()
            if body.index(el) < 8:  # logotipo de la portada
                for dp in el.iter(qn('wp:docPr')):
                    dp.set('descr', 'Logotipo de CEOSMOS (símbolo de infinito)')
                continue
            titulo = titulo_seccion(el)
        for dp in el.iter(qn('wp:docPr')):
            dp.set('descr', f'Captura: {titulo}. Los números en círculo señalan las partes explicadas en el texto.')
            dp.set('title', titulo[:120])
        n += 1
        pie = nuevo_par_despues(el, 'Caption')
        pie.alignment = WD_ALIGN_PARAGRAPH.CENTER
        pie.add_run('Figura ')
        campo(pie, 'SEQ Figura \\* ARABIC', str(n))
        pie.add_run('. ' + titulo)
    print('figuras', n)

# 4. Encabezado y propiedades
sec = d.sections[0]
sec.different_first_page_header_footer = True
h = sec.header.paragraphs[0]
if not h.text:
    h.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = h.add_run('CEOSMOS Móvil Integral · Manual de usuario'); r.font.size = Pt(8.5); r.font.color.rgb = RGBColor(0x6B, 0x5A, 0x60)
cp = d.core_properties
cp.author = cp.last_modified_by = 'César Osvaldo Ramírez Pérez'
cp.title = 'Manual de usuario - CEOSMOS'
cp.subject = 'Uso de CEOSMOS Móvil Integral 1.3.0 (app Android, PWA, Reloj y TV)'
cp.keywords = 'CEOSMOS; manual; PWA; Reloj; TV'
cp.language = 'es-MX'
d.save(RUTA)
print('ok')
