#!/usr/bin/env python3
"""score.py TAG [-j N]: score foresight's pages against gnuplot 6.0's.

Rasterizes $W/gp/<page>.svg and $W/fs_TAG/<page>.svg (headless Chrome, 600x400 on white) and scores each page pair by
the mean absolute difference of the two pages as 120x80 grayscale images blurred by 2 px: 0 identical, 1 opposite. A
score is a coarse layout measure (where the ink is), not a pixel comparison: line widths, glyph shapes and anti-aliasing
weigh little, a moved axis, a missing key or a wrong range weighs a lot.

Only the demos listed in $W/fs_TAG/demos.txt (written by run.sh) are scored. A page drawn by one program only scores
1.0 and is flagged `gp only` or `fs only`. Writes $W/scores_TAG.txt, worst first: `score page [flag]`.

$W is $FORESIGHT_FIDELITY (default ~/.cache/foresight-fidelity). Chrome is $FORESIGHT_CHROME, else Playwright's headless
shell under ~/.cache/ms-playwright.
"""

from __future__ import annotations

import glob
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageChops, ImageFilter, ImageStat

W = os.environ.get("FORESIGHT_FIDELITY", os.path.expanduser("~/.cache/foresight-fidelity"))


def chrome() -> str:
    """Path of a headless Chrome."""
    exe = os.environ.get("FORESIGHT_CHROME")
    if exe:
        return exe
    for d in sorted(glob.glob(os.path.expanduser("~/.cache/ms-playwright/chromium_headless_shell-*/*/")), reverse=True):
        for name in ("chrome-headless-shell", "headless_shell"):
            if os.path.exists(d + name):
                return d + name
    sys.exit("score.py: no headless Chrome: set FORESIGHT_CHROME or run `npx playwright install chromium`")


def png(exe: str, svg: str) -> str:
    """Rasterize one SVG page (cached next to it, refreshed when the SVG is newer)."""
    out = svg[:-4] + ".png"
    if not os.path.exists(out) or os.path.getmtime(out) < os.path.getmtime(svg):
        html = svg[:-4] + ".wrap.html"
        with open(html, "w") as f:
            f.write(
                f'<html><body style="margin:0;background:#fff"><img src="{os.path.basename(svg)}" '
                'width="600" height="400"></body></html>'
            )
        subprocess.run(
            [exe, "--no-sandbox", "--disable-gpu", f"--screenshot={out}", "--window-size=600,400", "file://" + html],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
            check=False,
        )
    return out


def small(path: str) -> Image.Image:
    """The page as a blurred 120x80 grayscale image."""
    return Image.open(path).convert("L").filter(ImageFilter.GaussianBlur(2)).resize((120, 80))


def score(exe: str, gp: str, fs: str, page: str) -> tuple[float, str, str]:
    """Score one page pair."""
    a, b = f"{gp}/{page}", f"{fs}/{page}"
    has_a = os.path.exists(a) and os.path.getsize(a) > 0
    has_b = os.path.exists(b) and os.path.getsize(b) > 0
    if not (has_a and has_b):
        return (1.0, page, "gp only" if has_a else "fs only")
    try:
        d = ImageStat.Stat(ImageChops.difference(small(png(exe, a)), small(png(exe, b)))).mean[0] / 255
    except Exception as e:  # noqa: BLE001 - a page that does not rasterize is a score of 1, not a stop
        return (1.0, page, "error " + str(e)[:40])
    return (d, page, "")


def main() -> None:
    """Score every page of the listed demos."""
    tag = sys.argv[1]
    jobs = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[2] == "-j" else os.cpu_count() or 1
    gp, fs = f"{W}/gp", f"{W}/fs_{tag}"
    with open(f"{fs}/demos.txt") as f:
        demos = {line.strip()[:-4] for line in f if line.strip()}
    pages = sorted(
        {
            os.path.basename(p)
            for p in glob.glob(gp + "/*_p*.svg") + glob.glob(fs + "/*_p*.svg")
            if os.path.basename(p).rsplit("_p", 1)[0] in demos
        }
    )
    exe = chrome()
    with ThreadPoolExecutor(jobs) as pool:
        rows = list(pool.map(lambda p: score(exe, gp, fs, p), pages))
    rows.sort(reverse=True)
    with open(f"{W}/scores_{tag}.txt", "w") as f:
        for d, p, n in rows:
            f.write(f"{d:.4f} {p} {n}\n")
    both = [r for r in rows if not r[2]]
    print(
        f"score.py: {len(rows)} pages, {len(both)} drawn by both; total {sum(r[0] for r in rows):.4f}, "
        f"mean of the drawn {sum(r[0] for r in both) / max(1, len(both)):.4f} -> {W}/scores_{tag}.txt"
    )


if __name__ == "__main__":
    main()
