"""Convierte un markdown sencillo (títulos, párrafos, listas, tablas, código,
negritas y saltos de página) a .docx con los estilos del Reporte de avances
(Calibri 11, títulos en negrita gris oscuro, tablas con encabezado sombreado).

    python scripts/md_a_docx.py entrada.md salida.docx

Una línea con solo `\\pagebreak` inserta un salto de página.
"""
import re
import sys

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor, Inches
from docx.text.paragraph import Paragraph

TINTA = RGBColor(0x00, 0x00, 0x00)
TITULO = RGBColor(0x22, 0x22, 0x22)


def estilos(doc):
    normal = doc.styles['Normal']
    normal.font.name = 'Calibri'
    normal.font.size = Pt(11)
    normal.element.rPr.rFonts.set(qn('w:eastAsia'), 'Calibri')
    normal.paragraph_format.space_after = Pt(5)
    normal.paragraph_format.line_spacing = 1.1
    for nivel, tam in [(1, 16), (2, 13), (3, 11.5)]:
        st = doc.styles[f'Heading {nivel}']
        st.font.name = 'Calibri'
        st.font.size = Pt(tam)
        st.font.bold = True
        st.font.color.rgb = TITULO
        st.element.rPr.rFonts.set(qn('w:eastAsia'), 'Calibri')
        st.paragraph_format.space_before = Pt(12 if nivel == 1 else 9)
        st.paragraph_format.space_after = Pt(5)
        st.paragraph_format.keep_with_next = True
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Inches(8.5), Inches(11)
    for lado in ('left_margin', 'right_margin'):
        setattr(sec, lado, Inches(0.83))
    sec.top_margin = sec.bottom_margin = Inches(0.75)


def runs(par, texto, tam=None):
    # **negrita** y `código`
    for trozo in re.split(r'(\*\*[^*]+\*\*|`[^`]+`)', texto):
        if not trozo:
            continue
        if trozo.startswith('**'):
            r = par.add_run(trozo[2:-2]); r.bold = True
        elif trozo.startswith('`'):
            r = par.add_run(trozo[1:-1]); r.font.name = 'Consolas'; r.font.size = Pt(9.5)
        else:
            r = par.add_run(trozo)
        if tam and not trozo.startswith('`'):
            r.font.size = Pt(tam)


def sombrear(celda, color='EADDE1'):
    tcPr = celda._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), color)
    tcPr.append(shd)


def tabla(doc, filas):
    cab = [c.strip() for c in filas[0].strip('|').split('|')]
    cuerpo = [[c.strip() for c in f.strip('|').split('|')] for f in filas[2:]]
    t = doc.add_table(rows=1 + len(cuerpo), cols=len(cab))
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, c in enumerate(cab):
        cel = t.rows[0].cells[i]; cel.text = ''
        runs(cel.paragraphs[0], c.replace('**', ''), 9); cel.paragraphs[0].runs[0].bold = True if cel.paragraphs[0].runs else None
        sombrear(cel)
    for fi, fila in enumerate(cuerpo, 1):
        for i in range(len(cab)):
            cel = t.rows[fi].cells[i]; cel.text = ''
            runs(cel.paragraphs[0], fila[i] if i < len(fila) else '', 9)
    doc.add_paragraph()


def convertir(entrada, salida):
    doc = Document()
    estilos(doc)
    lineas = open(entrada, encoding='utf-8').read().splitlines()
    i = 0
    while i < len(lineas):
        l = lineas[i]
        if l.strip() == '\\pagebreak':
            doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
        elif l.startswith('```'):
            bloque = []
            i += 1
            while i < len(lineas) and not lineas[i].startswith('```'):
                bloque.append(lineas[i]); i += 1
            p = doc.add_paragraph()
            r = p.add_run('\n'.join(bloque)); r.font.name = 'Consolas'; r.font.size = Pt(9)
        elif l.startswith('|') and i + 1 < len(lineas) and re.match(r'^\|[\s:|-]+\|$', lineas[i + 1].strip()):
            filas = []
            while i < len(lineas) and lineas[i].startswith('|'):
                filas.append(lineas[i]); i += 1
            tabla(doc, filas)
            continue
        elif m := re.match(r'^(#{1,3}) (.*)', l):
            doc.add_heading(m.group(2).strip(), level=len(m.group(1)))
        elif m := re.match(r'^(\s*)[-*] (?:\[[ x]\] )?(.*)', l):
            p = doc.add_paragraph(style='List Bullet' if not m.group(1) else 'List Bullet 2')
            marca = '☑ ' if '[x]' in l[:8] else ('☐ ' if '[ ]' in l[:8] else '')
            runs(p, marca + m.group(2))
        elif m := re.match(r'^\d+\. (.*)', l):
            runs(doc.add_paragraph(style='List Number'), m.group(1))
        elif l.strip().startswith('>'):
            p = doc.add_paragraph(); runs(p, l.strip().lstrip('> ')); p.paragraph_format.left_indent = Inches(0.3)
        elif l.strip():
            runs(doc.add_paragraph(), l.strip())
        i += 1
    saltos_antes_de_lo_siguiente(doc)
    doc.save(salida)


def saltos_antes_de_lo_siguiente(doc):
    """Cambia cada párrafo que solo contiene un salto de página por «salto antes»
    en el párrafo siguiente. Así, si la sección anterior llena la página justo,
    no queda una página en blanco (hoja de defensa, 22/11)."""
    for p in list(doc.paragraphs):
        if p.text.strip() or not p._p.xpath('.//w:br[@w:type="page"]'):
            continue
        siguiente = p._p.getnext()
        if siguiente is not None and siguiente.tag == qn('w:p'):
            # python-docx coloca el elemento en el orden que exige el esquema.
            Paragraph(siguiente, p._parent).paragraph_format.page_break_before = True
            p._p.getparent().remove(p._p)
            # Un párrafo vacío justo antes también podría caer solo en una página nueva.
            previo = siguiente.getprevious()
            while (previo is not None and previo.tag == qn('w:p')
                   and not ''.join(previo.itertext()).strip()
                   and not previo.xpath('.//w:br | .//w:drawing')):
                anterior = previo.getprevious()
                previo.getparent().remove(previo)
                previo = anterior


if __name__ == '__main__':
    convertir(sys.argv[1], sys.argv[2])
    print('ok', sys.argv[2])
