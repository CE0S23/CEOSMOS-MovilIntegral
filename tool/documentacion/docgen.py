# -*- coding: utf-8 -*-
"""Utilidades para generar los documentos Word de CEOSMOS con el sistema de diseño
(Bricolage Grotesque en títulos, DM Sans en texto, guinda #5B011D y cian #51D7FD).

Los campos (índice, listas de figuras y tablas, SEQ y PAGE) se actualizan después con
Word (tool/documentacion/actualizar_y_exportar.ps1), que también exporta a PDF.
"""
import copy
import re

import docx
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

GUINDA = RGBColor(0x5B, 0x01, 0x1D)
GUINDA_MEDIO = RGBColor(0x8A, 0x1C, 0x3D)
CIAN_TEXTO = RGBColor(0x08, 0x70, 0x8F)
TINTA = RGBColor(0x1E, 0x0A, 0x12)
GRIS = RGBColor(0x6B, 0x5A, 0x60)
TITULOS = 'Bricolage Grotesque 36pt'
TEXTO = 'DM Sans'
REPO = 'https://github.com/CE0S23/CEOSMOS-MovilIntegral'


def _fuente(estilo_o_run, nombre):
    f = estilo_o_run.font
    f.name = nombre
    rpr = estilo_o_run.element.get_or_add_rPr() if hasattr(estilo_o_run.element, 'get_or_add_rPr') else None
    if rpr is not None:
        rf = rpr.find(qn('w:rFonts'))
        if rf is None:
            rf = OxmlElement('w:rFonts')
            rpr.append(rf)
        for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
            rf.set(qn(a), nombre)


class Doc:
    def __init__(self, plantilla, titulo_corto, version='1.3.0'):
        """plantilla: un .docx del proyecto con los estilos de la marca (se vacía el cuerpo)."""
        self.d = docx.Document(plantilla)
        body = self.d.element.body
        for el in list(body):
            if el.tag != qn('w:sectPr'):
                body.remove(el)
        self.titulo_corto = titulo_corto
        self.version = version
        self._estilos()
        self._img_id = 1000

    # ---------- estilos ----------
    def _estilos(self):
        st = self.d.styles
        n = st['Normal']
        _fuente(n, TEXTO)
        n.font.size = Pt(11)
        n.font.color.rgb = TINTA
        n.paragraph_format.space_after = Pt(6)
        n.paragraph_format.line_spacing = 1.12
        for nombre, tam, color, fuente, antes in (
                ('Heading 1', 18, GUINDA, TITULOS, 18), ('Heading 2', 13.5, GUINDA_MEDIO, TITULOS, 12),
                ('Heading 3', 11.5, CIAN_TEXTO, TEXTO, 8)):
            h = st[nombre]
            _fuente(h, fuente)
            h.font.size = Pt(tam)
            h.font.bold = True
            h.font.color.rgb = color
            h.paragraph_format.space_before = Pt(antes)
            h.paragraph_format.space_after = Pt(6)
            h.paragraph_format.keep_with_next = True
        try:
            c = st['Caption']
        except KeyError:
            c = st.add_style('Caption', 1)
        _fuente(c, TEXTO)
        c.font.size = Pt(9)
        c.font.bold = False
        c.font.italic = True
        c.font.color.rgb = GRIS
        c.paragraph_format.space_after = Pt(10)
        for nombre in ('List Bullet', 'List Number'):
            try:
                s = st[nombre]
                _fuente(s, TEXTO)
                s.font.size = Pt(11)
                s.font.color.rgb = TINTA
            except KeyError:
                pass
        for nombre in ('TOC 1', 'TOC 2', 'TOC 3', 'Table of Figures'):
            try:
                s = st[nombre]
            except KeyError:
                s = st.add_style(nombre, 1)
            _fuente(s, TEXTO)
            s.font.size = Pt(10.5)
            s.paragraph_format.space_after = Pt(2)
            if nombre == 'TOC 2':
                s.paragraph_format.left_indent = Cm(0.5)
            if nombre == 'TOC 3':
                s.paragraph_format.left_indent = Cm(1.0)

    # ---------- texto ----------
    def _runs(self, p, texto, tam=None, color=None):
        """Marcado mínimo: **negrita**, *cursiva*, `código` y [texto](url)."""
        patron = re.compile(r'(\*\*.+?\*\*|`.+?`|\[[^\]]+\]\([^)]+\)|(?<!\*)\*[^*]+?\*(?!\*))')
        for trozo in patron.split(texto):
            if not trozo:
                continue
            if trozo.startswith('**'):
                r = p.add_run(trozo[2:-2]); r.bold = True
            elif trozo.startswith('`'):
                r = p.add_run(trozo[1:-1]); _fuente(r, 'Consolas'); r.font.size = Pt((tam or 11) - 1.5)
                r.font.color.rgb = GUINDA_MEDIO
                continue
            elif re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', trozo):
                m = re.fullmatch(r'\[([^\]]+)\]\(([^)]+)\)', trozo)
                self.enlace(p, m.group(1), m.group(2), tam)
                continue
            elif re.fullmatch(r'\*[^*]+\*', trozo):
                r = p.add_run(trozo[1:-1]); r.italic = True
            else:
                r = p.add_run(trozo)
            if tam:
                r.font.size = Pt(tam)
            if color is not None:
                r.font.color.rgb = color
        return p

    def enlace(self, p, texto, url, tam=None):
        rid = p.part.relate_to(url, 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
                               is_external=True)
        h = OxmlElement('w:hyperlink')
        h.set(qn('r:id'), rid)
        r = OxmlElement('w:r')
        rpr = OxmlElement('w:rPr')
        c = OxmlElement('w:color'); c.set(qn('w:val'), '08708F'); rpr.append(c)
        u = OxmlElement('w:u'); u.set(qn('w:val'), 'single'); rpr.append(u)
        if tam:
            sz = OxmlElement('w:sz'); sz.set(qn('w:val'), str(int(tam * 2))); rpr.append(sz)
        r.append(rpr)
        t = OxmlElement('w:t'); t.text = texto; t.set(qn('xml:space'), 'preserve'); r.append(t)
        h.append(r)
        p._p.append(h)

    def p(self, texto='', estilo=None, alin=None, tam=None, color=None, antes=None, despues=None):
        par = self.d.add_paragraph(style=estilo)
        self._runs(par, texto, tam, color)
        if alin == 'c':
            par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        elif alin == 'j':
            par.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        if antes is not None:
            par.paragraph_format.space_before = Pt(antes)
        if despues is not None:
            par.paragraph_format.space_after = Pt(despues)
        return par

    def h1(self, t, salto=True):
        par = self.d.add_paragraph(style='Heading 1')
        if salto:
            par.paragraph_format.page_break_before = True
        par.add_run(t)
        return par

    def h2(self, t):
        return self.p(t, 'Heading 2')

    def h3(self, t):
        return self.p(t, 'Heading 3')

    def viñetas(self, items, estilo='List Bullet'):
        for it in items:
            self.p(it, estilo, despues=3)

    def numerada(self, items):
        for i, it in enumerate(items, 1):
            par = self.p(f'{i}. ' + it, despues=3)
            par.paragraph_format.left_indent = Cm(0.6)
            par.paragraph_format.first_line_indent = Cm(-0.6)

    def salto(self):
        self.d.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    # ---------- campos ----------
    def _campo(self, par, instr, marcador='Actualice el campo (F9).'):
        def fc(t):
            r = OxmlElement('w:r'); f = OxmlElement('w:fldChar'); f.set(qn('w:fldCharType'), t); r.append(f); return r
        par._p.append(fc('begin'))
        r = OxmlElement('w:r'); it = OxmlElement('w:instrText'); it.set(qn('xml:space'), 'preserve'); it.text = f' {instr} '
        r.append(it); par._p.append(r)
        par._p.append(fc('separate'))
        r = OxmlElement('w:r'); t = OxmlElement('w:t'); t.text = marcador; r.append(t); par._p.append(r)
        par._p.append(fc('end'))

    def indice(self):
        self.p('Índice', 'Heading 1').paragraph_format.page_break_before = True
        self._campo(self.d.add_paragraph(), 'TOC \\o "1-3" \\h \\z \\u')

    def lista_figuras(self):
        self.p('Lista de figuras', 'Heading 1').paragraph_format.page_break_before = True
        self._campo(self.d.add_paragraph(), 'TOC \\h \\z \\c "Figura"')

    def lista_tablas(self, salto=False):
        par = self.p('Lista de tablas', 'Heading 1')
        par.paragraph_format.page_break_before = salto
        self._campo(self.d.add_paragraph(), 'TOC \\h \\z \\c "Tabla"')

    def _pie(self, tipo, texto, arriba=False):
        par = self.d.add_paragraph(style='Caption')
        r = par.add_run(f'{tipo} ')
        self._campo(par, f'SEQ {tipo} \\* ARABIC', '1')
        par.add_run('. ' + texto)
        if arriba:
            par.paragraph_format.keep_with_next = True
            par.paragraph_format.space_after = Pt(3)
            par.paragraph_format.space_before = Pt(6)
        return par

    # ---------- figuras ----------
    def figura(self, ruta, pie, ancho_cm=16.0, alt=None):
        par = self.d.add_paragraph()
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        par.paragraph_format.keep_with_next = True
        run = par.add_run()
        run.add_picture(ruta, width=Cm(ancho_cm))
        self._alt(run, alt or pie)
        self._pie('Figura', pie).alignment = WD_ALIGN_PARAGRAPH.CENTER

    def figuras_lado(self, rutas, pie, alto_cm=9.0, alt=None):
        par = self.d.add_paragraph()
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        par.paragraph_format.keep_with_next = True
        for i, ruta in enumerate(rutas):
            run = par.add_run('    ' if i else '')
            run = par.add_run()
            run.add_picture(ruta, height=Cm(alto_cm))
            self._alt(run, (alt or pie) + f' (imagen {i + 1} de {len(rutas)})')
        self._pie('Figura', pie).alignment = WD_ALIGN_PARAGRAPH.CENTER

    @staticmethod
    def _alt(run, texto):
        for dp in run._r.iter(qn('wp:docPr')):
            dp.set('descr', texto)
            dp.set('title', texto[:120])

    # ---------- tablas ----------
    def tabla(self, filas, anchos_cm, pie=None, tam=9.5, cabecera=True):
        if pie:
            self._pie('Tabla', pie, arriba=True)
        t = self.d.add_table(rows=len(filas), cols=len(filas[0]))
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        tblPr = t._tbl.tblPr
        bordes = OxmlElement('w:tblBorders')
        for b in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
            e = OxmlElement(f'w:{b}'); e.set(qn('w:val'), 'single'); e.set(qn('w:sz'), '4'); e.set(qn('w:color'), 'D9C9CF')
            bordes.append(e)
        tblPr.append(bordes)
        mar = OxmlElement('w:tblCellMar')
        for lado, v in (('top', 50), ('bottom', 50), ('left', 90), ('right', 90)):
            e = OxmlElement(f'w:{lado}'); e.set(qn('w:w'), str(v)); e.set(qn('w:type'), 'dxa'); mar.append(e)
        tblPr.append(mar)
        lay = OxmlElement('w:tblLayout'); lay.set(qn('w:type'), 'fixed'); tblPr.append(lay)
        for i, fila in enumerate(filas):
            row = t.rows[i]
            trPr = row._tr.get_or_add_trPr()
            cs = OxmlElement('w:cantSplit'); trPr.append(cs)
            if i == 0 and cabecera:
                th = OxmlElement('w:tblHeader'); trPr.append(th)
            for j, valor in enumerate(fila):
                cel = row.cells[j]
                cel.width = Cm(anchos_cm[j])
                par = cel.paragraphs[0]
                par.paragraph_format.space_after = Pt(0)
                par.paragraph_format.line_spacing = 1.0
                lineas = str(valor).split('\n')
                for k, linea in enumerate(lineas):
                    if k:
                        par = cel.add_paragraph(); par.paragraph_format.space_after = Pt(0)
                    if i == 0 and cabecera:
                        r = par.add_run(linea); r.bold = True; r.font.size = Pt(tam); r.font.color.rgb = RGBColor(255, 255, 255)
                    else:
                        self._runs(par, linea, tam)
                tcPr = cel._tc.get_or_add_tcPr()
                if i == 0 and cabecera:
                    self._sombra(tcPr, '5B011D')
                elif i % 2 == 0:
                    self._sombra(tcPr, 'FBF3EE')
        for j, w in enumerate(anchos_cm):
            for c in t.columns[j].cells:
                c.width = Cm(w)
        # Tablas cortas: que no se separen del encabezado ni queden partidas al pie de página.
        limite = len(filas) if len(filas) <= 9 else 2
        for i in range(min(limite, len(filas)) - 1):
            for cel in t.rows[i].cells:
                for par in cel.paragraphs:
                    par.paragraph_format.keep_with_next = True
        self.d.add_paragraph().paragraph_format.space_after = Pt(2)
        return t

    @staticmethod
    def _sombra(tcPr, color):
        s = OxmlElement('w:shd'); s.set(qn('w:val'), 'clear'); s.set(qn('w:color'), 'auto'); s.set(qn('w:fill'), color)
        tcPr.append(s)

    def nota(self, texto, color='DDF7FF'):
        t = self.d.add_table(rows=1, cols=1)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        cel = t.rows[0].cells[0]
        cel.width = Cm(16.5)
        self._runs(cel.paragraphs[0], texto, 10)
        cel.paragraphs[0].paragraph_format.space_after = Pt(0)
        self._sombra(cel._tc.get_or_add_tcPr(), color)
        self.d.add_paragraph().paragraph_format.space_after = Pt(2)

    # ---------- portada, encabezado y pie ----------
    def portada(self, logo, titulo, subtitulo, lineas_meta, autor):
        self.p('Universidad Tecnológica de Querétaro', alin='c', tam=11, color=GRIS, despues=0)
        self.p('Desarrollo Móvil Integral · 10.° cuatrimestre', alin='c', tam=11, color=GRIS, despues=30)
        if logo:
            par = self.d.add_paragraph(); par.alignment = WD_ALIGN_PARAGRAPH.CENTER
            run = par.add_run(); run.add_picture(logo, width=Cm(3.2)); self._alt(run, 'Logotipo de CEOSMOS (símbolo de infinito)')
        par = self.p('', alin='c', antes=18, despues=4)
        r = par.add_run('CEOSMOS Móvil Integral'); _fuente(r, TITULOS); r.font.size = Pt(30); r.bold = True; r.font.color.rgb = GUINDA
        par = self.p('', alin='c', despues=6)
        r = par.add_run(titulo); _fuente(r, TITULOS); r.font.size = Pt(20); r.bold = True; r.font.color.rgb = GUINDA_MEDIO
        self.p(subtitulo, alin='c', tam=12, color=CIAN_TEXTO, despues=40)
        for l in lineas_meta:
            self.p(l, alin='c', tam=11, despues=2)
        self.p('', despues=40)
        for l in autor:
            self.p(l, alin='c', tam=11, despues=2)

    def encabezado_pie(self, texto_pie):
        sec = self.d.sections[0]
        sec.different_first_page_header_footer = True
        h = sec.header.paragraphs[0]
        for r in list(h.runs):
            r._r.getparent().remove(r._r)
        h.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        r = h.add_run(f'CEOSMOS Móvil Integral · {self.titulo_corto}'); r.font.size = Pt(8.5); r.font.color.rgb = GRIS
        f = sec.footer.paragraphs[0]
        for el in list(f._p):
            if el.tag != qn('w:pPr'):
                f._p.remove(el)
        f.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = f.add_run(texto_pie + ' · página '); r.font.size = Pt(8.5); r.font.color.rgb = GRIS
        self._campo(f, 'PAGE', '1')
        r = f.add_run(' de '); r.font.size = Pt(8.5); r.font.color.rgb = GRIS
        self._campo(f, 'NUMPAGES', '1')

    def propiedades(self, titulo, asunto, palabras):
        cp = self.d.core_properties
        cp.author = 'César Osvaldo Ramírez Pérez'
        cp.last_modified_by = 'César Osvaldo Ramírez Pérez'
        cp.title = titulo
        cp.subject = asunto
        cp.keywords = palabras
        cp.language = 'es-MX'
        cp.comments = 'Universidad Tecnológica de Querétaro · IDGS16 · matrícula 2023371167'

    def margenes(self, izq=2.2, der=2.2, arr=2.0, aba=2.0):
        s = self.d.sections[0]
        s.page_width, s.page_height = Cm(21.59), Cm(27.94)
        s.left_margin, s.right_margin, s.top_margin, s.bottom_margin = Cm(izq), Cm(der), Cm(arr), Cm(aba)

    def guardar(self, ruta):
        self.d.save(ruta)
