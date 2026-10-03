# -*- coding: utf-8 -*-
"""
Argus Full — gerador do relatório Word no padrão visual da ACD.

Padrão fixo (não muda entre idiomas; só os rótulos traduzem):
  · Arial em 100% do documento
  · cor SOMENTE nos marcadores de status
  · sem faixas ou blocos de cor sólida; hairlines como únicos separadores
  · rodapé com a linha de crédito fixa

Diferencial desta versão: cada achado de vídeo carrega o timecode e o LINK DO
QUADRO exportado, para que a pessoa confira o erro com os próprios olhos.
"""
from __future__ import annotations

import io
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor, Inches

# ---------------------------------------------------------------- paleta ACD
INK      = RGBColor(0x1F, 0x23, 0x28)
SUBINK   = RGBColor(0x57, 0x60, 0x6A)
RED      = RGBColor(0xB3, 0x26, 0x1E)
AMBER    = RGBColor(0x9A, 0x63, 0x00)
GREEN    = RGBColor(0x1E, 0x7B, 0x34)
HAIRLINE = "D9DCE1"
HEADFILL = "F6F7F8"
ACCENT   = "C6631F"
FONT     = "Arial"

LABELS = {
    "pt": dict(
        title="Argus — Relatório de Revisão Ortográfica",
        file="Arquivo", coverage="Cobertura", fmt="Formato", date="Data",
        requester="Solicitante", method="Método",
        errors="Erros", consistency="Consistência — a confirmar",
        clean="O que está limpo", notes="Notas",
        cols=("Local", "Está escrito", "Correto", "Observação/tempo"),
        chips=("erros", "a confirmar", "limpos", "nota(s) de cobertura"),
        frame="ver quadro", credit="Argus · Advisors Creative Desk · criado por Igor Fernandes",
        none="Nenhum erro de ortografia, acentuação, concordância ou digitação foi encontrado.",
    ),
    "en": dict(
        title="Argus — Spelling Review Report",
        file="File", coverage="Coverage", fmt="Format", date="Date",
        requester="Requester", method="Method",
        errors="Errors", consistency="Consistency — to confirm",
        clean="What's clean", notes="Notes",
        cols=("Location", "Reads", "Should be", "Note/time"),
        chips=("errors", "to confirm", "clean", "coverage note(s)"),
        frame="view frame", credit="Argus · Advisors Creative Desk · created by Igor Fernandes",
        none="No spelling, accentuation, agreement or typing errors were found.",
    ),
    "es": dict(
        title="Argus — Informe de Revisión Ortográfica",
        file="Archivo", coverage="Cobertura", fmt="Formato", date="Fecha",
        requester="Solicitante", method="Método",
        errors="Errores", consistency="Consistencia — a confirmar",
        clean="Lo que está limpio", notes="Notas",
        cols=("Ubicación", "Dice", "Debe decir", "Observación/tiempo"),
        chips=("errores", "a confirmar", "limpios", "nota(s) de cobertura"),
        frame="ver fotograma", credit="Argus · Advisors Creative Desk · creado por Igor Fernandes",
        none="No se encontraron errores de ortografía, acentuación, concordancia ni tipeo.",
    ),
}


# ---------------------------------------------------------------- utilidades
def _run(p, text, *, bold=False, color=INK, size=10, italic=False):
    r = p.add_run(text)
    r.font.name = FONT
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.italic = italic
    r.font.color.rgb = color
    r._element.rPr.rFonts.set(qn("w:cs"), FONT)   # Arial também em scripts complexos
    return r


def _shade(cell, hexcolor):
    el = OxmlElement("w:shd")
    el.set(qn("w:val"), "clear")
    el.set(qn("w:fill"), hexcolor)
    cell._tc.get_or_add_tcPr().append(el)


def _hairlines(table, inside_only=False):
    borders = OxmlElement("w:tblBorders")
    edges = ("insideH",) if inside_only else ("top", "bottom", "insideH")
    for edge in edges:
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:color"), HAIRLINE)
        borders.append(el)
    none_edges = (("top", "bottom", "left", "right", "insideV")
                  if inside_only else ("left", "right", "insideV"))
    for edge in none_edges:
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "none")
        borders.append(el)
    table._tbl.tblPr.append(borders)


def _rule(p, color, size=10):
    """Filete fino sob o parágrafo."""
    pbdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), str(size))
    bottom.set(qn("w:space"), "4")
    bottom.set(qn("w:color"), color)
    pbdr.append(bottom)
    p._p.get_or_add_pPr().append(pbdr)


def _hyperlink(p, url, text):
    """Link clicável — é como o quadro do vídeo chega ao revisor."""
    r_id = p.part.relate_to(
        url,
        "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink",
        is_external=True,
    )
    link = OxmlElement("w:hyperlink")
    link.set(qn("r:id"), r_id)
    run = OxmlElement("w:r")
    rpr = OxmlElement("w:rPr")
    fonts = OxmlElement("w:rFonts")
    fonts.set(qn("w:ascii"), FONT); fonts.set(qn("w:hAnsi"), FONT)
    color = OxmlElement("w:color"); color.set(qn("w:val"), "57606A")
    u = OxmlElement("w:u"); u.set(qn("w:val"), "single")
    sz = OxmlElement("w:sz"); sz.set(qn("w:val"), "18")
    for el in (fonts, color, u, sz):
        rpr.append(el)
    run.append(rpr)
    t = OxmlElement("w:t"); t.text = text
    run.append(t)
    link.append(run)
    p._p.append(link)


def _section(doc, color, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(7)
    _run(p, "■  ", bold=True, color=color, size=11)
    _run(p, text, bold=True, size=12)
    _rule(p, HAIRLINE, 4)
    return p


def _findings_table(doc, cols, rows, marker, lbl):
    t = doc.add_table(rows=1, cols=4)
    t.autofit = True
    _hairlines(t)
    for i, name in enumerate(cols):
        cell = t.rows[0].cells[i]
        cell.text = ""
        _shade(cell, HEADFILL)
        _run(cell.paragraphs[0], name, bold=True, color=SUBINK, size=8.5)
    for row in rows:
        cells = t.add_row().cells
        p = cells[0].paragraphs[0]
        _run(p, "■  ", bold=True, color=marker)
        _run(p, row.get("location", ""), bold=True, size=9)
        # timecode e link do quadro, quando o achado vem de vídeo
        if row.get("timecode"):
            _run(p, f"  {row['timecode']}", color=SUBINK, size=9)
        if row.get("asset_url"):
            _run(p, "  ", size=9)
            _hyperlink(p, row["asset_url"], f"[{lbl['frame']}]")
        for i, key in enumerate(("reads", "should_be", "note"), start=1):
            _run(cells[i].paragraphs[0], row.get(key, ""), color=SUBINK, size=9)
    return t


# ---------------------------------------------------------------- documento
def build(findings: dict, language: str = "en") -> bytes:
    """findings = {
         file, subtitle, coverage, fmt, date, requester, method, report_name,
         errors: [{location, reads, should_be, note, timecode?, asset_url?}],
         consistency: [...],
         clean: [str],
         coverage_notes: [str],
       }
    """
    lbl = LABELS.get(language, LABELS["en"])
    doc = Document()

    style = doc.styles["Normal"]
    style.font.name = FONT
    style.font.size = Pt(10)
    style.font.color.rgb = INK
    style.element.rPr.rFonts.set(qn("w:cs"), FONT)

    for s in doc.sections:
        s.top_margin = s.bottom_margin = Inches(0.7)
        s.left_margin = s.right_margin = Inches(0.75)

    # cabeçalho enxuto
    p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(2)
    _run(p, "ADVISORS CREATIVE DESK", color=SUBINK, size=9)
    _rule(p, ACCENT, 10)

    p = doc.add_paragraph(); p.paragraph_format.space_before = Pt(10)
    _run(p, lbl["title"], bold=True, size=20)

    if findings.get("subtitle"):
        p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(16)
        _run(p, findings["subtitle"], color=SUBINK, size=10, italic=True)

    # ficha
    facts = [(lbl[k], findings.get(k, "")) for k in
             ("file", "coverage", "fmt", "date", "requester", "method")
             if findings.get(k)]
    if facts:
        t = doc.add_table(rows=0, cols=2)
        _hairlines(t, inside_only=True)
        for name, value in facts:
            cells = t.add_row().cells
            _run(cells[0].paragraphs[0], name, bold=True, size=9)
            _run(cells[1].paragraphs[0], str(value), color=SUBINK, size=9)

    errors = findings.get("errors", [])
    consistency = findings.get("consistency", [])
    clean = findings.get("clean", [])
    notes = findings.get("coverage_notes", [])

    # chips do placar
    p = doc.add_paragraph(); p.paragraph_format.space_before = Pt(12)
    for color, count, word in (
        (RED, len(errors), lbl["chips"][0]),
        (AMBER, len(consistency), lbl["chips"][1]),
        (GREEN, len(clean), lbl["chips"][2]),
    ):
        _run(p, "■ ", bold=True, color=color)
        _run(p, f"{count} {word}      ", bold=True, size=10)
    if notes:
        _run(p, "■ ", bold=True, color=SUBINK)
        _run(p, f"{len(notes)} {lbl['chips'][3]}", bold=True, color=SUBINK, size=10)

    # erros
    _section(doc, RED, lbl["errors"])
    if errors:
        _findings_table(doc, lbl["cols"], errors, RED, lbl)
    else:
        p = doc.add_paragraph()
        _run(p, lbl["none"], color=SUBINK, size=9, italic=True)

    # consistência
    if consistency:
        _section(doc, AMBER, lbl["consistency"])
        _findings_table(doc, lbl["cols"], consistency, AMBER, lbl)

    # o que está limpo
    if clean:
        _section(doc, GREEN, lbl["clean"])
        for item in clean:
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.25)
            p.paragraph_format.space_after = Pt(4)
            _run(p, "✓  ", bold=True, color=GREEN)
            _run(p, item, size=9)

    # notas de cobertura
    if notes:
        _section(doc, SUBINK, lbl["notes"])
        for note in notes:
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(4)
            _run(p, note, color=SUBINK, size=9)

    # rodapé com o crédito fixo
    p = doc.add_paragraph(); p.paragraph_format.space_before = Pt(18)
    _rule(p, HAIRLINE, 4)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _run(p, lbl["credit"], color=SUBINK, size=8)

    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()
