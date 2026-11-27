#!/usr/bin/env python3
"""Generate foresight's compiled-in math font: the glyphs of Latin Modern Math that TeX-math labels use.

Usage (from the repository root; fontTools needed: `pip install fonttools`):

    python3 scripts/gen_mathfont.py [--lm-math FILE]

reads Latin Modern Math (default: the Debian/Ubuntu package fonts-lmodern's, as TeX Live installs it) and writes

- `src/lib/foresight_mathfont.F90`: the MATH table's constants (font units) and the interfaces of the glyph lookup;
- `src/lib/foresight_mathfont_data.F90`: the glyph data (parameter arrays, used by the submodule only: nvfortran
  copies parameter arrays into the module files of every user), the outlines of the first half of the glyphs;
- `src/lib/foresight_mathfont_outlines.F90`: the outlines of the other half (nvfortran 26.9's front end crashes on a
  module whose outline points are one array of 47000 values: each half holds about 24000);
- `src/lib/foresight_mathfont_lookup.F90`: the submodule of the lookup.

The glyph set: ASCII, the upright Greek capitals, the math italic Latin and Greek letters (U+1D434..., U+1D6E2...),
the operators, relations and accents of foresight_math, each with its size variants (MathVariants: radicals,
delimiters, big operators) and its script alternates (the `ssty` feature, levels 1 and 2, which LuaTeX applies at
script and scriptscript sizes). A variant or alternate has a code of its own in the private use plane 15
(U+F0000...), shown as its base character. Per glyph: the advance, the italic correction (MathItalicsCorrectionInfo),
the top accent attachment (MathTopAccentAttachment, -32768 when the font gives none), the bounding box's bottom and
top, the outline (as scripts/gen_fonts.py writes them: 0 move, 1 line, 2 quadratic, 3 cubic, 4 close).
"""

from __future__ import annotations

import argparse
import hashlib
import os

from fontTools.pens.boundsPen import BoundsPen
from fontTools.ttLib import TTFont

from gen_fonts import SegmentPen, fortran_array, wrap_comment, wrap_values

LM_MATH = "/usr/share/texmf/fonts/opentype/public/lm-math/latinmodern-math.otf"
PUA = 0xF0000
MATH_ITALIC = [c for c in range(0x1D434, 0x1D468) if c != 0x1D455] + [0x210E]
MATH_GREEK = list(range(0x1D6E2, 0x1D71C))
OPERATORS = [0x00AC, 0x00B1, 0x00B7, 0x00D7, 0x2016, 0x2026, 0x2032, 0x2033, 0x2034, 0x210F, 0x2113, 0x2190, 0x2192,
             0x2194, 0x21D0, 0x21D2, 0x21D4, 0x2200, 0x2202, 0x2203, 0x2205, 0x2207, 0x2208, 0x2209, 0x220F, 0x2211,
             0x2212, 0x2213, 0x2218, 0x2219, 0x221A, 0x221D, 0x221E, 0x2223, 0x2225, 0x2227, 0x2228, 0x2229, 0x222A,
             0x222B, 0x222E, 0x223C, 0x2243, 0x2245, 0x2248, 0x2260, 0x2261, 0x2264, 0x2265, 0x226A, 0x226B, 0x2282,
             0x2283, 0x2286, 0x2287, 0x2295, 0x2297, 0x22A5, 0x22C5, 0x22EF, 0x2308, 0x2309, 0x230A, 0x230B, 0x27E8,
             0x27E9, 0x1D715]
ACCENTS = [0x0300, 0x0301, 0x0302, 0x0303, 0x0304, 0x0306, 0x0307, 0x0308, 0x030C, 0x20D7]
NOTICE = ("Font data: from Latin Modern Math 1.959, Copyright 2012--2014 B. Jackowski, P. Strzelczyk and P. Pianowski "
          "(on behalf of TeX users groups). Released under the GUST Font License (LICENSES/GUST-FONT-LICENSE.txt), not "
          "under foresight's licenses.")
CONSTANTS = ["AxisHeight", "AccentBaseHeight", "FractionNumeratorShiftUp", "FractionDenominatorShiftDown",
             "FractionNumeratorGapMin", "FractionDenominatorGapMin", "FractionRuleThickness", "SuperscriptShiftUp",
             "SuperscriptShiftUpCramped", "SuperscriptBaselineDropMax", "SuperscriptBottomMin",
             "SuperscriptBottomMaxWithSubscript", "SubscriptShiftDown", "SubscriptBaselineDropMin", "SubscriptTopMax",
             "SubSuperscriptGapMin", "SpaceAfterScript", "RadicalVerticalGap", "RadicalRuleThickness",
             "RadicalExtraAscender", "ScriptPercentScaleDown", "ScriptScriptPercentScaleDown", "OverbarVerticalGap",
             "OverbarRuleThickness", "OverbarExtraAscender", "UpperLimitGapMin", "UpperLimitBaselineRiseMin",
             "LowerLimitGapMin", "LowerLimitBaselineDropMin", "DelimitedSubFormulaMinHeight",
             "FlattenedAccentBaseHeight"]


def snake(name: str) -> str:
    """AxisHeight -> AXIS_HEIGHT."""
    out = ""
    for i, ch in enumerate(name):
        if ch.isupper() and i > 0:
            out += "_"
        out += ch.upper()
    return out


def main() -> None:
    """Read the font, write the modules."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--lm-math", default=LM_MATH)
    args = parser.parse_args()
    font = TTFont(args.lm_math)
    with open(args.lm_math, "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    math = font["MATH"].table
    cmap = font.getBestCmap()
    gs = font.getGlyphSet()
    hmtx = font["hmtx"]
    info = math.MathGlyphInfo
    italic = {}
    if info.MathItalicsCorrectionInfo:
        ic = info.MathItalicsCorrectionInfo
        italic = {g: v.Value for g, v in zip(ic.Coverage.glyphs, ic.ItalicsCorrection, strict=True)}
    accent = {}
    if info.MathTopAccentAttachment:
        ta = info.MathTopAccentAttachment
        accent = {g: v.Value for g, v in zip(ta.TopAccentCoverage.glyphs, ta.TopAccentAttachment, strict=True)}
    vert = math.MathVariants.VertGlyphCoverage.glyphs
    variants = {g: [r.VariantGlyph for r in math.MathVariants.VertGlyphConstruction[i].MathGlyphVariantRecord]
                for i, g in enumerate(vert)}
    ssty: dict[str, list[str]] = {}
    gsub = font["GSUB"].table
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != "ssty":
            continue
        for li in record.Feature.LookupListIndex:
            for st in gsub.LookupList.Lookup[li].SubTable:
                for g, alts in getattr(st, "alternates", {}).items():
                    ssty.setdefault(g, list(alts))
                for g, alt in getattr(st, "mapping", {}).items():
                    ssty.setdefault(g, [alt])
    wanted = sorted(set(range(0x21, 0x7F)) | set(range(0x391, 0x3AA)) - {0x3A2} | set(MATH_ITALIC)
                    | set(MATH_GREEK) | set(OPERATORS) | set(ACCENTS))
    # the glyphs: the coded ones, then their variants and script alternates (each once)
    glyphs: list[tuple[int, int, str]] = []  # (code, unicode shown, glyph name)
    index: dict[str, int] = {}
    for code in wanted:
        if code in cmap and cmap[code] not in index:
            index[cmap[code]] = len(glyphs)
            glyphs.append((code, code, cmap[code]))
    extra = PUA
    for code, _, name in list(glyphs):
        for other in variants.get(name, [])[1:] + ssty.get(name, []):
            if other not in index:
                index[other] = len(glyphs)
                glyphs.append((extra, code, other))
                extra += 1
    data = {"CODE": [], "UNICODE": [], "ADVANCE": [], "ITALIC": [], "ACCENT": [], "YMIN": [], "YMAX": [],
            "PATH_START": [], "POINT_START": [], "OPS": [], "POINTS": []}
    for code, shown, name in glyphs:
        pen = SegmentPen(gs, 1.0)
        gs[name].draw(pen)
        bounds = BoundsPen(gs)
        gs[name].draw(bounds)
        box = bounds.bounds or (0, 0, 0, 0)
        data["CODE"].append(code)
        data["UNICODE"].append(shown)
        data["ADVANCE"].append(hmtx[name][0])
        data["ITALIC"].append(italic.get(name, 0))
        data["ACCENT"].append(accent.get(name, -32768))
        data["YMIN"].append(round(box[1]))
        data["YMAX"].append(round(box[3]))
        data["PATH_START"].append(len(data["OPS"]) + 1)
        data["POINT_START"].append(len(data["POINTS"]) // 2 + 1)
        data["OPS"] += pen.ops
        data["POINTS"] += pen.pts
    data["PATH_START"].append(len(data["OPS"]) + 1)
    data["POINT_START"].append(len(data["POINTS"]) // 2 + 1)
    # the outlines in two halves, each its own starts (from 1)
    half = len(glyphs) // 2
    parts = []
    for lo, hi in ((0, half), (half, len(glyphs))):
        o0, p0 = data["PATH_START"][lo] - 1, data["POINT_START"][lo] - 1
        parts.append({
            "PATH_START": [v - o0 for v in data["PATH_START"][lo:hi + 1]],
            "POINT_START": [v - p0 for v in data["POINT_START"][lo:hi + 1]],
            "OPS": data["OPS"][o0:data["PATH_START"][hi] - 1],
            "POINTS": data["POINTS"][2 * p0:2 * (data["POINT_START"][hi] - 1)],
        })
    # variants and script alternates by glyph (1-based glyph numbers, 0 none)
    var_first, var_list = [], []
    st1, st2 = [], []
    for _, _, name in glyphs:
        var_first.append(len(var_list) + 1)
        var_list += [index[v] + 1 for v in variants.get(name, [])[1:]]
        alts = ssty.get(name, [])
        st1.append(index[alts[0]] + 1 if len(alts) > 0 and alts[0] in index else 0)
        st2.append(index[alts[1]] + 1 if len(alts) > 1 and alts[1] in index else st1[-1])
    var_first.append(len(var_list) + 1)
    order = sorted(range(len(glyphs)), key=lambda i: glyphs[i][0])
    assert order == list(range(len(glyphs))), "codes are not sorted"
    source = f"{os.path.basename(args.lm_math)} (sha256 {digest}, {font['name'].getDebugName(5)})"
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "lib")
    constants = {n: getattr(math.MathConstants, n) for n in CONSTANTS}
    constants = {n: getattr(v, "Value", v) for n, v in constants.items()}

    # the interface module
    head = "foresight_mathfont, Latin Modern Math's glyphs and constants (generated by scripts/gen_mathfont.py: do not edit)."
    lines = [f"!< {head}", "module foresight_mathfont", f"!< {head}", "!<"]
    lines += wrap_comment(
        "The glyphs of TeX-math labels (foresight_math): glyph numbers 1 to MATH_GLYPHS, in the order of their codes "
        "(a variant's or a script alternate's in the private use plane 15). Lengths in font units, MATH_UPM to the em. "
        "From: " + source + ".")
    lines += ["!<"] + wrap_comment(NOTICE)
    lines += ["use penf, only : I4P", "", "implicit none", "private",
              "public :: MATH_UPM, MATH_GLYPHS",
              "public :: math_glyph, math_code, math_unicode, math_advance, math_italic, math_accent, math_ymin, "
              "math_ymax",
              "public :: math_outline, math_variant, math_script_glyph"]
    names = [f"MATH_{snake(n)}" for n in CONSTANTS]
    rows = wrap_values(names, 100)
    for i, row in enumerate(rows):
        row = row.rstrip(",")
        lines.append(("public :: " if i == 0 else "          ") + row + (", &" if i < len(rows) - 1 else ""))
    lines += ["", f"integer(I4P), parameter :: MATH_UPM = {font['head'].unitsPerEm} !< Font units to the em.",
              f"integer(I4P), parameter :: MATH_GLYPHS = {len(glyphs)} !< Glyphs compiled in."]
    for n in CONSTANTS:
        lines.append(f"integer(I4P), parameter :: MATH_{snake(n)} = {constants[n]} !< MATH table: {n}.")
    lines += ["", "interface"]
    one = [("math_glyph", "code", "The glyph of the character `code`, 0 if none."),
           ("math_code", "glyph", "The code of a glyph (a variant's or alternate's in plane 15)."),
           ("math_unicode", "glyph", "The character a glyph shows."),
           ("math_advance", "glyph", "Advance width."),
           ("math_italic", "glyph", "Italic correction."),
           ("math_accent", "glyph", "Top accent attachment, -32768 if none."),
           ("math_ymin", "glyph", "Bounding box bottom."),
           ("math_ymax", "glyph", "Bounding box top.")]
    for fn, arg, doc in one:
        lines += [f"   pure module function {fn}({arg}) result(value)", f"   !< {doc}",
                  f"   integer(I4P), intent(in) :: {arg} !< {'Code point' if arg == 'code' else 'Glyph number'}.",
                  "   integer(I4P)             :: value !< Value.", f"   endfunction {fn}", ""]
    lines += ["   pure module function math_variant(glyph, k) result(value)",
              "   !< The `k`-th larger size variant of a glyph (MathVariants), 0 if none.",
              "   integer(I4P), intent(in) :: glyph !< Glyph number.",
              "   integer(I4P), intent(in) :: k     !< Variant, from 1.",
              "   integer(I4P)             :: value !< Glyph number of the variant.", "   endfunction math_variant", "",
              "   pure module function math_script_glyph(glyph, level) result(value)",
              "   !< The glyph at script (`level` 1) or scriptscript (2) size: its `ssty` alternate, else itself.",
              "   integer(I4P), intent(in) :: glyph !< Glyph number.",
              "   integer(I4P), intent(in) :: level !< 1 script, 2 scriptscript.",
              "   integer(I4P)             :: value !< Glyph number.", "   endfunction math_script_glyph", "",
              "   pure module subroutine math_outline(glyph, ops, points)",
              "   !< The outline of a glyph: its operations and their points (x, y pairs).",
              "   integer(I4P),              intent(in)  :: glyph     !< Glyph number.",
              "   integer(I4P), allocatable, intent(out) :: ops(:)    !< Operations.",
              "   integer(I4P), allocatable, intent(out) :: points(:) !< Points, x and y.",
              "   endsubroutine math_outline", "endinterface", "endmodule foresight_mathfont"]
    with open(os.path.join(root, "foresight_mathfont.F90"), "w") as f:
        f.write("\n".join(lines) + "\n")

    # the data module
    head = "foresight_mathfont_data, the glyph data of foresight_mathfont (generated by scripts/gen_mathfont.py: do not edit)."
    lines = [f"!< {head}", "module foresight_mathfont_data", f"!< {head}", "!<"] + wrap_comment(NOTICE)
    lines += ["use penf, only : I4P", "", "implicit none", "private"]
    arrays = ["CODE", "UNICODE", "ADVANCE", "ITALIC", "ACCENT", "YMIN", "YMAX", "VAR_FIRST", "VAR_LIST", "SSTY1",
              "SSTY2", "HALF", "PATH_START1", "POINT_START1", "OPS1", "POINTS1"]
    rows = wrap_values([f"MD_{a}" for a in arrays], 100)
    for i, row in enumerate(rows):
        row = row.rstrip(",")
        lines.append(("public :: " if i == 0 else "          ") + row + (", &" if i < len(rows) - 1 else ""))
    lines.append("")
    docs = {"CODE": "Codes, sorted.", "UNICODE": "Characters shown.", "ADVANCE": "Advance widths.",
            "ITALIC": "Italic corrections.", "ACCENT": "Top accent attachments (-32768 none).",
            "YMIN": "Bounding box bottoms.", "YMAX": "Bounding box tops."}
    for a in arrays[:7]:
        lines += fortran_array(f"MD_{a}", "I4P", data[a], docs[a])
    lines += fortran_array("MD_VAR_FIRST", "I4P", var_first, "First variant of each glyph in MD_VAR_LIST.")
    lines += fortran_array("MD_VAR_LIST", "I4P", var_list or [0], "Size variants, glyph numbers.")
    lines += fortran_array("MD_SSTY1", "I4P", st1, "Script alternate of each glyph, 0 none.")
    lines += fortran_array("MD_SSTY2", "I4P", st2, "Scriptscript alternate of each glyph, 0 none.")
    lines.append(f"integer(I4P), parameter :: MD_HALF = {half} !< Glyphs whose outlines are here, the others' in "
                 "foresight_mathfont_outlines.")

    def outline_arrays(part: dict, suffix: str) -> list[str]:
        out = fortran_array(f"MD_PATH_START{suffix}", "I4P", part["PATH_START"], "First operation of each glyph.")
        out += fortran_array(f"MD_POINT_START{suffix}", "I4P", part["POINT_START"], "First point of each glyph.")
        out += fortran_array(f"MD_OPS{suffix}", "I4P", part["OPS"], "Outline operations.")
        pts = part["POINTS"]
        assert all(-16384 <= v < 16384 for v in pts)
        packed = [(pts[i] + 16384) * 32768 + pts[i + 1] + 16384 for i in range(0, len(pts), 2)]
        return out + fortran_array(f"MD_POINTS{suffix}", "I4P", packed, "Outline points, (x + 16384) * 32768 + y + 16384.")

    lines += outline_arrays(parts[0], "1")
    lines.append("endmodule foresight_mathfont_data")
    with open(os.path.join(root, "foresight_mathfont_data.F90"), "w") as f:
        f.write("\n".join(lines) + "\n")
    head = ("foresight_mathfont_outlines, the outlines of the second half of foresight_mathfont's glyphs (generated by "
            "scripts/gen_mathfont.py: do not edit).")
    lines = [f"!< {head}", "module foresight_mathfont_outlines", f"!< {head}", "!<"] + wrap_comment(NOTICE)
    lines += ["use penf, only : I4P", "", "implicit none", "private",
              "public :: MD_PATH_START2, MD_POINT_START2, MD_OPS2, MD_POINTS2", ""]
    lines += outline_arrays(parts[1], "2")
    lines.append("endmodule foresight_mathfont_outlines")
    with open(os.path.join(root, "foresight_mathfont_outlines.F90"), "w") as f:
        f.write("\n".join(lines) + "\n")

    # the submodule
    head = "foresight_mathfont_lookup, the glyph lookup of foresight_mathfont (generated by scripts/gen_mathfont.py: do not edit)."
    lines = [f"!< {head}", "submodule (foresight_mathfont) foresight_mathfont_lookup", f"!< {head}",
             "use foresight_mathfont_data", "use foresight_mathfont_outlines", "", "implicit none", "", "contains"]
    lines += ["   pure module function math_glyph(code) result(value)", "   !< Binary search of the sorted codes.",
              "   integer(I4P), intent(in) :: code  !< Code point.", "   integer(I4P)             :: value !< Glyph.",
              "   integer(I4P)             :: lo    !< Lower bound.", "   integer(I4P)             :: hi    !< Upper bound.",
              "   integer(I4P)             :: mid   !< Middle.", "", "   value = 0_I4P", "   lo = 1_I4P",
              "   hi = MATH_GLYPHS", "   do while (lo <= hi)", "      mid = (lo + hi) / 2_I4P",
              "      if (MD_CODE(mid) == code) then", "         value = mid", "         return",
              "      elseif (MD_CODE(mid) < code) then", "         lo = mid + 1_I4P", "      else",
              "         hi = mid - 1_I4P", "      endif", "   enddo", "   endfunction math_glyph", ""]
    for fn, arr in [("math_code", "CODE"), ("math_unicode", "UNICODE"), ("math_advance", "ADVANCE"),
                    ("math_italic", "ITALIC"), ("math_accent", "ACCENT"), ("math_ymin", "YMIN"), ("math_ymax", "YMAX")]:
        lines += [f"   pure module function {fn}(glyph) result(value)", f"   !< MD_{arr} of the glyph, 0 out of range.",
                  "   integer(I4P), intent(in) :: glyph !< Glyph number.",
                  "   integer(I4P)             :: value !< Value.", "",
                  "   value = 0_I4P",
                  f"   if (glyph >= 1_I4P .and. glyph <= MATH_GLYPHS) value = MD_{arr}(glyph)",
                  f"   endfunction {fn}", ""]
    lines += ["   pure module function math_variant(glyph, k) result(value)", "   !< MD_VAR_LIST of the glyph.",
              "   integer(I4P), intent(in) :: glyph !< Glyph number.", "   integer(I4P), intent(in) :: k     !< Variant.",
              "   integer(I4P)             :: value !< Glyph number.", "", "   value = 0_I4P",
              "   if (glyph < 1_I4P .or. glyph > MATH_GLYPHS .or. k < 1_I4P) return",
              "   if (MD_VAR_FIRST(glyph) + k - 1_I4P < MD_VAR_FIRST(glyph + 1_I4P)) &",
              "      value = MD_VAR_LIST(MD_VAR_FIRST(glyph) + k - 1_I4P)", "   endfunction math_variant", "",
              "   pure module function math_script_glyph(glyph, level) result(value)", "   !< MD_SSTY1, MD_SSTY2.",
              "   integer(I4P), intent(in) :: glyph !< Glyph number.", "   integer(I4P), intent(in) :: level !< Level.",
              "   integer(I4P)             :: value !< Glyph number.", "", "   value = glyph",
              "   if (glyph < 1_I4P .or. glyph > MATH_GLYPHS) return",
              "   if (level == 1_I4P .and. MD_SSTY1(glyph) > 0_I4P) value = MD_SSTY1(glyph)",
              "   if (level >= 2_I4P .and. MD_SSTY2(glyph) > 0_I4P) value = MD_SSTY2(glyph)",
              "   endfunction math_script_glyph", "",
              "   pure module subroutine math_outline(glyph, ops, points)",
              "   !< MD_OPS and the unpacked MD_POINTS of the glyph, element by element (nvfortran 26.9 -O2: bug 36).",
              "   integer(I4P),              intent(in)  :: glyph     !< Glyph number.",
              "   integer(I4P), allocatable, intent(out) :: ops(:)    !< Operations.",
              "   integer(I4P), allocatable, intent(out) :: points(:) !< Points, x and y.",
              "   integer(I4P)                           :: k         !< Counter.",
              "   integer(I4P)                           :: p         !< Packed point.", "",
              "   integer(I4P)                           :: g         !< Glyph in its half.", "",
              "   if (glyph < 1_I4P .or. glyph > MATH_GLYPHS) then", "      allocate(ops(0), points(0))", "      return",
              "   endif", "   if (glyph <= MD_HALF) then", "      g = glyph",
              "      allocate(ops(MD_PATH_START1(g + 1_I4P) - MD_PATH_START1(g)))",
              "      do k = 1_I4P, size(ops, kind=I4P)", "         ops(k) = MD_OPS1(MD_PATH_START1(g) + k - 1_I4P)",
              "      enddo", "      allocate(points(2_I4P * (MD_POINT_START1(g + 1_I4P) - MD_POINT_START1(g))))",
              "      do k = 1_I4P, size(points, kind=I4P) / 2_I4P",
              "         p = MD_POINTS1(MD_POINT_START1(g) + k - 1_I4P)",
              "         points(2_I4P * k - 1_I4P) = p / 32768_I4P - 16384_I4P",
              "         points(2_I4P * k) = mod(p, 32768_I4P) - 16384_I4P", "      enddo", "   else",
              "      g = glyph - MD_HALF", "      allocate(ops(MD_PATH_START2(g + 1_I4P) - MD_PATH_START2(g)))",
              "      do k = 1_I4P, size(ops, kind=I4P)", "         ops(k) = MD_OPS2(MD_PATH_START2(g) + k - 1_I4P)",
              "      enddo", "      allocate(points(2_I4P * (MD_POINT_START2(g + 1_I4P) - MD_POINT_START2(g))))",
              "      do k = 1_I4P, size(points, kind=I4P) / 2_I4P",
              "         p = MD_POINTS2(MD_POINT_START2(g) + k - 1_I4P)",
              "         points(2_I4P * k - 1_I4P) = p / 32768_I4P - 16384_I4P",
              "         points(2_I4P * k) = mod(p, 32768_I4P) - 16384_I4P", "      enddo", "   endif",
              "   endsubroutine math_outline",
              "endsubmodule foresight_mathfont_lookup"]
    with open(os.path.join(root, "foresight_mathfont_lookup.F90"), "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"gen_mathfont: {len(glyphs)} glyphs, {len(var_list)} variants, {sum(1 for s in st1 if s)} script alternates")


if __name__ == "__main__":
    main()
