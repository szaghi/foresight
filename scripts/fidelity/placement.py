#!/usr/bin/env python3
"""placement.py [options]: where foresight puts each 2D text, against gnuplot 6.0, with equal plot areas (issue #6).

Each probe of scripts/fidelity/placement/*.gp is run by gnuplot and by foresight through two terminals, `svg size
600,400` and `cairolatex pdf input size 5in,3in`, with the same fixed screen margins (MARGINS, or the probe's), so both programs draw
the same plot area and every difference left is a text placement rule. The texts of both outputs are matched by their
content (the nearest one when a content repeats) and each pair's offset is reported, foresight's position less
gnuplot's: svg in px (the baseline anchor of the <text>), cairolatex in bp (the \\put point), dy positive downward.

A probe's first lines may hold options:
  #! font: N        the terminal font size (default: the terminal's own, 12 for svg and 11 for cairolatex)
  #! margins: L R B T  the border at these fractions of the canvas (default MARGINS)
  #! fonts: system  gnuplot's cairo terminals measure with the system's "Sans"; without it they measure with
                    Liberation Sans (a fontconfig alias), the font foresight lays its texts out with

Options:
  --foresight BIN   foresight's command line tool (default bin/foresight)
  --probe NAME      only this probe (repeatable; the name without .gp)
  --term T          only this terminal: svg or cairolatex (repeatable)
  --write FILE      write the table to FILE (scripts/fidelity/baseline/placement.txt is the committed one)
  --explain         attribute each offset to a width or a placement rule (see explain())
  --kinds K,K       only these kinds of text (title, xlabel, ylabel, x2label, y2label, xtic, ytic, x2tic, y2tic,
                    key, keytitle, label)
  --check           exit 1 when a text not driven by a width is off by more than LIMIT (0.5 px, 0.1 bp), or a
                    width-driven one by more than LIMIT beyond its width difference

Exits 1 when a text is found in one output only (or --check fails).
"""

from __future__ import annotations

import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PROBES = os.path.join(HERE, "placement")
MARGINS = (0.18, 0.85, 0.22, 0.75)  # left, right, bottom, top border, fractions of the canvas (gnuplot `at screen`)
TERMS = {"svg": ("svg size 600,400", "svg", 12.0), "cairolatex": ("cairolatex pdf input size 5in,3in", "tex", 11.0)}
UNITS = {"svg": "px", "cairolatex": "bp"}
LIMIT = {"svg": 0.5, "cairolatex": 0.1}
FONTCONF = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <match target="pattern">
    <test name="family"><string>Sans</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Liberation Sans</string></edit>
  </match>
  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Liberation Sans</string></edit>
  </match>
</fontconfig>
"""


@dataclass
class Text:
    """A text drawn: its content, anchor point (svg px, y down; cairolatex bp, y down), anchor and angle."""

    text: str
    x: float
    y: float
    anchor: str
    angle: float
    raw: str = ""


@dataclass
class Row:
    """A text of gnuplot's matched with foresight's: the probe, terminal, kind and offset."""

    probe: str
    term: str
    text: str
    kind: str
    dx: float
    dy: float
    note: str
    gx: float = 0.0
    gy: float = 0.0
    raw: str = ""


def raw(text: str) -> str:
    """The characters of a text as gnuplot counts them: without markup and math delimiters, its spaces kept."""
    text = re.sub(r"<[^>]+>", "", text)
    return html.unescape(text).replace("\\strut{}", "").replace("$", "")


def clean(text: str) -> str:
    """The content of a text without markup, math delimiters and spaces at its ends."""
    return re.sub(r"\s+", " ", raw(text)).strip()


def svg_texts(path: str, gnuplot: bool) -> list[Text]:
    """The texts of an SVG file: gnuplot's <g transform="translate(..)"><text>, foresight's <text x y>."""
    with open(path, errors="replace") as f:
        s = f.read()
    out = []
    if gnuplot:
        for m in re.finditer(r'<g transform="translate\(([-\d.]+),([-\d.]+)\)(?: rotate\((-?[\d.]+)\))?"([^>]*)>\s*'
                             r"<text[^>]*>(.*?)</text>", s, re.S):
            anchor = re.search(r'text-anchor="(\w+)"', m.group(4))
            out.append(Text(clean(m.group(5)), float(m.group(1)), float(m.group(2)),
                            anchor.group(1) if anchor else "start", -float(m.group(3) or 0.0), raw(m.group(5))))
        return [t for t in out if t.text]
    for m in re.finditer(r"<text([^>]*)>(.*?)</text>", s, re.S):
        a = m.group(1)
        x, y = re.search(r'\bx="([-\d.]+)"', a), re.search(r'\by="([-\d.]+)"', a)
        tr = re.search(r'translate\(([-\d.]+)[ ,]([-\d.]+)\)', a)
        rot = re.search(r"rotate\((-?[\d.]+)", a)
        anchor = re.search(r'text-anchor="(\w+)"', a)
        if tr:
            px, py = float(tr.group(1)), float(tr.group(2))
        elif x and y:
            px, py = float(x.group(1)), float(y.group(1))
        else:
            continue
        out.append(Text(clean(m.group(2)), px, py, anchor.group(1) if anchor else "start",
                        -float(rot.group(1)) if rot else 0.0))
    return [t for t in out if t.text]


def tex_texts(path: str) -> list[Text]:
    """The texts of a cairolatex picture: each \\put of a \\makebox, in bp from the top left."""
    with open(path, errors="replace") as f:
        s = f.read()
    height = re.search(r"\\begin\{picture\}\(([\d.]+),([\d.]+)\)", s)
    top = float(height.group(2)) / 20.0 if height else 0.0
    out = []
    for m in re.finditer(r"\\put\((-?\d+),(-?\d+)\)\{(.*)", s):
        rest = m.group(3)
        box = re.search(r"\\makebox\(0,0\)(\[([lrc])\])?\{(.*)", rest)
        if not box:
            continue
        rot = re.search(r"\\rotatebox\{(-?[\d.]+)\}", rest)
        body = re.sub(r"\}+%?\s*$", "", box.group(3))
        anchor = {"l": "start", "r": "end"}.get(box.group(2) or "c", "middle")
        out.append(Text(clean(body), int(m.group(1)) / 20.0, top - int(m.group(2)) / 20.0, anchor,
                        float(rot.group(1)) if rot else 0.0, raw(body)))
    return [t for t in out if t.text]


def options(probe: str) -> dict[str, str]:
    """The `#! key: value` lines of a probe."""
    out = {}
    with open(probe) as f:
        for line in f:
            m = re.match(r"#!\s*(\w+)\s*:\s*(.*)", line)
            if m:
                out[m.group(1)] = m.group(2).strip()
    return out


def roles(probe: str) -> dict[str, str]:
    """The kind of each text a probe sets by name: title, xlabel, ..., key, keytitle, label (one per line)."""
    with open(probe) as f:
        src = f.read()
    out: dict[str, str] = {}

    def add(kind: str, quoted: str) -> None:
        for line in quoted.replace("\\n", "\n").split("\n"):
            out.setdefault(clean(line), kind)

    q = r"""(?P<q>['"])(?P<s>.*?)(?P=q)"""
    for kind in ("title", "xlabel", "x2label", "ylabel", "y2label"):
        for m in re.finditer(rf"^\s*set\s+{kind}\s+{q}", src, re.M):
            add(kind, m.group("s"))
    for m in re.finditer(rf"^\s*set\s+key\b.*?\btitle\s+{q}", src, re.M):
        add("keytitle", m.group("s"))
    for m in re.finditer(rf"^\s*set\s+label\s+\d*\s*{q}", src, re.M):
        add("label", m.group("s"))
    for m in re.finditer(r"^\s*plot\b(.*)$", src, re.M):
        for t in re.finditer(rf"\btitle\s+{q}", m.group(1)):
            add("key", t.group("s"))
    return out


def margins(probe: str) -> tuple[float, ...]:
    """The probe's border, fractions of the canvas: left, right, bottom, top."""
    m = options(probe).get("margins")
    return tuple(float(v) for v in m.split()) if m else MARGINS


def tick_kind(t: Text, term: str, border: tuple[float, ...]) -> str:
    """The axis of a tick label, from where it stands against the plot area."""
    width, height = (600.0, 400.0) if term == "svg" else (360.0, 216.0)
    left, right, top, bottom = border[0] * width, border[1] * width, (1 - border[3]) * height, (1 - border[2]) * height
    if round(t.angle) % 180:  # rotated tick labels: x ones (y ones are not rotated in the probes)
        return "xtic" if t.y > (top + bottom) / 2 else "x2tic"
    slack = 0.06 * height  # a label centred on the corner tick hangs below the border by its baseline drop
    if t.x < left - 1.0 and top - slack <= t.y <= bottom + slack:
        return "ytic"
    if t.x > right + 1.0 and top - slack <= t.y <= bottom + slack:
        return "y2tic"
    return "xtic" if t.y > bottom else "x2tic"


def run(program: list[str], probe: str, term: str, out: str, env: dict[str, str] | None) -> None:
    """Run `probe` through `program` with the terminal `term`, its output into `out`."""
    opts = options(probe)
    spec, _, _ = TERMS[term]
    if "font" in opts:
        spec += f" font ',{opts['font']}'"
    with tempfile.TemporaryDirectory() as tmp:
        wrap = os.path.join(tmp, "wrap.gp")
        with open(wrap, "w") as f:
            m = margins(probe)
            f.write(f"set terminal {spec}\nset output '{out}'\nset lmargin at screen {m[0]}; set rmargin at screen {m[1]}; "
                    f"set bmargin at screen {m[2]}; set tmargin at screen {m[3]}\nload '{probe}'\nset output\n")
        subprocess.run(program + [wrap], cwd=tmp, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=60, check=False, env=env)


def match(gp: list[Text], fs: list[Text]) -> tuple[list[tuple[Text, Text]], list[Text], list[Text]]:
    """Pairs of texts of the same content, nearest first; the texts left on each side."""
    pairs, left_gp, left_fs = [], [], []
    for content in sorted({t.text for t in gp} | {t.text for t in fs}):
        a = [t for t in gp if t.text == content]
        b = [t for t in fs if t.text == content]
        cand = sorted(((abs(p.x - q.x) + abs(p.y - q.y), i, j) for i, p in enumerate(a) for j, q in enumerate(b)))
        used_a, used_b = set(), set()
        for _, i, j in cand:
            if i in used_a or j in used_b:
                continue
            used_a.add(i)
            used_b.add(j)
            pairs.append((a[i], b[j]))
        left_gp += [p for i, p in enumerate(a) if i not in used_a]
        left_fs += [q for j, q in enumerate(b) if j not in used_b]
    return pairs, left_gp, left_fs


def measure(foresight: str, probes: list[str], terms: list[str]) -> tuple[list[Row], list[str]]:
    """Run every probe through both programs and both terminals: the rows and the texts found on one side only."""
    rows, lonely = [], []
    with tempfile.TemporaryDirectory() as tmp:
        conf = os.path.join(tmp, "fonts.conf")
        with open(conf, "w") as f:
            f.write(FONTCONF)
        for probe in probes:
            name = os.path.basename(probe)[:-3]
            kinds = roles(probe)
            system = options(probe).get("fonts") == "system"
            for term in terms:
                ext = TERMS[term][1]
                gp_out, fs_out = os.path.join(tmp, f"{name}_gp.{ext}"), os.path.join(tmp, f"{name}_fs.{ext}")
                env = dict(os.environ)
                if not system:
                    env["FONTCONFIG_FILE"] = conf
                run(["gnuplot"], probe, term, gp_out, env)
                run([foresight], probe, term, fs_out, None)
                if not (os.path.exists(gp_out) and os.path.exists(fs_out)):
                    lonely.append(f"{name} {term}: no output from {'gnuplot' if not os.path.exists(gp_out) else 'foresight'}")
                    continue
                if term == "svg":
                    gp, fs = svg_texts(gp_out, True), svg_texts(fs_out, False)
                else:
                    gp, fs = tex_texts(gp_out), tex_texts(fs_out)
                pairs, only_gp, only_fs = match(gp, fs)
                for g, f in pairs:
                    kind = kinds.get(g.text) or tick_kind(g, term, margins(probe))
                    note = "" if (g.anchor, round(g.angle) % 360) == (f.anchor, round(f.angle) % 360) else \
                        f"anchor/angle {g.anchor} {g.angle:g} vs {f.anchor} {f.angle:g}"
                    rows.append(Row(name, term, g.text, kind, f.x - g.x, f.y - g.y, note, g.x, g.y, g.raw))
                lonely += [f"{name} {term}: {t.text!r} gnuplot only" for t in only_gp]
                lonely += [f"{name} {term}: {t.text!r} foresight only" for t in only_fs]
    return rows, lonely


def table(rows: list[Row]) -> str:
    """The rows as a fixed-width table."""
    lines = [f"{'probe':18} {'term':10} {'kind':8} {'dx':>8} {'dy':>8} unit text"]
    for r in rows:
        lines.append(f"{r.probe:18} {r.term:10} {r.kind:8} {r.dx:8.2f} {r.dy:8.2f} {UNITS[r.term]:4} {r.text!r}"
                     + (f"  [{r.note}]" if r.note else ""))
    return "\n".join(lines) + "\n"


def main() -> None:
    """Parse the options, measure, report."""
    args = sys.argv[1:]
    foresight, names, terms, write, explain_, check = os.path.join(ROOT, "bin", "foresight"), [], [], None, False, False
    kinds: list[str] = []
    while args:
        a = args.pop(0)
        if a == "--foresight":
            foresight = args.pop(0)
        elif a == "--probe":
            names.append(args.pop(0))
        elif a == "--term":
            terms.append(args.pop(0))
        elif a == "--write":
            write = args.pop(0)
        elif a == "--explain":
            explain_ = True
        elif a == "--check":
            check = True
        elif a == "--kinds":
            kinds = args.pop(0).split(",")
        else:
            sys.exit(f"placement.py: unknown option {a} (see the docstring)")
    if not shutil.which("gnuplot"):
        sys.exit("placement.py: gnuplot 6.0 not found")
    foresight = os.path.abspath(foresight)
    probes = sorted(os.path.join(PROBES, f) for f in os.listdir(PROBES) if f.endswith(".gp"))
    if names:
        probes = [p for p in probes if os.path.basename(p)[:-3] in names]
    rows, lonely = measure(foresight, probes, terms or list(TERMS))
    text = table(rows)
    print(text, end="")
    if write:
        with open(write, "w") as f:
            f.write(text)
    for line in lonely:
        print("unmatched:", line)
    failed = bool(lonely)
    if explain_ or check:
        from placement_rules import explain

        failed |= explain(rows, foresight, check, kinds)
    print(f"placement: {len(rows)} texts matched in {len(probes)} probes, {len(lonely)} unmatched")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
