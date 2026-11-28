"""placement_rules.py: gnuplot 6.0's 2D text placement (boundary.c, axis.c, gadgets.c, term.c), for placement.py.

`explain(rows, foresight, check)` predicts where gnuplot puts each text of the probes from its rules and the terminal's
character cell, and prints, per text, the rule, how far gnuplot's own position is from the prediction (the model's
residual, which attributes gnuplot's position to the rule) and foresight's offset. An offset is attributed when the
residual is within placement.LIMIT; it is driven by a width when the rule counts characters (the widest y tick label,
a left key's longest title, rotated x tick labels), and then the width difference (foresight measures the texts,
gnuplot counts characters times h_char) is printed too.

With `check`, foresight must be at gnuplot's place: within LIMIT, or within LIMIT of the width difference for the
width-driven coordinate.

Coordinates are the page's, y down, in px (svg) or bp (cairolatex). The rules, gnuplot's y up turned down:
  title       line i centre at T - (n Vt + V/2) [- x2 tick labels, x2 label, x2 ticks out] + i Vt - offset
  xlabel      line i centre at B + xtic_height + xtic_textheight + V/2 [+ V/2 without x tics] + i V - offset
  ylabel      (rotated 90) centre x at L - ytic_width - ytic_textwidth - n V / 2 + H / 4 + i V + offset
  x2label     line centre at T - n V - V/2 - 1.5 x2tic_textheight - x2tic_height + V/2
  y2label     centre x at R + y2tic_width + y2tic_textwidth + n V / 2
  xtic        first line centre at B + xtic_height + V (rotated: + H)
  ytic        right end at L - ytic_width - H, centred on the tick
  x2tic       centre at T - x2tic_height - V;   y2tic   left end at R + y2tic_width + H
  key         inside the border, v_tic below its top or above its bottom; rows of max(1.25 v_tic, V) spacing; the
              titles right-justified H left of the sample, which is 4 H + h_tic long and ends 2 H from the key's right;
              a left key's columns are its measured widest title and a H of padding (foresight) or its characters times
              H (gnuplot): the width difference plus H
  keytitle    centred over the key (or H in from a side), its first line V / 2 under the key's top
with xtic_height = v_tic scale (ticks out), xtic_textheight = (lines + 1) V, ytic_textwidth = (widest + 2) H; V, H,
v_tic, h_tic the terminal's (placement's svg cell: 1.5 and 0.7 font sizes, ticks half V; cairo: Liberation Sans' line,
digits, ticks V / 2.5). A text's anchor is its centre; svg writes its baseline (ascent - descent) / 2 = 0.325 font
sizes lower (along the text's up direction when rotated).
"""

from __future__ import annotations

import math
import os
import re
import subprocess
import tempfile

from placement import FONTCONF, LIMIT, MARGINS, PROBES, TERMS, Row, margins, options

LIB_UPM, LIB_LINE, LIB_DIGIT = 2048.0, 1854.0 + 434.0, 1139.0  # Liberation Sans: em, hhea line, digit advance


def cell(term: str, size: float) -> dict[str, float]:
    """gnuplot's cell of `term` at the font `size` (svg px, cairolatex pt): V, H, VT, HT and the baseline drop D."""
    if term == "svg":
        v = int(size * 90 + size * 25 + size * 35) / 100.0
        return {"V": v, "H": int(size * 70) / 100.0, "VT": int(v * 100) // 2 / 100.0,
                "HT": int(v * 100) // 2 / 100.0, "D": 0.325 * size}
    drawn = size * 0.6 * 4.0 / 3.0  # cairolatex: fontscale 0.6, drawn at 96 dpi [pt]
    units = drawn * 200.0 / LIB_UPM
    v = math.ceil(LIB_LINE * units) - 1
    h = math.ceil(10 * round(LIB_DIGIT * units) / 10)
    tic = int(v / 2.5)
    return {"V": v / 200.0, "H": h / 200.0, "VT": tic / 200.0, "HT": tic / 200.0, "D": 0.0}


_CELLS: dict = {}


def gnuplot_cell(probe: str, term: str, size: float) -> dict[str, float]:
    """gnuplot's own V and H for the probe's terminal (GPVAL_TERM_VCHAR, GPVAL_TERM_HCHAR after a plot), its ticks by
    the terminal's rule and the baseline drop of `cell`: the model then reads the cell gnuplot used (the system's font
    for a `#! fonts: system` probe); foresight_cell_test checks `cell` against the same values."""
    key = (probe, term)
    if key not in _CELLS:
        spec = TERMS[term][0] + (f" font ',{options(probe)['font']}'" if "font" in options(probe) else "")
        with tempfile.TemporaryDirectory() as tmp:
            env = dict(os.environ)
            if options(probe).get("fonts") != "system":
                conf = os.path.join(tmp, "fonts.conf")
                with open(conf, "w") as f:
                    f.write(FONTCONF)
                env["FONTCONFIG_FILE"] = conf
            out = subprocess.run(["gnuplot", "-e", f"set terminal {spec}; set output '{tmp}/x.{TERMS[term][1]}'; "
                                  "plot x; print GPVAL_TERM_VCHAR, GPVAL_TERM_HCHAR"], env=env, capture_output=True,
                                 text=True, cwd=tmp, check=False)
        v, h = (int(w) for w in out.stderr.split()[-2:])
        scale = 100.0 if term == "svg" else 200.0
        tic = v // 2 if term == "svg" else int(v / 2.5)
        _CELLS[key] = {"V": v / scale, "H": h / scale, "VT": tic / scale, "HT": tic / scale,
                       "D": cell(term, size)["D"]}
    return _CELLS[key]


def settings(probe: str) -> dict:
    """What a probe sets that the rules read: fonts, offsets, lines, tics, key."""
    with open(probe) as f:
        src = f.read()
    q = r"""(?P<q>['"])(?P<s>.*?)(?P=q)"""
    out: dict = {"lines": {}, "offset": {}, "font": {}}
    for kind in ("title", "xlabel", "x2label", "ylabel", "y2label"):
        m = re.search(rf"^\s*set\s+{kind}\s+{q}(?P<rest>.*)$", src, re.M)
        if not m:
            continue
        out["lines"][kind] = m.group("s").replace("\\n", "\n").split("\n")
        off = re.search(r"\boffset\s+(-?[\d.]+)\s*,\s*(-?[\d.]+)", m.group("rest"))
        out["offset"][kind] = (float(off.group(1)), float(off.group(2))) if off else (0.0, 0.0)
        font = re.search(r"\bfont\s+['\"][^,'\"]*,([\d.]+)", m.group("rest"))
        if font:
            out["font"][kind] = float(font.group(1))
    out["out"] = bool(re.search(r"^\s*set\s+tics\s+out", src, re.M))
    scale = re.search(r"^\s*set\s+tics\b.*\bscale\s+([\d.]+)", src, re.M)
    out["scale"] = float(scale.group(1)) if scale else 1.0
    out["x2tics"] = bool(re.search(r"^\s*set\s+x2tics", src, re.M))
    out["y2tics"] = bool(re.search(r"^\s*set\s+y2tics", src, re.M))
    out["xrotate"] = bool(re.search(r"^\s*set\s+xtics\b.*\brotate", src, re.M))
    key = re.search(r"^\s*set\s+key\b(.*)$", src, re.M)
    words = key.group(1) if key else ""
    out["key_left"] = bool(re.search(r"\bleft\b", words))
    out["key_bottom"] = bool(re.search(r"\bbottom\b", words))
    title = re.search(rf"\btitle\s+{q}", words)
    out["key_title"] = title.group("s") if title else ""
    out["titles"] = [t.group("s") for m in re.finditer(r"^\s*plot\b(.*)$", src, re.M)
                     for t in re.finditer(rf"\btitle\s+{q}", m.group(1))]
    return out


def area(probe: str, term: str) -> tuple[float, float, float, float]:
    """The plot area, page coordinates (y down): left, right, top, bottom, as gnuplot rounds the border to its units."""
    m = margins(probe) if probe else MARGINS
    if term == "svg":  # units of 1/100 px; ytop and xright at (max - 1) fractions, truncated
        xmax, ymax = 60000, 40000
        left, right = int(m[0] * xmax) / 100, int(m[1] * (xmax - 1)) / 100
        bottom, top = (ymax - int(m[2] * ymax)) / 100, (ymax - int(m[3] * (ymax - 1))) / 100
        return left, right, top, bottom
    # cairo terminals (cairo.trm): a canvas of (width - 1) x (height - 1) pt, its top 1 pt below the page's
    xmax, ymax = 359.0, 215.0
    return m[0] * xmax, m[1] * xmax, 216.0 - m[3] * ymax, 216.0 - m[2] * ymax


def predict(r: Row, s: dict, probe: str, gp_texts: dict) -> tuple[str, float | None, float | None, float, float]:
    """The rule of the text `r`, gnuplot's predicted x and y (None: not predicted), and the offset each coordinate takes
    from widths: foresight's position less gnuplot's when foresight measures the widths gnuplot estimates (0 when not
    width-driven)."""
    size = float(options(probe).get("font", TERMS[r.term][2]))
    c = gnuplot_cell(probe, r.term, size)
    V, H, VT, HT = c["V"], c["H"], c["VT"], c["HT"]
    L, R, T, B = area(probe, r.term)
    tic_out = s["out"]
    xtic_height = VT * s["scale"] if tic_out else 0.0
    ytic_width = HT * s["scale"] if tic_out else 0.0
    widest = max((len(t) for t in gp_texts.get("ytic", [])), default=0)
    widest2 = max((len(t) for t in gp_texts.get("y2tic", [])), default=0)
    ytic_textwidth = H * (widest + 2)
    y2tic_textwidth = H * (widest2 + 2) if s["y2tics"] else 0.0
    x2tic_textheight = V if s["x2tics"] else 0.0
    x2tic_height = VT * s["scale"] if (s["x2tics"] and tic_out) else 0.0

    def drop(kind: str) -> float:
        return c["D"] * s["font"].get(kind, size) / size

    def line_of(kind: str) -> int:
        lines = s["lines"].get(kind, [r.text])
        return lines.index(r.text) if r.text in lines else 0

    if r.kind == "title":
        n = len(s["lines"]["title"])
        vt = c["V"] * s["font"].get("title", size) / size if r.term == "svg" else \
            cell(r.term, s["font"].get("title", size))["V"] * c["V"] / cell(r.term, size)["V"]
        off = s["offset"]["title"]
        y = T - (n * vt + 0.5 * V) + line_of("title") * vt - off[1] * V
        if n + off[1] > 0:
            y -= x2tic_textheight + x2tic_height + (len(s["lines"].get("x2label", [])) * V)
        return "title: T - (n Vt + V/2) + i Vt", (L + R) / 2 + off[0] * H, y + drop("title"), 0.0, 0.0
    if r.kind == "xlabel":
        off = s["offset"]["xlabel"]
        texth = 2 * V
        if s["xrotate"]:
            proj = math.sin(math.radians(45))  # the probes' `rotate by 45 right`
            texts = gp_texts.get("xtic", [])
            y = B + xtic_height + H * max(len(t) for t in texts) * proj + V + 0.5 * V - off[1] * V
            return "xlabel below rotated x tick labels: B + xtic_height + widest H proj + V + V/2", \
                (L + R) / 2 + off[0] * H, y + drop("xlabel"), 0.0, width_difference(texts, H, size, r.term) * proj
        y = B + xtic_height + texth + 0.5 * V + line_of("xlabel") * V - off[1] * V
        return "xlabel: B + xtic_height + 2V + V/2", (L + R) / 2 + off[0] * H, y + drop("xlabel"), 0.0, 0.0
    if r.kind == "ylabel":
        off = s["offset"]["ylabel"]
        n = len(s["lines"]["ylabel"])
        x = L - ytic_width - ytic_textwidth - n * V / 2 + H / 4 + line_of("ylabel") * V + off[0] * H
        return "ylabel: L - ytic_width - (widest + 2) H - n V/2 + H/4", x + drop("ylabel"), (T + B) / 2 - off[1] * V, \
            -width_difference(gp_texts.get("ytic", []), H, size, r.term), 0.0
    if r.kind == "x2label":
        n = len(s["lines"]["x2label"])
        y = T - n * V - 0.5 * V - 1.5 * x2tic_textheight - x2tic_height + 0.5 * V + line_of("x2label") * V
        return "x2label: T - n V - 1.5 x2tic_textheight - x2tic_height", (L + R) / 2, y + drop("x2label"), 0.0, 0.0
    if r.kind == "y2label":
        n = len(s["lines"]["y2label"])
        x = R + (ytic_width if s["y2tics"] else 0.0) + y2tic_textwidth + n * V / 2 + line_of("y2label") * V
        if not s["y2tics"]:
            x += 0.25 * V  # half of the half line the label's room takes without y2 tics
        return "y2label: R + y2tic_width + (widest + 2) H + n V/2", x + drop("y2label"), (T + B) / 2, \
            width_difference(gp_texts.get("y2tic", []), H, size, r.term), 0.0
    if r.kind == "xtic":
        if s["xrotate"]:
            return "xtic rotated: B + xtic_height + H", None, None, 0.0, 0.0
        return "xtic: B + xtic_height + V", None, B + xtic_height + V + drop("xtic"), 0.0, 0.0
    if r.kind == "ytic":
        return "ytic: L - ytic_width - H", L - ytic_width - H, None, 0.0, 0.0
    if r.kind == "x2tic":
        return "x2tic: T - x2tic_height - V", None, T - x2tic_height - V + drop("x2tic"), 0.0, 0.0
    if r.kind == "y2tic":
        return "y2tic: R + y2tic_width + H", R + (ytic_width if s["out"] else 0.0) + H, None, 0.0, 0.0
    if r.kind in ("key", "keytitle"):
        titles = s["titles"]
        longest = max(len(t) for t in titles)
        entry = max(1.25 * VT, V)
        # a key title takes one line; cairolatex: gnuplot's estimate_strlen leaves the height unset for LaTeX
        # terminals and do_key_layout reads it uninitialized (0 in this build: the rows start at the top): a gnuplot
        # defect, modelled to attribute gnuplot's positions, not followed by foresight
        defect = r.term == "cairolatex" and bool(s["key_title"])
        title_h = (0.0 if defect else V) if s["key_title"] else 0.0
        sample = 4 * H + HT
        width = H * (longest + 1) + sample + H
        height = title_h + len(titles) * entry
        top = (B - VT - height) if s["key_bottom"] else (T + VT)
        left = (L + H) if s["key_left"] else (R - H - width)
        if r.kind == "keytitle":
            return ("DEFECT (gnuplot: the title's height uninitialized, 0 here) " if defect else "") + \
                "keytitle: centred, V/2 under the key's top", left + width / 2, top + title_h / 2 + c["D"], \
                (width_difference(titles, H, size, r.term) + H) / 2 if s["key_left"] else 0.0, 0.0
        row = titles.index(r.text)
        y = top + title_h + entry / 2 + row * entry + c["D"]
        x = left + H * longest
        return ("DEFECT (gnuplot: the key title's height uninitialized, 0 here) " if defect else "") + \
            "key: rows max(1.25 VT, V); text H left of a 4H + HT sample", x, y, \
            (width_difference(titles, H, size, r.term) + H) if s["key_left"] else 0.0, 0.0
    return "label: at its data position (the baseline drop only)", None, None, 0.0, 0.0


_FONT = None


def width_difference(texts: list[str], h: float, size: float, term: str) -> float:
    """The widest of `texts` measured in Liberation Sans less gnuplot's estimate (characters times `h`)."""
    global _FONT
    if not texts:
        return 0.0
    if _FONT is None:
        from fontTools.ttLib import TTFont

        f = TTFont("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf")
        _FONT = (f.getBestCmap(), f["hmtx"], f["head"].unitsPerEm)
    cmap, hmtx, upm = _FONT
    em = size if term == "svg" else size * 0.6 * 4.0 / 3.0
    real = max(sum(hmtx[cmap.get(ord(ch), cmap[ord("0")])][0] for ch in t.strip()) / upm * em for t in texts)
    est = max(len(t) for t in texts) * h
    return real - est


def explain(rows: list[Row], foresight: str, check: bool, kinds: list[str] | None = None) -> bool:
    """Print each text's rule, gnuplot's residual against it and foresight's offset (the `kinds` only, if given);
    True on a failure."""
    failed = False
    by = {}
    for r in rows:
        by.setdefault((r.probe, r.term), []).append(r)
    print(f"\n{'probe':16} {'term':10} {'kind':8} {'gp res x':>8} {'gp res y':>8} {'fs dx':>7} {'fs dy':>7} "
          f"{'w dx':>7} {'w dy':>7} rule")
    for (name, term), group in by.items():
        probe = os.path.join(PROBES, name + ".gp")
        s = settings(probe)
        system = options(probe).get("fonts") == "system"
        gp_texts: dict = {}
        for r in group:
            if r.kind in ("ytic", "y2tic", "xtic"):
                gp_texts.setdefault(r.kind, []).append(r.raw)
        for r in group:
            if kinds and r.kind not in kinds:
                continue
            rule, px, py, wx, wy = predict(r, s, probe, gp_texts)
            rx = None if px is None else r.gx - px
            ry = None if py is None else r.gy - py
            lim = LIMIT[r.term]
            unattributed = (rx is not None and abs(rx) > lim) or (ry is not None and abs(ry) > lim)
            bad = unattributed
            # the system's font in a cairo terminal: gnuplot measures another font than foresight's, nothing to check
            if check and not (system and r.term != "svg"):
                # a gnuplot defect is not followed: only the coordinate it does not touch is checked
                bad = bad or abs(r.dx - wx) > lim or (abs(r.dy - wy) > lim and not rule.startswith("DEFECT"))
            failed |= bad
            fmt = lambda v: "       -" if v is None else f"{v:8.2f}"  # noqa: E731
            print(f"{name:16} {term:10} {r.kind:8} {fmt(rx)} {fmt(ry)} {r.dx:7.2f} {r.dy:7.2f} {wx:7.2f} {wy:7.2f} "
                  f"{'UNATTRIBUTED ' if unattributed else ''}{'OFF ' if bad and not unattributed else ''}{rule}"
                  f"  {r.text!r}")
    return failed
