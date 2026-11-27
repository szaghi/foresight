#!/usr/bin/env python3
"""check_math.py [GOLDEN_DIR]: TeX-math labels in foresight's SVG and PDF output as LuaLaTeX sets them (issue #5 G4).

The golden figure math_refs (foresight_golden_test) writes the 40 formulas of src/tests/math_refs.txt as labels at
10 pt, in two columns of 20 (screen x 0.12 and 0.55, rows from screen y 0.95 down by 0.045), left justified. For each
formula, the glyphs drawn near its label are matched with LaTeX's (scripts/gen_math_refs.py) from the formula's
origin, the label's anchor (its baseline 0.35 font size below the anchor point): in math_refs.pdf by character
(PyMuPDF, the embedded fonts' ToUnicode maps), in math_refs.svg by position (the <use> of each glyph); every glyph
within 0.5 pt, as many glyphs as LaTeX's. Exits 1 otherwise.
"""

from __future__ import annotations

import os
import re
import sys

import fitz

TOLERANCE = 0.5  # pt
SIZE_PT = 10.0
PX = 0.75  # pt per px


def references(path: str) -> list[tuple[str, list[tuple[int, float, float]]]]:
    """The formulas and their glyphs (code, x, y up) [pt at 10 pt]."""
    out: list[tuple[str, list[tuple[int, float, float]]]] = []
    with open(path) as f:
        for line in f:
            if line.startswith("F "):
                out.append((line[2:].rstrip("\n"), []))
            elif line.startswith("G "):
                c, x, y = line.split()[1:]
                out[-1][1].append((int(c), float(x), float(y)))
    return out


def anchors(width: float, height: float, n: int) -> list[tuple[float, float]]:
    """Each formula's origin [pt from the top left]: the label anchor, its baseline 0.35 font size lower."""
    out = []
    for k in range(n):
        col, row = divmod(k, 20)
        sx, sy = (0.12, 0.55)[col], 0.95 - 0.045 * row
        out.append((sx * width, (1 - sy) * height + 0.35 * SIZE_PT))
    return out


def match(ref: list[tuple[int, float, float]], got: list[tuple[int, float, float]], by_code: bool) -> tuple[float, str]:
    """The worst distance [pt] of LaTeX's glyphs to foresight's nearest unused (same character if `by_code`)."""
    free = list(got)
    worst = 0.0
    for code, x, y in ref:
        same = [g for g in free if g[0] == code] if by_code else free
        if not same:
            return 99.0, f"no glyph U+{code:04X}"
        best = min(same, key=lambda g: max(abs(g[1] - x), abs(g[2] - y)))
        free.remove(best)
        worst = max(worst, max(abs(best[1] - x), abs(best[2] - y)))
    if free:
        return 99.0, f"{len(free)} glyphs more than LaTeX's"
    return worst, ""


def pdf_glyphs(path: str) -> tuple[list[tuple[int, float, float]], float, float]:
    """The PDF's glyphs (code, x, y from the top) [pt] and its page size."""
    doc = fitz.open(path)
    page = doc[0]
    out = []
    for block in page.get_text("rawdict")["blocks"]:
        for line in block.get("lines", []):
            for span in line["spans"]:
                for c in span["chars"]:
                    if not c["c"].isspace():
                        out.append((ord(c["c"][0]), c["origin"][0], c["origin"][1]))
    return out, page.rect.width, page.rect.height


def svg_glyphs(path: str) -> tuple[list[tuple[int, float, float]], float, float]:
    """The SVG's glyph origins (0, x, y from the top) [pt] (each <use> in its group's translation) and its size."""
    with open(path) as f:
        svg = f.read()
    w = float(re.search(r'<svg[^>]*width="([\d.]+)"', svg).group(1))
    h = float(re.search(r'<svg[^>]*height="([\d.]+)"', svg).group(1))
    out = []
    for gx, gy, body in re.findall(r'<g class="fs-glyphs"[^>]*transform="translate\(([-\d.]+) ([-\d.]+)\)">(.*?)</g>',
                                   svg, re.S):
        for ux, uy in re.findall(r'<use [^>]*transform="translate\(([-\d.]+) ([-\d.]+)\)', body):
            out.append((0, (float(gx) + float(ux)) * PX, (float(gy) + float(uy)) * PX))
    return out, w * PX, h * PX


def main() -> None:
    """Match every formula in both files."""
    golden = sys.argv[1] if len(sys.argv) > 1 else "src/tests/goldens"
    refs = references(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "tests", "math_refs.txt"))
    failed = 0
    for name, by_code in (("math_refs.pdf", True), ("math_refs.svg", False)):
        if name.endswith(".pdf"):
            glyphs, w, h = pdf_glyphs(os.path.join(golden, name))
        else:
            glyphs, w, h = svg_glyphs(os.path.join(golden, name))
        worst_all, bad = 0.0, 0
        for (formula, ref), (ax, ay) in zip(refs, anchors(w, h, len(refs)), strict=True):
            near = [(c, x - ax, ay - y) for c, x, y in glyphs if -2 <= x - ax <= 70 and -14 <= ay - y <= 14]
            worst, why = match(ref, near, by_code)
            worst_all = max(worst_all, worst)
            if worst > TOLERANCE:
                bad += 1
                print(f"FAIL {name} {formula}: {why or f'{worst:.3f} pt'}")
        print(f"{'ok  ' if not bad else 'FAIL'} {name}: {len(refs) - bad}/{len(refs)} formulas within {TOLERANCE} pt "
              f"of LuaLaTeX, worst {worst_all:.3f} pt")
        failed += bad
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
