#!/usr/bin/env python3
"""cairolatex.py FORESIGHT TAG [-j N]: foresight's cairolatex figures against gnuplot 6.0's own (issue #5 step 3.1).

For each demo page of cairolatex_pages.txt (`<demo>_pNN`): the demo copied as pdfcairo.py copies it, but with `set
terminal cairolatex pdf standalone` (one LaTeX file and its graphics per `pause`), run by gnuplot (into $W/tex_gp_lib,
once, "Sans" aliased to Liberation Sans as pdfcairo.py does) and by FORESIGHT (into $W/tex_TAG), each LaTeX file
compiled by LuaLaTeX (the texts set by LaTeX in both), both PDFs rasterized by pdftoppm at 96 dpi and scored as
pdfcairo.py scores them. Writes $W/cairolatex_TAG.txt, worst first; exits 1 when a page scores 0.03 or more, is missing
or does not compile.

$W is $FORESIGHT_FIDELITY (default ~/.cache/foresight-fidelity), prepared by fetch.sh.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

from pdfcairo import LIMIT, W, paged_copy, program_env, score

HERE = os.path.dirname(os.path.abspath(__file__))
TERM = "cairolatex pdf standalone"


def render(program: list[str], demo: str, out: str) -> None:
    """Run `program` on the cairolatex copy of `demo` in a private copy of the demo directory, pages into `out`."""
    with tempfile.TemporaryDirectory() as tmp:
        job = os.path.join(tmp, "demo")
        shutil.copytree(os.path.join(W, "demo"), job)
        script = paged_copy(demo, job, TERM, "tex")
        subprocess.run(program + ["-c", script, out], cwd=job, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=120, check=False, env=program_env(program, tmp))


def compile_tex(tex: str) -> str | None:
    """LuaLaTeX on the standalone `tex` (in its directory): the PDF, or None when it fails."""
    folder, name = os.path.split(tex)
    result = subprocess.run(["lualatex", "-interaction=nonstopmode", "-halt-on-error", name], cwd=folder,
                            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            timeout=120, check=False)
    pdf = tex[:-4] + ".pdf"
    return pdf if result.returncode == 0 and os.path.exists(pdf) else None


def main() -> None:
    """Render, compile, score, report."""
    foresight, tag = os.path.abspath(sys.argv[1]), sys.argv[2]
    jobs = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[3] == "-j" else os.cpu_count() or 1
    with open(os.path.join(HERE, "cairolatex_pages.txt")) as f:
        pages = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    demos = sorted({p.rsplit("_p", 1)[0] for p in pages})
    gp, fs = os.path.join(W, "tex_gp_lib"), os.path.join(W, "tex_" + tag)
    os.makedirs(gp, exist_ok=True)
    os.makedirs(fs, exist_ok=True)
    with ThreadPoolExecutor(jobs) as pool:
        todo = [pool.submit(render, ["gnuplot"], d, gp) for d in demos if not os.path.exists(f"{gp}/{d}_p01.tex")]
        todo += [pool.submit(render, [foresight], d, fs) for d in demos]
        for t in todo:
            t.result()
        pdfs = {}
        for folder in (gp, fs):
            for page in pages:
                tex = f"{folder}/{page}.tex"
                pdfs[tex] = pool.submit(compile_tex, tex) if os.path.exists(tex) else None
        pdfs = {k: (v.result() if v else None) for k, v in pdfs.items()}
    rows = []
    for page in pages:
        a, b = pdfs[f"{gp}/{page}.tex"], pdfs[f"{fs}/{page}.tex"]
        if a is None or b is None:
            rows.append((1.0, page, "missing or not compiled" + (" (gnuplot)" if a is None else "")))
            continue
        rows.append((score(a, b), page, ""))
    rows.sort(reverse=True)
    with open(os.path.join(W, f"cairolatex_{tag}.txt"), "w") as f:
        for d, p, n in rows:
            f.write(f"{d:.4f} {p} {n}\n")
    for d, p, n in rows:
        print(f"{'ok  ' if d < LIMIT else 'FAIL'} {d:.4f} {p} {n}")
    failed = sum(d >= LIMIT for d, _, _ in rows)
    print(f"cairolatex: {len(rows) - failed}/{len(rows)} pages within {LIMIT}, worst {rows[0][0]:.4f}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
