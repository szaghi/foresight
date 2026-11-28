#!/usr/bin/env python3
"""pdfcairo.py FORESIGHT TAG [-j N]: foresight's pdfcairo pages against gnuplot 6.0's own (issue #5 step 2.3).

For each demo page of pdfcairo_pages.txt (`<demo>_pNN`): the demo copied as fetch.sh's paged copies are, but with `set
terminal pdfcairo` (gnuplot's defaults: 5 x 3 in, "Sans,12" at fontscale 0.5, 0.5 pt lines) and one PDF page per
`pause`, run by gnuplot (into $W/pdf_gp_lib, once, "Sans" aliased to Liberation Sans: program_env) and by FORESIGHT
(into $W/pdf_TAG), each demo in a private copy of $W/demo. Both PDFs are rasterized by pdftoppm at 96 dpi (one
rasterizer for both) and scored as score.py scores the SVG pages (the mean absolute difference of the blurred 120x80
grayscale pages). Writes $W/pdfcairo_TAG.txt, worst first; exits 1 when a page scores 0.03 or more (or is missing).

$W is $FORESIGHT_FIDELITY (default ~/.cache/foresight-fidelity), prepared by fetch.sh.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageChops, ImageFilter, ImageStat

W = os.environ.get("FORESIGHT_FIDELITY", os.path.expanduser("~/.cache/foresight-fidelity"))
HERE = os.path.dirname(os.path.abspath(__file__))
LIMIT = 0.03
TERM = re.compile(r"^\s*set\s+(term|termi|termin|termina|terminal)\b(?!option)")
PAUSE = re.compile(r"^\s*pause\b")


def paged_copy(demo: str, demodir: str, term: str = "pdfcairo", ext: str = "pdf") -> str:
    """The demo as a copy for `term` writing ARG1/<name>_pNN.<ext>, one page per pause: its file name."""
    with open(os.path.join(demodir, demo + ".dem"), errors="replace") as f:
        src = f.read().split("\n")
    lines = [f"set terminal {term}", "FID_N = 1", "FID_DIR = ARG1",
             f"set output sprintf('%s/{demo}_p%02d.{ext}', FID_DIR, FID_N)"]
    cont = False
    for line in src:
        if not cont and TERM.match(line):
            lines.append("# " + line)
        elif not cont and PAUSE.match(line):
            lines.append(f"FID_N = FID_N + 1; set output sprintf('%s/{demo}_p%02d.{ext}', FID_DIR, FID_N)")
        else:
            lines.append(line)
        cont = line.rstrip().endswith("\\")
    lines.append("set output")
    name = ext + "_" + demo + ".dem"
    with open(os.path.join(demodir, name), "w") as f:
        f.write("\n".join(lines) + "\n")
    return name


def program_env(program: list[str], tmp: str) -> dict[str, str]:
    """The environment of `program`: gnuplot's cairo terminals measure and draw "Sans" as Liberation Sans (a fontconfig
    alias, placement.py's), the font foresight lays out with and embeds; the system's "Sans" differs from machine to
    machine (Noto Sans, DejaVu Sans) and with it gnuplot's character cell."""
    env = dict(os.environ)
    if os.path.basename(program[0]) == "gnuplot":
        from placement import FONTCONF

        conf = os.path.join(tmp, "fonts.conf")
        with open(conf, "w") as f:
            f.write(FONTCONF)
        env["FONTCONFIG_FILE"] = conf
    return env


def render(program: list[str], demo: str, out: str) -> None:
    """Run `program` on the pdfcairo copy of `demo` in a private copy of the demo directory, pages into `out`."""
    with tempfile.TemporaryDirectory() as tmp:
        job = os.path.join(tmp, "demo")
        shutil.copytree(os.path.join(W, "demo"), job)
        script = paged_copy(demo, job)
        subprocess.run(program + ["-c", script, out], cwd=job, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=120, check=False, env=program_env(program, tmp))


def score(a: str, b: str) -> float:
    """The fidelity score of two PDF pages, rasterized at 96 dpi."""
    with tempfile.TemporaryDirectory() as tmp:
        images = []
        for k, pdf in enumerate((a, b)):
            subprocess.run(["pdftoppm", "-r", "96", "-png", "-singlefile", pdf, os.path.join(tmp, str(k))], check=True)
            images.append(Image.open(os.path.join(tmp, f"{k}.png")).convert("L"))
        size = images[0].size
        small = [im.resize(size).filter(ImageFilter.GaussianBlur(2)).resize((120, 80)) for im in images]
        return ImageStat.Stat(ImageChops.difference(small[0], small[1])).mean[0] / 255


def main() -> None:
    """Render, score, report."""
    foresight, tag = os.path.abspath(sys.argv[1]), sys.argv[2]
    jobs = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[3] == "-j" else os.cpu_count() or 1
    with open(os.path.join(HERE, "pdfcairo_pages.txt")) as f:
        pages = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    demos = sorted({p.rsplit("_p", 1)[0] for p in pages})
    gp, fs = os.path.join(W, "pdf_gp_lib"), os.path.join(W, "pdf_" + tag)
    os.makedirs(gp, exist_ok=True)
    os.makedirs(fs, exist_ok=True)
    with ThreadPoolExecutor(jobs) as pool:
        todo = [pool.submit(render, ["gnuplot"], d, gp) for d in demos if not os.path.exists(f"{gp}/{d}_p01.pdf")]
        todo += [pool.submit(render, [foresight], d, fs) for d in demos]
        for t in todo:
            t.result()
    rows = []
    for page in pages:
        a, b = f"{gp}/{page}.pdf", f"{fs}/{page}.pdf"
        if not (os.path.exists(a) and os.path.exists(b)):
            rows.append((1.0, page, "missing"))
            continue
        rows.append((score(a, b), page, ""))
    rows.sort(reverse=True)
    with open(os.path.join(W, f"pdfcairo_{tag}.txt"), "w") as f:
        for d, p, n in rows:
            f.write(f"{d:.4f} {p} {n}\n")
    for d, p, n in rows:
        print(f"{'ok  ' if d < LIMIT else 'FAIL'} {d:.4f} {p} {n}")
    failed = sum(d >= LIMIT for d, _, _ in rows)
    print(f"pdfcairo: {len(rows) - failed}/{len(rows)} pages within {LIMIT}, worst {rows[0][0]:.4f}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
