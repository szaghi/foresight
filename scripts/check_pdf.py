#!/usr/bin/env python3
"""check_pdf.py [GOLDEN_DIR]: check the PDF goldens (src/tests/goldens/*.pdf).

For each NAME.pdf:
- `qpdf --check` passes;
- `pdffonts` lists every font embedded, with its Unicode map;
- the text `pdftotext` extracts is the text of the SVG golden of the same figure (NAME.svg: the contents of its <text>
  elements, hover titles left out), compared as the multiset of their non-blank characters (the two programs split
  and order runs differently: sub- and superscripts, rotated labels);
- when NAME_glyphs.svg exists (the same figure, its texts drawn from the glyphs: `fontglyphs`), the PDF and that SVG
  rasterized differ by less than 0.002 (the fidelity score of scripts/fidelity/score.py: the mean absolute difference
  of the blurred 120x80 grayscale pages). Both are rasterized by the same headless Chrome, the PDF's drawing converted
  to SVG by `pdftocairo -svg` (geometry unchanged): poppler's own rasterizer snaps thin strokes to whole pixels where
  Chrome antialiases them, a difference of 0.001-0.002 by itself (two PDF rasterizers on one file differ as much).
Exits 1 when a file fails, after reporting every file. Chrome is $FORESIGHT_CHROME, else Playwright's headless shell.
"""

from __future__ import annotations

import collections
import glob
import html
import os
import re
import subprocess
import sys
import tempfile

RASTER_LIMIT = 0.002


def svg_text(path: str) -> str:
    """The characters of the texts of an SVG page."""
    with open(path, encoding="utf-8") as f:
        page = f.read()
    page = re.sub(r"<title>.*?</title>", "", page, flags=re.S)
    texts = re.findall(r"<text\b[^>]*>(.*?)</text>", page, flags=re.S)
    return html.unescape("".join(re.sub(r"<[^>]+>", "", t) for t in texts))


def pdf_text(path: str) -> str:
    """The characters pdftotext extracts."""
    return subprocess.run(["pdftotext", "-q", path, "-"], capture_output=True, text=True, check=True).stdout


def chars(text: str) -> collections.Counter:
    """Multiset of the non-blank characters."""
    return collections.Counter(c for c in text if not c.isspace())


def fonts_embedded(path: str) -> tuple[bool, str]:
    """Whether pdffonts lists every font embedded with its Unicode map (and no warning)."""
    run = subprocess.run(["pdffonts", path], capture_output=True, text=True, check=False)
    rows = run.stdout.splitlines()[2:]
    bad = [r for r in rows if len(r.split()) < 5 or r.split()[-5] != "yes" or r.split()[-3] != "yes"]
    ok = run.returncode == 0 and not run.stderr.strip() and not bad
    return ok, f"{len(rows)} fonts" + ("" if ok else f" ({run.stderr.strip()[:80]} {bad[:2]})")


def chrome() -> str:
    """Path of a headless Chrome."""
    exe = os.environ.get("FORESIGHT_CHROME")
    if exe:
        return exe
    for d in sorted(glob.glob(os.path.expanduser("~/.cache/ms-playwright/chromium_headless_shell-*/*/")), reverse=True):
        for name in ("chrome-headless-shell", "headless_shell"):
            if os.path.exists(d + name):
                return d + name
    sys.exit("check_pdf.py: no headless Chrome: set FORESIGHT_CHROME or run `npx playwright install chromium`")


def shot(page: str, png: str, width: int, height: int) -> None:
    """Rasterize the HTML `page` into `png` with a headless Chrome."""
    subprocess.run([chrome(), "--no-sandbox", "--disable-gpu", "--allow-file-access-from-files", f"--screenshot={png}",
                    f"--window-size={width},{height}", "file://" + page],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60, check=False)


def raster_score(pdf: str, svg: str) -> float:
    """The fidelity score between the PDF and the SVG of the same figure."""
    from PIL import Image, ImageChops, ImageFilter, ImageStat

    with open(svg, encoding="utf-8") as f:
        head = f.read(4096)
    width = int(float(re.search(r'<svg[^>]*\bwidth="([0-9.]+)"', head).group(1)))
    height = int(float(re.search(r'<svg[^>]*\bheight="([0-9.]+)"', head).group(1)))
    with tempfile.TemporaryDirectory() as tmp:
        page = os.path.join(tmp, "page.html")
        with open(page, "w") as f:
            f.write(f'<html><body style="margin:0;background:#fff"><img src="file://{os.path.abspath(svg)}" '
                    f'width="{width}" height="{height}"></body></html>')
        svg_png = os.path.join(tmp, "svg.png")
        shot(page, svg_png, width, height)
        drawing = os.path.join(tmp, "pdf.svg")
        subprocess.run(["pdftocairo", "-svg", pdf, drawing], check=True)
        page = os.path.join(tmp, "pdfpage.html")
        with open(page, "w") as f:
            f.write(f'<html><body style="margin:0;background:#fff"><img src="file://{drawing}" '
                    f'width="{width}" height="{height}"></body></html>')
        shot(page, os.path.join(tmp, "pdf.png"), width, height)

        def small(path: str) -> Image.Image:
            img = Image.open(path).convert("L").resize((width, height))
            return img.filter(ImageFilter.GaussianBlur(2)).resize((120, 80))

        return ImageStat.Stat(ImageChops.difference(small(svg_png), small(os.path.join(tmp, "pdf.png")))).mean[0] / 255


def main() -> None:
    """Check every PDF golden."""
    golden_dir = sys.argv[1] if len(sys.argv) > 1 else "src/tests/goldens"
    files = sorted(glob.glob(os.path.join(golden_dir, "*.pdf")))
    failed = 0
    for pdf in files:
        name = os.path.basename(pdf)
        notes = []
        check = subprocess.run(["qpdf", "--check", pdf], capture_output=True, text=True, check=False)
        ok = check.returncode == 0 and "No syntax or stream encoding errors" in check.stdout
        if not ok:
            notes.append("qpdf: " + (check.stdout + check.stderr).strip().replace("\n", " | ")[:200])
        embedded, fonts = fonts_embedded(pdf)
        notes.append(fonts)
        if not embedded:
            ok = False
            notes.append("NOT ALL EMBEDDED")
        expected, got = chars(svg_text(pdf[:-4] + ".svg")), chars(pdf_text(pdf))
        notes.append(f"{sum(got.values())} characters")
        if expected != got:
            ok = False
            notes.append(f"missing {dict(expected - got)} extra {dict(got - expected)}")
        glyphs = pdf[:-4] + "_glyphs.svg"
        if os.path.exists(glyphs):
            score = raster_score(pdf, glyphs)
            notes.append(f"raster against {os.path.basename(glyphs)} {score:.5f}")
            if score >= RASTER_LIMIT:
                ok = False
        print(f"{'ok' if ok else 'FAIL'} {name}: " + ", ".join(notes))
        failed += not ok
    print(f"check_pdf: {len(files) - failed}/{len(files)} PDF goldens pass")
    sys.exit(1 if failed or not files else 0)


if __name__ == "__main__":
    main()
