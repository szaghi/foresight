#!/usr/bin/env python3
"""check_cairolatex.py [GOLDEN_DIR]: each text of foresight's LaTeX pictures where its device would draw it (issue #5 3.1).

For each LaTeX picture golden NAME.tex with an SVG golden NAME.svg of the same figure (lines, annotations,
histograms): every `\\put` of the picture is matched with an SVG text of the same characters (math `$` and LaTeX's
`\\strut{}`, `\\times` and escapes read back), and must lie at that text's center, the SVG anchor raised by 0.35 font
size (rotated with it), in 0.05 bp from the bottom left: within 0.1 bp on both axes. The counts must agree. Exits 1 on
any mismatch.
"""

from __future__ import annotations

import html
import math
import os
import re
import sys

PUT = re.compile(r"\\put\((-?\d+),(-?\d+)\)\{(\\rotatebox\{-?[\d.]+\}\{)?\\makebox\(0,0\)(?:\[[lr]\])?")
TEXT = re.compile(r"<text([^>]*)>(.*?)</text>", re.S)
ATTR = re.compile(r'([\w-]+)="([^"]*)"')
NAMES = ["lines", "annotations", "histograms"]
TOLERANCE = 2  # 0.1 bp in 0.05 bp units


def tex_plain(text: str) -> str:
    """The characters of a LaTeX label as the SVG shows them."""
    text = text.replace("\\strut{}", "").replace("\\times", "\u00d7")
    text = re.sub(r"\^\{([^}]*)\}", r"\1", text)
    text = re.sub(r"\\([#$%^&_{}\\])", r"\1", text)
    return text.replace("$", "").replace("-", "\u2212")


def svg_plain(text: str) -> str:
    """The characters of an SVG text (its tspans' text joined)."""
    return html.unescape(re.sub(r"<[^>]+>", "", text)).replace("-", "\u2212")


def puts(path: str) -> list[tuple[int, int, str]]:
    """The `\\put`s of a LaTeX picture: x, y [0.05 bp], plain text."""
    out = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            m = PUT.search(line)
            if m:
                # the box's text: the rest less `}%` (the put), `}` (a rotatebox) and the box's braces
                rest = line[m.end():-2]
                if m.group(3):
                    rest = rest[:-1]
                out.append((int(m.group(1)), int(m.group(2)), tex_plain(rest[1:-1])))
    return out


def anchors(path: str) -> list[tuple[float, float, str]]:
    """The expected `\\put` of each SVG text: its center from the bottom left [0.05 bp], plain text."""
    with open(path) as f:
        svg = f.read()
    root = dict(ATTR.findall(re.search(r"<svg[^>]*>", svg).group(0)))
    height, size0 = float(root["height"]), float(root.get("font-size", "12"))
    out = []
    for attrs, body in TEXT.findall(svg):
        a = dict(ATTR.findall(attrs))
        if "x" not in a or "y" not in a:
            continue
        x, y, size = float(a["x"]), float(a["y"]), float(a.get("font-size", size0))
        angle = 0.0
        rot = re.search(r"rotate\((-?[\d.]+)", a.get("transform", ""))
        if rot:
            angle = math.radians(float(rot.group(1)))
        cx = x + 0.35 * size * math.sin(angle)
        cy = height - y + 0.35 * size * math.cos(angle)
        out.append((20 * 0.75 * cx, 20 * 0.75 * cy, svg_plain(body)))
    return out


def main() -> None:
    """Match, report, exit."""
    golden = sys.argv[1] if len(sys.argv) > 1 else "src/tests/goldens"
    failed = 0
    for name in NAMES:
        p, s = puts(os.path.join(golden, name + ".tex")), anchors(os.path.join(golden, name + ".svg"))
        worst, bad = 0.0, []
        if len(p) != len(s):
            bad.append(f"{len(p)} puts, {len(s)} SVG texts")
        free = list(s)
        for x, y, text in p:
            same = [t for t in free if t[2] == text]
            if not same:
                bad.append(f"no SVG text {text!r}")
                continue
            best = min(same, key=lambda t: max(abs(t[0] - x), abs(t[1] - y)))
            free.remove(best)
            d = max(abs(best[0] - x), abs(best[1] - y))
            worst = max(worst, d)
            if d > TOLERANCE:
                bad.append(f"{text!r} at ({x},{y}), expected ({best[0]:.1f},{best[1]:.1f})")
        status = "ok  " if not bad else "FAIL"
        print(f"{status} {name}: {len(p)} texts, worst {worst / 20:.3f} bp" + ("; " + "; ".join(bad[:5]) if bad else ""))
        failed += bool(bad)
    print(f"check_cairolatex: {len(NAMES) - failed}/{len(NAMES)} pictures, every text within 0.1 bp")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
