#!/usr/bin/env python3
"""gen_math_refs.py [OUT]: the reference layout of foresight's TeX-math test formulas, set by LuaLaTeX (issue #5 4.1).

Each formula of FORMULAS is set inline (`$...$`, text style) at 10 pt by LuaLaTeX with unicode-math and Latin Modern
Math (the font foresight compiles in), one to a page; `\\savepos` records where the formula starts, PyMuPDF reads back
every glyph's origin and character. Writes OUT (default src/tests/math_refs.txt): per formula a line `F <formula>`,
then one line per glyph `G <code point> <x> <y>`, the origin from the formula's start in TeX points (y up), sizes 10,
7 and 5 pt read back as `S <size>` before the glyphs of that size. foresight_math_test lays the formulas out and checks
each glyph within 0.5 pt of LaTeX's.

Needs lualatex (TeX Live: unicode-math, lm-math) and PyMuPDF (`pip install pymupdf`).
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile

import fitz

FORMULAS = [
    r"x", r"x^2", r"x_i", r"x_i^2", r"e^{-x^2}", r"\alpha+\beta=\gamma", r"\frac{a}{b}", r"\frac{1}{2}",
    r"\frac{x+1}{y-1}", r"\sqrt{x}", r"\sqrt{x^2+y^2}", r"\sqrt{\frac{a}{b}}", r"\sum_{i=1}^{n} x_i",
    r"\int_0^1 f(x)\,dx", r"\partial u/\partial t", r"\nabla\cdot\mathbf{u}=0", r"a\times b", r"x\pm\sigma",
    r"a\le b\ge c", r"\hat{u}", r"\bar{x}", r"\vec{v}", r"\left(\frac{1}{2}\right)", r"\left[x+1\right]",
    r"\mathrm{Re}=\frac{UL}{\nu}", r"\mathbf{F}=m\mathbf{a}", r"E=mc^2", r"\omega_0^2", r"10^{-3}", r"\Delta t",
    r"\Gamma(n)=(n-1)!", r"f'(x)", r"|H(i\omega)|", r"x_{i,j}", r"a^{b^c}", r"\frac{\partial^2 u}{\partial x^2}",
    r"\mathrm{d}x", r"\infty", r"\tau_w=\mu\frac{\partial u}{\partial y}", r"\zeta=0.1",
]
SP_PER_BP = 65536 * 72.27 / 72  # scaled points per big point
PT_PER_BP = 72.27 / 72

DOC = r"""\documentclass[10pt]{article}
\usepackage[paperwidth=8cm,paperheight=4cm,margin=1cm]{geometry}
\usepackage{unicode-math}
\setmainfont{Latin Modern Roman}
\setmathfont{Latin Modern Math}
\pagestyle{empty}
\newwrite\refs
\immediate\openout\refs=positions.txt
\begin{document}
%s
\end{document}
"""


def main() -> None:
    """Typeset, read back, write."""
    out = sys.argv[1] if len(sys.argv) > 1 else "src/tests/math_refs.txt"
    pages = "\n".join(r"\noindent\savepos\write\refs{\the\lastxpos\space\the\lastypos}$" + f + r"$\newpage"
                      for f in FORMULAS)
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, "refs.tex"), "w") as f:
            f.write(DOC % pages)
        subprocess.run(["lualatex", "-interaction=nonstopmode", "-halt-on-error", "refs.tex"], cwd=tmp, check=True,
                       stdout=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
        with open(os.path.join(tmp, "positions.txt")) as f:
            starts = [tuple(int(v) for v in line.split()) for line in f if line.strip()]
        doc = fitz.open(os.path.join(tmp, "refs.pdf"))
        if len(doc) != len(FORMULAS) or len(starts) != len(FORMULAS):
            sys.exit(f"gen_math_refs: {len(doc)} pages, {len(starts)} positions, {len(FORMULAS)} formulas")
        lines = [f"# {len(FORMULAS)} formulas set by LuaLaTeX (unicode-math, Latin Modern Math) at 10 pt: "
                 "scripts/gen_math_refs.py"]
        for formula, page, (sx, sy) in zip(FORMULAS, doc, starts, strict=True):
            x0, y0 = sx / SP_PER_BP, sy / SP_PER_BP  # bp from the bottom left
            height = page.rect.height
            lines.append("F " + formula)
            size = None
            for block in page.get_text("rawdict")["blocks"]:
                for line in block.get("lines", []):
                    for span in line["spans"]:
                        for c in span["chars"]:
                            if c["c"].isspace():
                                continue
                            s = round(span["size"] * PT_PER_BP)
                            if s != size:
                                lines.append(f"S {s}")
                                size = s
                            x = (c["origin"][0] - x0) * PT_PER_BP
                            y = (height - c["origin"][1] - y0) * PT_PER_BP
                            lines.append(f"G {ord(c['c'][0])} {x:.3f} {y:.3f}")
    with open(out, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"gen_math_refs: {out}, {len(FORMULAS)} formulas")


if __name__ == "__main__":
    main()
