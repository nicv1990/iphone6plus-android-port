#!/usr/bin/env python3
"""Small dependency-free Markdown-ish to PDF renderer for project reports."""

from __future__ import annotations

import argparse
import re
import textwrap
from pathlib import Path


PAGE_W = 612
PAGE_H = 792
MARGIN = 54
BODY_SIZE = 10
H1_SIZE = 18
H2_SIZE = 14
H3_SIZE = 12
LINE_H = 13
CODE_LINE_H = 11


def pdf_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def strip_inline_md(text: str) -> str:
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\*\*([^*]*)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]*)\*", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1 (\2)", text)
    return text


class Pdf:
    def __init__(self, title: str):
        self.title = title
        self.pages: list[list[tuple[str, int, str, float]]] = [[]]
        self.y = PAGE_H - MARGIN

    def new_page(self) -> None:
        self.pages.append([])
        self.y = PAGE_H - MARGIN

    def ensure(self, height: float) -> None:
        if self.y - height < MARGIN:
            self.new_page()

    def add_line(self, text: str, size: int = BODY_SIZE, font: str = "F1",
                 leading: float = LINE_H) -> None:
        self.ensure(leading)
        self.pages[-1].append((font, size, text, self.y))
        self.y -= leading

    def add_gap(self, height: float = 6) -> None:
        self.ensure(height)
        self.y -= height

    def write(self, output: Path) -> None:
        objects: list[bytes] = []

        def add(obj: bytes) -> int:
            objects.append(obj)
            return len(objects)

        font_helv = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
        font_bold = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
        font_cour = add(b"<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>")

        page_ids = []
        content_ids = []
        for page in self.pages:
            commands = ["BT"]
            for font, size, text, y in page:
                commands.append(f"/{font} {size} Tf")
                commands.append(f"1 0 0 1 {MARGIN} {y:.2f} Tm")
                commands.append(f"({pdf_escape(text)}) Tj")
            commands.append("ET")
            stream = "\n".join(commands).encode("utf-8")
            content_ids.append(add(
                b"<< /Length " + str(len(stream)).encode("ascii") +
                b" >>\nstream\n" + stream + b"\nendstream"
            ))
            page_ids.append(add(b""))

        pages_id = len(objects) + 1
        for idx, page_id in enumerate(page_ids):
            page_obj = (
                f"<< /Type /Page /Parent {pages_id} 0 R "
                f"/MediaBox [0 0 {PAGE_W} {PAGE_H}] "
                f"/Resources << /Font << /F1 {font_helv} 0 R /F2 {font_bold} 0 R /F3 {font_cour} 0 R >> >> "
                f"/Contents {content_ids[idx]} 0 R >>"
            ).encode("ascii")
            objects[page_id - 1] = page_obj

        kids = " ".join(f"{pid} 0 R" for pid in page_ids)
        pages_id = add(f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>".encode("ascii"))
        catalog_id = add(f"<< /Type /Catalog /Pages {pages_id} 0 R >>".encode("ascii"))
        info_id = add(
            f"<< /Title ({pdf_escape(self.title)}) /Producer (iphone6plus-android-port render_markdown_pdf.py) >>".encode("utf-8")
        )

        out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
        offsets = [0]
        for i, obj in enumerate(objects, start=1):
            offsets.append(len(out))
            out.extend(f"{i} 0 obj\n".encode("ascii"))
            out.extend(obj)
            out.extend(b"\nendobj\n")

        xref = len(out)
        out.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
        out.extend(b"0000000000 65535 f \n")
        for off in offsets[1:]:
            out.extend(f"{off:010d} 00000 n \n".encode("ascii"))
        out.extend(
            f"trailer << /Size {len(objects) + 1} /Root {catalog_id} 0 R /Info {info_id} 0 R >>\n"
            f"startxref\n{xref}\n%%EOF\n".encode("ascii")
        )
        output.write_bytes(out)


def render_markdown(input_path: Path, output_path: Path) -> None:
    pdf = Pdf(input_path.stem.replace("_", " "))
    in_code = False

    for raw in input_path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()

        if line.startswith("```"):
            in_code = not in_code
            pdf.add_gap(4)
            continue

        if not line:
            pdf.add_gap(5)
            continue

        if in_code:
            for wrapped in textwrap.wrap(line, width=92, replace_whitespace=False,
                                         drop_whitespace=False) or [""]:
                pdf.add_line(wrapped, size=8, font="F3", leading=CODE_LINE_H)
            continue

        if line.startswith("# "):
            pdf.add_gap(6)
            pdf.add_line(strip_inline_md(line[2:]), size=H1_SIZE, font="F2", leading=22)
            pdf.add_gap(4)
            continue
        if line.startswith("## "):
            pdf.add_gap(8)
            pdf.add_line(strip_inline_md(line[3:]), size=H2_SIZE, font="F2", leading=18)
            pdf.add_gap(3)
            continue
        if line.startswith("### "):
            pdf.add_gap(6)
            pdf.add_line(strip_inline_md(line[4:]), size=H3_SIZE, font="F2", leading=16)
            continue

        text = strip_inline_md(line)
        indent = "  " if text.lstrip().startswith(("-", "*")) else ""
        for wrapped in textwrap.wrap(text, width=86):
            pdf.add_line(indent + wrapped, size=BODY_SIZE, font="F1", leading=LINE_H)

    pdf.write(output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    render_markdown(args.input, args.output)


if __name__ == "__main__":
    main()
