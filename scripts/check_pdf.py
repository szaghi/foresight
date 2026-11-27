#!/usr/bin/env python3
"""check_pdf.py [GOLDEN_DIR]: check the PDF goldens (src/tests/goldens/*.pdf).

For each NAME.pdf: `qpdf --check` passes, and the text `pdftotext` extracts is the text of the SVG golden of the same
figure (NAME.svg: the contents of its <text> elements, hover titles left out), compared as the multiset of their
non-blank characters (the two programs split and order runs differently: sub- and superscripts, rotated labels).
Exits 1 on the first kind of failure, after reporting every file.
"""

from __future__ import annotations

import collections
import glob
import html
import os
import re
import subprocess
import sys


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


def main() -> None:
    """Check every PDF golden."""
    golden_dir = sys.argv[1] if len(sys.argv) > 1 else "src/tests/goldens"
    files = sorted(glob.glob(os.path.join(golden_dir, "*.pdf")))
    failed = 0
    for pdf in files:
        name = os.path.basename(pdf)
        check = subprocess.run(["qpdf", "--check", pdf], capture_output=True, text=True, check=False)
        qpdf_ok = check.returncode == 0 and "No syntax or stream encoding errors" in check.stdout
        svg = pdf[:-4] + ".svg"
        expected, got = chars(svg_text(svg)), chars(pdf_text(pdf))
        text_ok = expected == got
        status = "ok" if qpdf_ok and text_ok else "FAIL"
        detail = ""
        if not text_ok:
            detail = f" missing {dict(expected - got)} extra {dict(got - expected)}"
        if not qpdf_ok:
            detail += " qpdf: " + (check.stdout + check.stderr).strip().replace("\n", " | ")[:200]
        print(f"{status} {name}: qpdf {'ok' if qpdf_ok else 'FAILED'}, {sum(got.values())} characters{detail}")
        failed += status != "ok"
    print(f"check_pdf: {len(files) - failed}/{len(files)} PDF goldens pass")
    sys.exit(1 if failed or not files else 0)


if __name__ == "__main__":
    main()
