from pathlib import Path
from xml.sax.saxutils import escape

from docx import Document
from docx.table import Table as DocxTable
from docx.text.paragraph import Paragraph as DocxParagraph
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    LongTable,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    TableStyle,
)


ROOT = Path(r"C:\Users\User\Documents\GitHub\collab")
SOURCE = ROOT / "output" / "report" / "Visit_1MY_Module_5_Report_Draft.docx"
OUTPUT = ROOT / "output" / "pdf" / "Visit_1MY_Module_5_Report_Draft.pdf"


def iter_blocks(parent):
    body = parent.element.body
    for child in body.iterchildren():
        if child.tag.endswith("}p"):
            yield DocxParagraph(child, parent)
        elif child.tag.endswith("}tbl"):
            yield DocxTable(child, parent)


class ReportDocTemplate(BaseDocTemplate):
    def __init__(self, filename, **kwargs):
        super().__init__(filename, **kwargs)
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="body",
            leftPadding=0,
            rightPadding=0,
            topPadding=0,
            bottomPadding=0,
        )
        self.addPageTemplates(PageTemplate(id="main", frames=[frame], onPage=self.draw_page))

    def draw_page(self, canvas, doc):
        canvas.saveState()
        canvas.setFont("Times-Roman", 8)
        canvas.setFillColor(colors.HexColor("#666666"))
        canvas.drawCentredString(
            A4[0] / 2,
            0.9 * cm,
            f"BMSE3004 Collaborative Development | Visit 1MY Module 5 | Page {doc.page}",
        )
        canvas.restoreState()


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="ReportTitle",
        parent=styles["Title"],
        fontName="Times-Bold",
        fontSize=18,
        leading=22,
        textColor=colors.black,
        alignment=TA_CENTER,
        spaceAfter=12,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportHeading1",
        parent=styles["Heading1"],
        fontName="Times-Bold",
        fontSize=14,
        leading=17,
        textColor=colors.black,
        spaceBefore=11,
        spaceAfter=7,
        keepWithNext=True,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportHeading2",
        parent=styles["Heading2"],
        fontName="Times-Bold",
        fontSize=12,
        leading=15,
        textColor=colors.black,
        spaceBefore=9,
        spaceAfter=5,
        keepWithNext=True,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportBody",
        parent=styles["BodyText"],
        fontName="Times-Roman",
        fontSize=10.5,
        leading=13.4,
        textColor=colors.black,
        alignment=TA_JUSTIFY,
        spaceAfter=4.5,
        allowWidows=0,
        allowOrphans=0,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportCentered",
        parent=styles["ReportBody"],
        alignment=TA_CENTER,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportList",
        parent=styles["ReportBody"],
        leftIndent=16,
        firstLineIndent=-12,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="ReportCode",
        fontName="Courier",
        fontSize=6.7,
        leading=8.2,
        leftIndent=12,
        rightIndent=4,
        spaceBefore=3,
        spaceAfter=8,
        textColor=colors.black,
    )
)
styles.add(
    ParagraphStyle(
        name="Cell",
        fontName="Times-Roman",
        fontSize=7.8,
        leading=9.4,
        alignment=TA_LEFT,
        textColor=colors.black,
    )
)
styles.add(
    ParagraphStyle(
        name="CellCenter",
        parent=styles["Cell"],
        fontName="Times-Bold",
        alignment=TA_CENTER,
    )
)
styles.add(
    ParagraphStyle(
        name="CellHeader",
        parent=styles["CellCenter"],
        fontSize=8.2,
        leading=9.8,
    )
)


def paragraph_markup(paragraph):
    parts = []
    for run in paragraph.runs:
        text = escape(run.text).replace("\n", "<br/>")
        if not text:
            continue
        if run.bold:
            text = f"<b>{text}</b>"
        if run.italic:
            text = f"<i>{text}</i>"
        parts.append(text)
    return "".join(parts) or escape(paragraph.text)


source_doc = Document(SOURCE)
story = []
number_counter = 0
previous_was_number = False


def build_requirements_table(rows):
    table = LongTable(
        rows,
        colWidths=[2.0 * cm, 2.3 * cm, 12.0 * cm],
        repeatRows=1,
        hAlign="CENTER",
    )
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#D9D9D9")),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#D9E2F3")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for row_index in range(2, len(rows), 2):
        commands.append(("BACKGROUND", (0, row_index), (-1, row_index), colors.HexColor("#F7F9FC")))
    table.setStyle(TableStyle(commands))
    return table

for block in iter_blocks(source_doc):
    if isinstance(block, DocxParagraph):
        text = block.text
        has_page_break = 'w:type="page"' in block._p.xml
        if has_page_break:
            story.append(PageBreak())
            previous_was_number = False
            continue
        if not text.strip():
            story.append(Spacer(1, 3))
            previous_was_number = False
            continue
        style_name = block.style.name if block.style else "Normal"
        if style_name == "Title":
            story.append(Paragraph(paragraph_markup(block), styles["ReportTitle"]))
            previous_was_number = False
        elif style_name == "Heading 1":
            story.append(Paragraph(paragraph_markup(block), styles["ReportHeading1"]))
            previous_was_number = False
        elif style_name in ("Heading 2", "Heading 3"):
            story.append(Paragraph(paragraph_markup(block), styles["ReportHeading2"]))
            previous_was_number = False
        elif style_name == "List Number":
            if not previous_was_number:
                number_counter = 0
            number_counter += 1
            story.append(Paragraph(f"{number_counter}. {escape(text)}", styles["ReportList"]))
            previous_was_number = True
        elif style_name == "List Bullet":
            story.append(Paragraph(f"- {escape(text)}", styles["ReportList"]))
            previous_was_number = False
        elif any((run.font.name or "") == "Consolas" for run in block.runs):
            story.append(Preformatted(text, styles["ReportCode"], maxLineLength=105))
            previous_was_number = False
        else:
            alignment = block.alignment
            chosen = styles["ReportCentered"] if alignment == 1 else styles["ReportBody"]
            story.append(Paragraph(paragraph_markup(block), chosen))
            previous_was_number = False
    else:
        rows = []
        for row_index, row in enumerate(block.rows):
            formatted = []
            for col_index, cell in enumerate(row.cells):
                text = "<br/>".join(escape(p.text) for p in cell.paragraphs if p.text)
                style = styles["CellHeader"] if row_index == 0 else (
                    styles["CellCenter"] if col_index < 2 else styles["Cell"]
                )
                formatted.append(Paragraph(text, style))
            rows.append(formatted)
        story.append(Spacer(1, 4))
        if len(rows) > 20:
            story.append(build_requirements_table(rows[:20]))
            story.append(PageBreak())
            story.append(Paragraph("B3 Functional Requirements Continued", styles["ReportHeading2"]))
            story.append(build_requirements_table([rows[0], *rows[20:]]))
        else:
            story.append(build_requirements_table(rows))
        story.append(Spacer(1, 8))
        previous_was_number = False

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
pdf = ReportDocTemplate(
    str(OUTPUT),
    pagesize=A4,
    leftMargin=2.1 * cm,
    rightMargin=2.1 * cm,
    topMargin=1.8 * cm,
    bottomMargin=1.6 * cm,
    title="Visit 1MY Module 5 Report Draft Content",
    author="HO JUN JIE",
    subject="BMSE3004 Collaborative Development",
)
pdf.build(story)
print(OUTPUT)
