#!/usr/bin/env python3
"""Generate foresight's compiled-in fonts: Liberation Sans and Latin Modern Roman, four faces each.

Usage (from the repository root; fontTools needed: `pip install fonttools`):

    python3 scripts/gen_fonts.py [--liberation DIR] [--lm DIR] [--lm-math FILE]

reads the font files (defaults: the Debian/Ubuntu packages fonts-liberation2 and fonts-lmodern) and writes

- `src/lib/foresight_fontdata_<face>.F90`, one module per face: the code points (sorted), advance widths, kerning pairs
  and glyph outlines (in font units) of the glyph set below;
- `src/lib/foresight_fontdata.F90`, the lookup's interfaces, and `src/lib/foresight_fontdata_lookup.F90`, its submodule
  over the eight faces (pure procedures, parameter arrays: only the submodule reads the face modules);
- `src/tests/foresight_font_test_data.inc`, the reference widths of a fixed string set at 10 pt, computed here by an
  independent path (fontTools' hmtx and a pair-by-pair walk of the GPOS kerning lookups), for `foresight_font_test`.

The glyph set: ASCII, Latin-1, Latin Extended-A, Greek, general punctuation, the math symbols of TeX-math labels and
the code points gnuplot's Symbol font maps to (`foresight_enhanced` `greek`). Latin Modern Roman has no lowercase Greek
nor math symbols (TeX takes them from its math fonts): they come from Latin Modern Math, as TeX's math italic for the
italic faces (U+1D6FC...), bold (U+1D6C2...) and bold italic (U+1D736...); Liberation Sans' few missing symbols come
from the serif face of the same style at run time (foresight_font text_advance), so that each data module keeps one
license. A code point no file has is left out (foresight then uses 0.556 em).

Kerning: the `kern` feature's pair-adjustment lookups of GPOS (scripts DFLT, latn, grek) (formats 1 and 2, extension lookups included), flattened
to the pairs of the glyph set, the first subtable covering a pair winning, as OpenType shapers do. Pairs with a blank
are kerned as the font says (HarfBuzz does; Chrome, shaping word by word, does not).

Outlines: one operation per segment (0 move, 1 line, 2 quadratic, 3 cubic, 4 close) and its points (x, y pairs, font
units; Latin Modern's fractional CFF coordinates rounded); TrueType's implied on-curve points are made explicit.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from dataclasses import dataclass, field

from fontTools.pens.basePen import BasePen
from fontTools.ttLib import TTFont

LIBERATION = "/usr/share/fonts/truetype/liberation"
LM = "/usr/share/texmf/fonts/opentype/public/lm"
LM_MATH = "/usr/share/texmf/fonts/opentype/public/lm-math/latinmodern-math.otf"

FACES = [  # name, family file, style
    ("sans_regular", "liberation", "LiberationSans-Regular.ttf", "regular"),
    ("sans_bold", "liberation", "LiberationSans-Bold.ttf", "bold"),
    ("sans_italic", "liberation", "LiberationSans-Italic.ttf", "italic"),
    ("sans_bolditalic", "liberation", "LiberationSans-BoldItalic.ttf", "bolditalic"),
    ("serif_regular", "lm", "lmroman10-regular.otf", "regular"),
    ("serif_bold", "lm", "lmroman10-bold.otf", "bold"),
    ("serif_italic", "lm", "lmroman10-italic.otf", "italic"),
    ("serif_bolditalic", "lm", "lmroman10-bolditalic.otf", "bolditalic"),
]

# gnuplot's Symbol font (foresight_enhanced greek): letters and the upper half of Adobe's encoding
SYMBOL = [945, 946, 967, 948, 949, 966, 947, 951, 953, 981, 954, 955, 956, 957, 959, 960, 952, 961, 963, 964, 965,
          982, 969, 958, 968, 950, 913, 914, 935, 916, 917, 934, 915, 919, 921, 977, 922, 923, 924, 925, 927, 928, 920,
          929, 931, 932, 933, 962, 937, 926, 936, 918, 8364, 978, 8242, 8804, 8260, 8734, 402, 9827, 9830, 9829, 9824,
          8596, 8592, 8593, 8594, 8595, 176, 177, 8243, 8805, 215, 8733, 8706, 8226, 247, 8800, 8801, 8776, 8230, 9168,
          9135, 8629, 8501, 8465, 8476, 8472, 8855, 8853, 8709, 8745, 8746, 8835, 8839, 8836, 8834, 8838, 8712, 8713,
          8736, 8711, 174, 169, 8482, 8719, 8730, 8901, 172, 8743, 8744, 8660, 8656, 8657, 8658, 8659, 9674, 9001,
          8721, 9115, 9116, 9117, 9121, 9122, 9123, 9127, 9128, 9129, 9130, 9002, 8747, 8992, 9134, 8993, 9118, 9119,
          9120, 9124, 9125, 9126, 9131, 9132, 9133]
# TeX-math labels (issue #5 step 4.1) and common punctuation
MATH = [0x2202, 0x2207, 0x22C5, 0x00B7, 0x00D7, 0x00B1, 0x2264, 0x2265, 0x2211, 0x222B, 0x221A, 0x2212, 0x221E,
        0x2260, 0x2248, 0x2192, 0x2190, 0x2208, 0x221D, 0x2032, 0x2033, 0x03D1, 0x03D5, 0x03D6, 0x03F5, 0x2200,
        0x2203, 0x2223, 0x2225, 0x2227, 0x2228, 0x2229, 0x222A, 0x2282, 0x2283, 0x2286, 0x2287, 0x2218, 0x2219,
        0x2213, 0x2261, 0x223C, 0x2243, 0x2245, 0x226A, 0x226B, 0x2295, 0x2297, 0x22A5, 0x2016, 0x27E8, 0x27E9,
        0x210F, 0x2113, 0x2134, 0x00AC]
PUNCT = list(range(0x2010, 0x2028)) + [0x2030, 0x2039, 0x203A, 0x2044, 0x20AC, 0x2122, 0x2190, 0x2191, 0x2192,
                                         0x2193, 0x2194, 0x21D0, 0x21D2, 0x21D4, 0x2205]


def code_set() -> list[int]:
    """The code points foresight compiles in (wanted; each face keeps those a file has)."""
    codes = set(range(0x20, 0x7F)) | set(range(0xA0, 0x180)) | set(range(0x391, 0x3AA)) | set(range(0x3B1, 0x3CA))
    codes |= set(SYMBOL) | set(MATH) | set(PUNCT)
    codes.discard(0x3A2)  # unassigned
    return sorted(codes)


def math_alternative(code: int, style: str) -> int:
    """The Latin Modern Math code point standing for `code` in `style` (TeX's math alphabets for lowercase Greek)."""
    if 0x3B1 <= code <= 0x3C9 and style != "regular":
        start = {"italic": 0x1D6FC, "bold": 0x1D6C2, "bolditalic": 0x1D736}[style]
        return start + code - 0x3B1
    return code


class SegmentPen(BasePen):
    """Records a glyph as foresight's operations and points (implied quadratic points made explicit)."""

    def __init__(self, glyphset, scale: float) -> None:
        super().__init__(glyphset)
        self.ops: list[int] = []
        self.pts: list[int] = []
        self.scale = scale

    def _p(self, *points) -> None:
        for x, y in points:
            self.pts += [round(x * self.scale), round(y * self.scale)]

    def _moveTo(self, p) -> None:  # noqa: N802 - fontTools' interface
        self.ops.append(0)
        self._p(p)

    def _lineTo(self, p) -> None:  # noqa: N802
        self.ops.append(1)
        self._p(p)

    def _qCurveToOne(self, p1, p2) -> None:  # noqa: N802
        self.ops.append(2)
        self._p(p1, p2)

    def _curveToOne(self, p1, p2, p3) -> None:  # noqa: N802
        self.ops.append(3)
        self._p(p1, p2, p3)

    def _closePath(self) -> None:  # noqa: N802
        self.ops.append(4)

    def _endPath(self) -> None:  # noqa: N802
        self.ops.append(4)


@dataclass
class Face:
    """One face's data, in the face's font units."""

    name: str
    upm: int
    ascent: int
    descent: int
    cap_height: int
    x_height: int
    codes: list[int] = field(default_factory=list)
    advance: list[int] = field(default_factory=list)
    path_start: list[int] = field(default_factory=list)  # 1-based into ops, n + 1 entries
    point_start: list[int] = field(default_factory=list)  # 1-based into the packed points, n + 1 entries
    ops: list[int] = field(default_factory=list)
    points: list[int] = field(default_factory=list)
    kern: dict[tuple[int, int], int] = field(default_factory=dict)  # (left index, right index) 1-based -> units
    sources: list[str] = field(default_factory=list)


def kern_lookups(font: TTFont) -> list:
    """The pair-adjustment subtables of the `kern` feature of the Latin, Greek and default scripts, in lookup order."""
    if "GPOS" not in font:
        return []
    gpos = font["GPOS"].table
    indices: set[int] = set()
    for script in gpos.ScriptList.ScriptRecord:  # the scripts of the glyph set (a Hebrew lookup is not Latin's)
        if script.ScriptTag not in ("DFLT", "latn", "grek") or script.Script.DefaultLangSys is None:
            continue
        for fi in script.Script.DefaultLangSys.FeatureIndex:
            record = gpos.FeatureList.FeatureRecord[fi]
            if record.FeatureTag == "kern":
                indices |= set(record.Feature.LookupListIndex)
    lookups = []
    for i in sorted(indices):
        lookup = gpos.LookupList.Lookup[i]
        subtables = []
        for st in lookup.SubTable:
            if lookup.LookupType == 9:
                if st.ExtensionLookupType != 2:
                    continue
                st = st.ExtSubTable
            elif lookup.LookupType != 2:
                continue
            subtables.append(st)
        lookups.append(subtables)
    return lookups


def x_advance(value) -> int:
    """XAdvance of a ValueRecord (0 when absent)."""
    return int(getattr(value, "XAdvance", 0) or 0) if value is not None else 0


def pair_kern(lookups: list, left: str, right: str) -> int:
    """The kerning of the glyph pair (reference path: one pair at a time, as a shaper applies the lookups)."""
    total = 0
    for subtables in lookups:
        for st in subtables:
            if left not in st.Coverage.glyphs:
                continue
            if st.Format == 1:
                pairs = st.PairSet[st.Coverage.glyphs.index(left)].PairValueRecord
                hit = next((r for r in pairs if r.SecondGlyph == right), None)
                if hit is None:
                    continue
                total += x_advance(hit.Value1)
                break
            c1 = st.ClassDef1.classDefs.get(left, 0)
            c2 = st.ClassDef2.classDefs.get(right, 0)
            total += x_advance(st.Class1Record[c1].Class2Record[c2].Value1)
            break
    return total


def flat_kern(lookups: list, names: list[str]) -> dict[tuple[int, int], int]:
    """Every nonzero pair among `names` (1-based indices), by scanning each subtable once."""
    index = {n: i + 1 for i, n in enumerate(names)}
    kern: dict[tuple[int, int], int] = {}
    for subtables in lookups:
        done: set[tuple[int, int]] = set()  # pairs a subtable of this lookup already decided
        for st in subtables:
            covered = [g for g in st.Coverage.glyphs if g in index]
            if st.Format == 1:
                for g in covered:
                    for r in st.PairSet[st.Coverage.glyphs.index(g)].PairValueRecord:
                        if r.SecondGlyph in index:
                            key = (index[g], index[r.SecondGlyph])
                            if key not in done:
                                done.add(key)
                                kern[key] = kern.get(key, 0) + x_advance(r.Value1)
            else:
                for g in covered:
                    row = st.Class1Record[st.ClassDef1.classDefs.get(g, 0)].Class2Record
                    for h, j in index.items():
                        key = (index[g], j)
                        if key not in done:
                            done.add(key)
                            kern[key] = kern.get(key, 0) + x_advance(row[st.ClassDef2.classDefs.get(h, 0)].Value1)
    return {k: v for k, v in kern.items() if v != 0}


def sha(path: str) -> str:
    """Short SHA-256 of a file."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def build_face(
    name: str, path: str, style: str, math: TTFont, math_path: str, supplement: bool
) -> tuple[Face, TTFont, list[str]]:
    """Read one face (its glyph names returned for the reference widths: '' for glyphs from Latin Modern Math, taken
    when `supplement`: the serif faces only, so that each data module keeps one license)."""
    font = TTFont(path)
    upm = font["head"].unitsPerEm
    os2 = font["OS/2"]
    face = Face(name, upm, os2.sTypoAscender, os2.sTypoDescender, getattr(os2, "sCapHeight", 0) or 0,
                getattr(os2, "sxHeight", 0) or 0)
    face.sources = [f"{os.path.basename(path)} (sha256 {sha(path)}, {font['name'].getDebugName(5)})"]
    cmap, mcmap = font.getBestCmap(), math.getBestCmap()
    gs, mgs = font.getGlyphSet(), math.getGlyphSet()
    mscale = upm / math["head"].unitsPerEm
    names: list[str] = []
    used_math = False
    for code in code_set():
        if code in cmap:
            glyph, pen_scale, glyphset, width = cmap[code], 1.0, gs, font["hmtx"][cmap[code]][0]
            names.append(glyph)
        else:
            alt = math_alternative(code, style)
            if not supplement or alt not in mcmap:
                continue
            glyph, pen_scale, glyphset = mcmap[alt], mscale, mgs
            width = round(math["hmtx"][glyph][0] * mscale)
            names.append("")
            used_math = True
        pen = SegmentPen(glyphset, pen_scale)
        glyphset[glyph].draw(pen)
        face.codes.append(code)
        face.advance.append(width)
        face.path_start.append(len(face.ops) + 1)
        face.point_start.append(len(face.points) // 2 + 1)
        face.ops += pen.ops
        face.points += pen.pts
    face.path_start.append(len(face.ops) + 1)
    face.point_start.append(len(face.points) // 2 + 1)
    if used_math:
        face.sources.append(f"{os.path.basename(math_path)} (sha256 {sha(math_path)}): the glyphs the face lacks")
    lookups = kern_lookups(font)
    real = [n if n else "\0" for n in names]  # supplemented glyphs kern with nothing
    face.kern = flat_kern(lookups, real)
    return face, font, names


def wrap_values(items: list[str], width: int = 118) -> list[str]:
    """Comma-separated items in lines of at most `width` characters."""
    lines, line = [], ""
    for item in items:
        if line and len(line) + len(item) + 2 > width:
            lines.append(line + ",")
            line = item
        else:
            line = f"{line}, {item}" if line else item
    lines.append(line)
    return lines


def fortran_array(name: str, kind: str, values: list[int], comment: str) -> list[str]:
    """A parameter array, in chunks of at most 200 continuation lines (the standard allows 255), then joined."""
    rows = wrap_values([str(v) for v in values]) if values else []
    out: list[str] = [f"! {comment}"]
    if not rows:
        return out + [f"integer({kind}), parameter :: {name}(0) = [integer({kind}) ::]"]
    chunks = [rows[i : i + 200] for i in range(0, len(rows), 200)]
    counts = [sum(r.count(",") + (0 if r.endswith(",") else 1) for r in c) for c in chunks]
    if len(chunks) == 1:
        names = [name]
    else:
        names = [f"{name}_{i + 1}" for i in range(len(chunks))]
    for pname, chunk, n in zip(names, chunks, counts, strict=True):
        out.append(f"integer({kind}), parameter :: {pname}({n}) = [ &")
        for i, row in enumerate(chunk):
            row = row.rstrip(",")
            out.append("   " + row + (", &" if i < len(chunk) - 1 else "]"))
    if len(chunks) > 1:
        joined = wrap_values(names)
        out.append(f"integer({kind}), parameter :: {name}({len(values)}) = [ &")
        for i, row in enumerate(joined):
            row = row.rstrip(",")
            out.append("   " + row + (", &" if i < len(joined) - 1 else "]"))
    return out


def wrap_comment(text: str, width: int = 116) -> list[str]:
    """`!<` comment lines."""
    words, lines, line = text.split(), [], ""
    for w in words:
        if len(line) + len(w) + 1 > width:
            lines.append(line)
            line = w
        else:
            line = (line + " " + w).strip()
    lines.append(line)
    return ["!< " + x for x in lines]


def face_module(face: Face) -> str:
    """The Fortran module of one face."""
    mod = f"foresight_fontdata_{face.name}"
    head = f"{mod}, the {face.name.replace('_', ' ')} face compiled in (generated by scripts/gen_fonts.py: do not edit)."
    keys = sorted(face.kern)
    lines = [f"!< {head}", f"module {mod}", f"!< {head}", "!<"]
    lines += wrap_comment(
        "Code points (sorted), advance widths, kerning pairs (the key left * 65536 + right, glyph indices, sorted) and "
        "outlines (operations from path_start(i) to path_start(i + 1) - 1: 0 move, 1 line, 2 quadratic, 3 cubic, 4 "
        "close; their points from point_start(i), x and y packed as (x + 16384) * 32768 + y + 16384) in font units, units_per_em to the em. From: "
        + "; ".join(face.sources)
        + "."
    )
    if face.name.startswith("sans"):
        notice = ("Font data: a Modified Version of Liberation Sans 2.1.5, Digitized data copyright (c) 2010 Google "
                  "Corporation with Reserved Font Arimo, Tinos and Cousine; Copyright (c) 2012 Red Hat, Inc. with "
                  "Reserved Font Name Liberation. Licensed under the SIL Open Font License 1.1 (LICENSES/OFL-1.1.txt), "
                  "not under foresight's licenses.")
    else:
        notice = ("Font data: from Latin Modern Roman 10 2.005, Copyright 2003--2021 B. Jackowski and J. M. Nowacki, "
                  "and Latin Modern Math 1.959, Copyright 2012--2014 B. Jackowski, P. Strzelczyk and P. Pianowski (on "
                  "behalf of TeX users groups). Released under the GUST Font License (LICENSES/GUST-FONT-LICENSE.txt), "
                  "not under foresight's licenses.")
    lines.append("!<")
    lines += wrap_comment(notice)
    lines += ["use penf, only : I4P", "", "implicit none", "private", ""]
    p = face.name.upper()
    names = ["UPM", "ASCENT", "DESCENT", "CAP_HEIGHT", "X_HEIGHT", "CODES", "ADVANCE", "KERN_KEY", "KERN_VALUE",
             "PATH_START", "POINT_START", "OPS", "POINTS"]
    rows = wrap_values([f"{p}_{n}" for n in names], 100)
    for i, row in enumerate(rows):
        row = row.rstrip(",")
        lines.append(("public :: " if i == 0 else "          ") + row + (", &" if i < len(rows) - 1 else ""))
    lines.append("")
    lines.append(f"integer(I4P), parameter :: {p}_UPM = {face.upm} !< Font units to the em.")
    lines.append(f"integer(I4P), parameter :: {p}_ASCENT = {face.ascent} !< Typographic ascender.")
    lines.append(f"integer(I4P), parameter :: {p}_DESCENT = {face.descent} !< Typographic descender (negative).")
    lines.append(f"integer(I4P), parameter :: {p}_CAP_HEIGHT = {face.cap_height} !< Capital height.")
    lines.append(f"integer(I4P), parameter :: {p}_X_HEIGHT = {face.x_height} !< x height.")
    lines += fortran_array(f"{p}_CODES", "I4P", face.codes, "Code points, sorted.")
    lines += fortran_array(f"{p}_ADVANCE", "I4P", face.advance, "Advance widths.")
    lines += fortran_array(f"{p}_KERN_KEY", "I4P", [a * 65536 + b for a, b in keys], "Kerning pairs, sorted.")
    lines += fortran_array(f"{p}_KERN_VALUE", "I4P", [face.kern[k] for k in keys], "Kerning of each pair.")
    lines += fortran_array(f"{p}_PATH_START", "I4P", face.path_start, "First operation of each glyph.")
    lines += fortran_array(f"{p}_POINT_START", "I4P", face.point_start, "First coordinate of each glyph.")
    lines += fortran_array(f"{p}_OPS", "I4P", face.ops, "Outline operations.")
    assert all(-16384 <= v < 16384 for v in face.points)
    packed = [(face.points[i] + 16384) * 32768 + face.points[i + 1] + 16384 for i in range(0, len(face.points), 2)]
    lines += fortran_array(f"{p}_POINTS", "I4P", packed, "Outline points, (x + 16384) * 32768 + y + 16384.")
    lines.append(f"endmodule {mod}")
    return "\n".join(lines) + "\n"


def lookup_module(faces: list[Face]) -> tuple[str, str]:
    """foresight_fontdata (the interfaces) and its submodule foresight_fontdata_lookup (the lookup over the faces).

    The face data stays out of every user's module file: only the submodule uses the face modules (nvfortran 26.9
    copies parameter arrays into the module files of every user, 22 MB each, and its front end then crashes)."""
    n = len(faces)
    procs = []  # (kind, name, args, result, dummies (interface), locals, body)

    def metric(fn: str, what: str, doc: str) -> None:
        body = ["select case (face)"]
        for i, f in enumerate(faces):
            body += [f"case ({i + 1})", f"   value = {f.name.upper()}_{what}"]
        body += ["case default", "   value = 0_I4P", "endselect"]
        procs.append(("function", fn, "face", "value", doc,
                      ["integer(I4P), intent(in) :: face  !< Face, 1 to FACES.",
                       "integer(I4P)             :: value !< Font units."], [], body))

    metric("face_upm", "UPM", "Font units to the em of `face`.")
    metric("face_ascent", "ASCENT", "Typographic ascender of `face`.")
    metric("face_descent", "DESCENT", "Typographic descender of `face` (negative).")
    metric("face_cap_height", "CAP_HEIGHT", "Capital height of `face`.")
    metric("face_x_height", "X_HEIGHT", "x height of `face`.")

    def dispatch(fn: str, args: str, decl: list[str], call: str, default: str, doc: str, result: str) -> None:
        body = ["select case (face)"]
        for i, f in enumerate(faces):
            body += [f"case ({i + 1})", "   " + call.replace("@", f.name.upper())]
        body += ["case default", f"   {default}", "endselect"]
        procs.append(("function", fn, args, result, doc, decl, [], body))

    dispatch(
        "glyph_index", "face, code",
        ["integer(I4P), intent(in) :: face  !< Face, 1 to FACES.",
         "integer(I4P), intent(in) :: code  !< Unicode code point.",
         "integer(I4P)             :: index !< Glyph index, 0 if the face lacks it."],
        "index = search(@_CODES, code)", "index = 0_I4P",
        "The glyph index of the code point `code` in `face` (0 if absent).", "index")
    dispatch(
        "glyph_advance", "face, index",
        ["integer(I4P), intent(in) :: face    !< Face, 1 to FACES.",
         "integer(I4P), intent(in) :: index   !< Glyph index (glyph_index), > 0.",
         "integer(I4P)             :: advance !< Font units."],
        "advance = @_ADVANCE(index)", "advance = 0_I4P",
        "The advance width of glyph `index` of `face`.", "advance")
    dispatch(
        "glyph_kern", "face, left, right",
        ["integer(I4P), intent(in) :: face  !< Face, 1 to FACES.",
         "integer(I4P), intent(in) :: left  !< Glyph index of the first glyph, > 0.",
         "integer(I4P), intent(in) :: right !< Glyph index of the second glyph, > 0.",
         "integer(I4P)             :: kern  !< Font units (negative: closer)."],
        "kern = pair(@_KERN_KEY, @_KERN_VALUE, left, right)", "kern = 0_I4P",
        "The kerning between glyphs `left` and `right` of `face`.", "kern")
    body = ["select case (face)"]
    for i, f in enumerate(faces):
        p = f.name.upper()
        body += [f"case ({i + 1})",
                 f"   ops = {p}_OPS({p}_PATH_START(index):{p}_PATH_START(index + 1) - 1)",
                 f"   packed = {p}_POINTS({p}_POINT_START(index):{p}_POINT_START(index + 1) - 1)"]
    body += ["case default", "   allocate(ops(0), packed(0))", "endselect",
             "allocate(points(2 * size(packed)))",
             "points(1::2) = packed / 32768_I4P - 16384_I4P",
             "points(2::2) = modulo(packed, 32768_I4P) - 16384_I4P"]
    procs.append(("subroutine", "glyph_outline", "face, index, ops, points", "",
                  "The outline of glyph `index` of `face`: its operations (0 move, 1 line, 2 quadratic, 3 cubic, 4 "
                  "close) and their points (x, y pairs, font units).",
                  ["integer(I4P),              intent(in)  :: face      !< Face, 1 to FACES.",
                   "integer(I4P),              intent(in)  :: index     !< Glyph index (glyph_index), > 0.",
                   "integer(I4P), allocatable, intent(out) :: ops(:)    !< Operations.",
                   "integer(I4P), allocatable, intent(out) :: points(:) !< Coordinates, x then y."],
                  ["integer(I4P), allocatable              :: packed(:) !< Points, x and y in one integer."], body))

    def header(kind: str, name: str, args: str, result: str) -> str:
        res = f" result({result})" if result else ""
        return f"pure module {kind} {name}({args}){res}"

    head = "foresight_fontdata, the compiled-in faces: their lookup (generated by scripts/gen_fonts.py: do not edit)."
    mod = [f"!< {head}", "module foresight_fontdata", f"!< {head}", "!<"]
    mod += wrap_comment(
        "Faces 1-4 Liberation Sans (regular, bold, italic, bold italic), 5-8 Latin Modern Roman in the same order. "
        "A glyph is found by its code point (binary search); its advance and its kerning with the next glyph are in "
        "font units of its face (face_upm). The procedures are in the submodule foresight_fontdata_lookup, the only "
        "user of the face data modules."
    )
    mod += ["use penf, only : I4P", "", "implicit none", "private", "public :: FACES",
            "public :: face_upm, face_ascent, face_descent, face_cap_height, face_x_height",
            "public :: glyph_index, glyph_advance, glyph_kern, glyph_outline", "",
            f"integer(I4P), parameter :: FACES = {n}_I4P !< Compiled-in faces.", "", "interface"]
    for kind, name, args, result, doc, decl, _, _ in procs:
        mod.append("   " + header(kind, name, args, result))
        mod += ["   " + x for x in wrap_comment(doc, 112)]
        mod += ["   " + d for d in decl]
        mod.append(f"   end{kind} {name}")
        mod.append("")
    mod[-1:] = ["endinterface", "endmodule foresight_fontdata"]

    shead = "foresight_fontdata_lookup, the lookup over the compiled-in faces (generated by scripts/gen_fonts.py: do not edit)."
    sub = [f"!< {shead}", "submodule (foresight_fontdata) foresight_fontdata_lookup", f"!< {shead}"]
    for f in faces:
        p = f.name.upper()
        rows = wrap_values([f"{p}_{x}" for x in ("UPM", "ASCENT", "DESCENT", "CAP_HEIGHT", "X_HEIGHT", "CODES",
                                                 "ADVANCE", "KERN_KEY", "KERN_VALUE", "PATH_START", "POINT_START",
                                                 "OPS", "POINTS")], 100)
        sub.append(f"use foresight_fontdata_{f.name}, only : &")
        for i, row in enumerate(rows):
            row = row.rstrip(",")
            sub.append("   " + row + (", &" if i < len(rows) - 1 else ""))
    sub += ["", "implicit none", "", "contains"]
    for kind, name, args, result, doc, decl, local, body in procs:
        sub.append("   " + header(kind, name, args, result))
        sub += ["   " + x for x in wrap_comment(doc, 112)]
        sub += ["   " + d for d in decl + local]
        sub.append("")
        sub += ["   " + b for b in body]
        sub.append(f"   end{kind} {name}")
        sub.append("")
    sub += [
        "   pure function search(codes, code) result(index)",
        "   !< The position of `code` in the sorted `codes`, 0 if absent.",
        "   integer(I4P), intent(in) :: codes(:) !< Sorted values.",
        "   integer(I4P), intent(in) :: code     !< Value.",
        "   integer(I4P)             :: index    !< Position.",
        "   integer(I4P)             :: low      !< Lower bound.",
        "   integer(I4P)             :: high     !< Upper bound.",
        "   integer(I4P)             :: middle   !< Middle.",
        "",
        "   index = 0_I4P",
        "   low = 1_I4P",
        "   high = size(codes, kind=I4P)",
        "   do while (low <= high)",
        "      middle = (low + high) / 2_I4P",
        "      if (codes(middle) == code) then",
        "         index = middle",
        "         return",
        "      elseif (codes(middle) < code) then",
        "         low = middle + 1_I4P",
        "      else",
        "         high = middle - 1_I4P",
        "      endif",
        "   enddo",
        "   endfunction search",
        "",
        "   pure function pair(keys, values, left, right) result(kern)",
        "   !< The kerning of the pair (`left`, `right`) in the sorted `keys` (left * 65536 + right), 0 if absent.",
        "   integer(I4P), intent(in) :: keys(:)   !< Sorted pair keys.",
        "   integer(I4P), intent(in) :: values(:) !< Kerning of each pair.",
        "   integer(I4P), intent(in) :: left      !< First glyph.",
        "   integer(I4P), intent(in) :: right     !< Second glyph.",
        "   integer(I4P)             :: kern      !< Font units.",
        "   integer(I4P)             :: k         !< Position.",
        "",
        "   kern = 0_I4P",
        "   if (size(keys) == 0) return",
        "   k = search(keys, left * 65536_I4P + right)",
        "   if (k > 0_I4P) kern = values(k)",
        "   endfunction pair",
        "endsubmodule foresight_fontdata_lookup",
    ]
    return "\n".join(mod) + "\n", "\n".join(sub) + "\n"


TEST_STRINGS = [
    "0123456789",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "abcdefghijklmnopqrstuvwxyz",
    "àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿß",
    "ÀÉÎÕÜÇÑŁłŠšŽžŒœĞğİı",
    "αβγδεζηθικλμνξοπρστυφχψω",
    "ΓΔΘΛΞΠΣΦΨΩ",
    "AV To Wa LT Yo P. F, Te",
    "AVATAR",
    "Temperature [K] vs. time (s), 10^{-3} ± 0.5 °C",
    "∂ ∇ · × ≤ ≥ ∑ ∫ √ − ∞",
]


def reference(faces: list[tuple[Face, TTFont, list[str]]], math: TTFont) -> str:
    """The test data: the width at 10 pt of each test string in each face, and of each kerned pair, by fontTools."""
    out = [
        "! foresight_font_test reference widths (generated by scripts/gen_fonts.py: do not edit): at 10 pt, from",
        "! fontTools' advance widths and a pair-by-pair walk of the GPOS kern lookups.",
    ]
    rows = []
    mcmap = math.getBestCmap()
    styles = {name: style for name, _, _, style in FACES}
    serif = {f.name: (f, font) for f, font, _ in faces if f.name.startswith("serif")}

    def serif_width(code: int, style: str) -> float | None:
        """Width at 10 pt of `code` in the serif face of `style` (Latin Modern Roman, else Latin Modern Math)."""
        face, font = serif[f"serif_{style}"]
        cmap = font.getBestCmap()
        if code in cmap:
            return font["hmtx"][cmap[code]][0] * 10.0 / face.upm
        alt = math_alternative(code, style)
        if alt in mcmap:
            return round(math["hmtx"][mcmap[alt]][0] * face.upm / math["head"].unitsPerEm) * 10.0 / face.upm
        return None

    for face, font, names in faces:
        lookups = kern_lookups(font)
        cmap = font.getBestCmap()
        for s in TEST_STRINGS:
            width, prev = 0.0, None
            for ch in s:
                code = ord(ch)
                if code in cmap:
                    g = cmap[code]
                    width += font["hmtx"][g][0] * 10.0 / face.upm
                    if prev:
                        width += pair_kern(lookups, prev, g) * 10.0 / face.upm
                    prev = g
                else:  # the serif face of the style (Latin Modern Math's glyph there), not kerned
                    w = serif_width(code, styles[face.name])
                    width += 5.56 if w is None else w
                    prev = None
            rows.append((face.name, s, width))
    out.append(f"integer, parameter :: NREF = {len(rows)}")
    out.append(f"integer, parameter :: REF_FACE({len(rows)}) = [ &")
    fidx = {f.name: i + 1 for i, (f, _, _) in enumerate(faces)}
    vals = [str(fidx[r[0]]) for r in rows]
    out += ["   " + ", ".join(vals[i : i + 20]) + (", &" if i + 20 < len(vals) else "]") for i in range(0, len(vals), 20)]
    out.append(f"character(len=*), parameter :: REF_TEXT({len(TEST_STRINGS)}) = [character(len=128) :: &")
    for i, s in enumerate(TEST_STRINGS):
        out.append("   '" + s.replace("'", "''") + "'" + (", &" if i < len(TEST_STRINGS) - 1 else "]"))
    out.append(f"real(R8P), parameter :: REF_WIDTH({len(rows)}) = [ &")
    w = [f"{r[2]:.6f}_R8P" for r in rows]
    out += ["   " + ", ".join(w[i : i + 6]) + (", &" if i + 6 < len(w) else "]") for i in range(0, len(w), 6)]
    # kerned pairs: the 40 strongest of each face, by the reference path
    pairs = []
    for face, font, names in faces:
        lookups = kern_lookups(font)
        top = sorted(face.kern.items(), key=lambda kv: (kv[1], kv[0]))[:40]
        for (a, b), _ in top:
            pairs.append((fidx[face.name], face.codes[a - 1], face.codes[b - 1],
                          pair_kern(lookups, names[a - 1], names[b - 1]) * 10.0 / face.upm))
    out.append(f"integer, parameter :: NPAIR = {len(pairs)}")
    out.append(f"integer, parameter :: PAIR_DATA(3, {len(pairs)}) = reshape([ &")
    pv = [f"{p[0]}, {p[1]}, {p[2]}" for p in pairs]
    out += ["   " + ", ".join(pv[i : i + 6]) + (", &" if i + 6 < len(pv) else f"], [3, {len(pairs)}])")
            for i in range(0, len(pv), 6)]
    out.append(f"real(R8P), parameter :: PAIR_KERN({len(pairs)}) = [ &")
    kv = [f"{p[3]:.6f}_R8P" for p in pairs]
    out += ["   " + ", ".join(kv[i : i + 6]) + (", &" if i + 6 < len(kv) else "]") for i in range(0, len(kv), 6)]
    return "\n".join(out) + "\n"


def main() -> None:
    """Generate the modules and the test data."""
    ap = argparse.ArgumentParser()
    ap.add_argument("--liberation", default=LIBERATION)
    ap.add_argument("--lm", default=LM)
    ap.add_argument("--lm-math", default=LM_MATH)
    ap.add_argument("--out", default="src/lib")
    ap.add_argument("--test-out", default="src/tests")
    a = ap.parse_args()
    math = TTFont(a.lm_math)
    built = []
    for name, family, filename, style in FACES:
        d = a.liberation if family == "liberation" else a.lm
        built.append(build_face(name, os.path.join(d, filename), style, math, a.lm_math, family == "lm"))
    for face, _, _ in built:
        path = os.path.join(a.out, f"foresight_fontdata_{face.name}.F90")
        with open(path, "w") as f:
            f.write(face_module(face))
        print(f"{path}: {len(face.codes)} glyphs, {len(face.kern)} kerning pairs, {len(face.ops)} operations, "
              f"{len(face.points) // 2} points")
    module, submodule = lookup_module([b[0] for b in built])
    with open(os.path.join(a.out, "foresight_fontdata.F90"), "w") as f:
        f.write(module)
    with open(os.path.join(a.out, "foresight_fontdata_lookup.F90"), "w") as f:
        f.write(submodule)
    with open(os.path.join(a.test_out, "foresight_font_test_data.inc"), "w") as f:
        f.write(reference(built, math))


if __name__ == "__main__":
    main()
