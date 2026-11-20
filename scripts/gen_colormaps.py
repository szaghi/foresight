#!/usr/bin/env python3
"""Generate ``src/lib/foresight_colormaps.F90``, the tables of the named palettes.

The tables come from the original releases, never from a translation:

- the 40 continuous maps of the *Scientific colour maps* v8.0.1 by Fabio Crameri (MIT),
  Crameri's 8-bit ``<name>/<name>.lut`` files of ``ScientificColourMaps8.zip`` (checked
  against the 6-decimal ``<name>/<name>.txt``: within 1 per channel),
  https://zenodo.org/records/8409685 (doi:10.5281/zenodo.8409685);
- magma, inferno, plasma and viridis by Nathaniel J. Smith, Stefan van der Walt and
  Eric Firing (CC0), ``colormaps.py`` of https://github.com/BIDS/colormap;
- cividis by J. R. Nunez, C. R. Anderton and R. S. Renslow, the table its author contributed
  to matplotlib, ``lib/matplotlib/_cm_listed.py`` (matplotlib's licence and the Battelle
  licence of its origin, pnnl/cmaputil: both notices are written into the module);
- the 22 categorical orders of the Scientific colour maps (``<name>S``), their
  ``CategoricalPalettes/<name>S_HEX.txt`` files, checked against the base 8-bit tables;
- black_body by Kenneth Moreland (CC0), his 256-entry byte table
  ``black-body-table-byte-0256.csv`` of https://www.kennethmoreland.com/color-advice/.

The matplotlib colors, 0 to 1 per channel, are rounded half up to 8 bits; the 256 colors of a map are
written as ``rrggbb``. The inputs are parsed as text, never executed. Run by hand (it
needs the downloaded inputs, not available in CI):

    python3 scripts/gen_colormaps.py --crameri DIR --crameri-zip ScientificColourMaps8.zip \
        --bids colormaps.py --cividis _cm_listed.py --mpl-license LICENSE \
        --battelle-license cmaputil/LICENSE --black-body black-body-table-byte-0256.csv \
        --output src/lib/foresight_colormaps.F90
"""

from __future__ import annotations

import argparse
import hashlib
import math
import re
import sys
import textwrap
from pathlib import Path

CRAMERI = (
    "acton bam bamako bamO batlow batlowK batlowW berlin bilbao broc brocO buda bukavu "
    "cork corkO davos devon fes glasgow grayC hawaii imola lajolla lapaz lipari lisbon "
    "managua navia naviaW nuuk oleron oslo roma romaO tofino tokyo turku vanimo vik vikO"
).split()
BIDS = ("magma", "inferno", "plasma", "viridis")
PNNL_DISCLAIMER = (
    "This material was prepared as an account of work sponsored by an agency of the United States Government. "
    "Neither the United States Government nor the United States Department of Energy, nor Battelle, nor any of "
    "their employees, nor any jurisdiction or organization that has cooperated in the development of these "
    "materials, makes any warranty, express or implied, or assumes any legal liability or responsibility for the "
    "accuracy, completeness, or usefulness or any information, apparatus, product, software, or process "
    "disclosed, or represents that its use would not infringe privately owned rights. Reference herein to any "
    "specific commercial product, process, or service by trade name, trademark, manufacturer, or otherwise does "
    "not necessarily constitute or imply its endorsement, recommendation, or favoring by the United States "
    "Government or any agency thereof, or Battelle Memorial Institute. The views and opinions of authors "
    "expressed herein do not necessarily state or reflect those of the United States Government or any agency "
    "thereof. PACIFIC NORTHWEST NATIONAL LABORATORY operated by BATTELLE for the UNITED STATES DEPARTMENT OF "
    "ENERGY under Contract DE-AC05-76RL01830"
)
LEVELS = 256
CATEGORICAL_LEVELS = 100
CATEGORICAL = (
    "acton bamako batlow batlowK batlowW bilbao buda davos devon glasgow grayC hawaii imola lajolla lapaz "
    "lipari navia naviaW nuuk oslo tokyo turku"
).split()
PER_LINE = 12  # colors per source line, as the former VIRIDIS constant
NAME_LEN = 10


class ColormapError(Exception):
    """An input is missing or malformed."""


def to_byte(value: float) -> int:
    """Round a channel in 0..1 half up to 0..255.

    Parameters
    ----------
    value : float
        Channel intensity, 0 to 1.

    Returns
    -------
    int
        Channel, 0 to 255.
    """
    return min(255, max(0, math.floor(255.0 * value + 0.5)))


def check_table(name: str, rows: list[list[float]]) -> list[tuple[int, int, int]]:
    """Validate a table of float colors and round it to bytes.

    Parameters
    ----------
    name : str
        Map name, for the messages.
    rows : list of list of float
        The colors, three channels 0..1 each.

    Returns
    -------
    list of tuple of int
        The 256 colors, 8-bit channels.

    Raises
    ------
    ColormapError
        If the table has not 256 colors of three channels in 0..1.
    """
    if len(rows) != LEVELS or any(len(r) != 3 for r in rows):  # noqa: PLR2004
        msg = f"{name}: {len(rows)} colors, {LEVELS} RGB triplets expected"
        raise ColormapError(msg)
    if any(not 0.0 <= v <= 1.0 for r in rows for v in r):
        msg = f"{name}: a channel outside 0..1"
        raise ColormapError(msg)
    return [(to_byte(r[0]), to_byte(r[1]), to_byte(r[2])) for r in rows]


def read_crameri(root: Path, name: str) -> list[tuple[int, int, int]]:
    """Read a Scientific colour map from ``root/<name>/<name>.lut``, checked against its ``.txt``.

    The 8-bit ``.lut`` is Crameri's own rounding of his full-precision data; rounding the
    6-decimal ``.txt`` instead differs by 1 where a value is within 1e-4 of a half unit.

    Parameters
    ----------
    root : Path
        The extracted ``ScientificColourMaps8`` directory.
    name : str
        Map name.

    Returns
    -------
    list of tuple of int
        The 256 colors.

    Raises
    ------
    ColormapError
        If the ``.lut`` is malformed or differs from the ``.txt`` by more than 1.
    """
    text = (root / name / f"{name}.txt").read_text(encoding="ascii")
    rows = [
        [float(v) for v in line.split()] for line in text.splitlines() if line.strip()
    ]
    rounded = check_table(name, rows)
    lut_text = (root / name / f"{name}.lut").read_text(encoding="ascii")
    lut = [
        tuple(int(v) for v in line.split())
        for line in lut_text.splitlines()
        if line.strip()
    ]
    if len(lut) != LEVELS or any(
        len(c) != 3 or any(not 0 <= v <= 255 for v in c)
        for c in lut  # noqa: PLR2004
    ):
        msg = f"{name}: malformed .lut"
        raise ColormapError(msg)
    if any(
        abs(a - b) > 1
        for c, r in zip(lut, rounded, strict=True)
        for a, b in zip(c, r, strict=True)
    ):
        msg = f"{name}: .lut and .txt differ by more than 1"
        raise ColormapError(msg)
    return [(c[0], c[1], c[2]) for c in lut]


def read_categorical(root: Path, name: str) -> list[tuple[int, int, int]]:
    """Read a categorical Scientific colour map, ``root/<name>/CategoricalPalettes/<name>S_HEX.txt``.

    Its 100 colors, ``r g b<TAB>label #RRGGBB`` rows, are an order of colors of the base map, the
    most distinct first; the generator checks the triplets against the hexadecimal codes and the
    base map's 8-bit table.

    Parameters
    ----------
    root : Path
        The extracted ``ScientificColourMaps8`` directory.
    name : str
        Base map name (``batlow`` for ``batlowS``).

    Returns
    -------
    list of tuple of int
        The 100 colors.

    Raises
    ------
    ColormapError
        If the file is malformed or a color is not one of the base map.
    """
    text = (root / name / "CategoricalPalettes" / f"{name}S_HEX.txt").read_text(
        encoding="ascii"
    )
    rows = [line for line in text.splitlines() if re.search(r"#[0-9A-Fa-f]{6}", line)]
    colors = [tuple(int(v) for v in row.split()[:3]) for row in rows]
    codes = [
        m.group(1).lower()
        for row in rows
        if (m := re.search(r"#([0-9A-Fa-f]{6})", row))
    ]
    base = read_crameri(root, name)
    if len(colors) != CATEGORICAL_LEVELS or any(
        f"{c[0]:02x}{c[1]:02x}{c[2]:02x}" != h
        for c, h in zip(colors, codes, strict=True)
    ):
        msg = f"{name}S: {CATEGORICAL_LEVELS} colors with matching codes expected"
        raise ColormapError(msg)
    if any(c not in base for c in colors):
        msg = f"{name}S: a color is not one of {name}"
        raise ColormapError(msg)
    return [(c[0], c[1], c[2]) for c in colors]


def read_moreland(path: Path) -> list[tuple[int, int, int]]:
    """Read Kenneth Moreland's 256-entry byte table (``scalar,RGB_r,RGB_g,RGB_b`` CSV).

    Parameters
    ----------
    path : Path
        ``black-body-table-byte-0256.csv``.

    Returns
    -------
    list of tuple of int
        The 256 colors.

    Raises
    ------
    ColormapError
        If the table is not 256 rows of three bytes after the header.
    """
    lines = [
        line for line in path.read_text(encoding="ascii").splitlines() if line.strip()
    ]
    if not lines or lines[0].strip() != "scalar,RGB_r,RGB_g,RGB_b":
        msg = f"{path.name}: header scalar,RGB_r,RGB_g,RGB_b expected"
        raise ColormapError(msg)
    rows = [tuple(int(v) for v in line.split(",")[1:]) for line in lines[1:]]
    if len(rows) != LEVELS or any(
        len(r) != 3 or any(not 0 <= v <= 255 for v in r)
        for r in rows  # noqa: PLR2004
    ):
        msg = f"{path.name}: {LEVELS} rows of three bytes expected"
        raise ColormapError(msg)
    return [(r[0], r[1], r[2]) for r in rows]


def read_bids(text: str, name: str) -> list[tuple[int, int, int]]:
    """Read ``_<name>_data = [[r, g, b], ...]`` from a matplotlib-style listed colormap file.

    Parameters
    ----------
    text : str
        The file content.
    name : str
        Map name.

    Returns
    -------
    list of tuple of int
        The 256 colors.

    Raises
    ------
    ColormapError
        If the list is not found.
    """
    match = re.search(rf"_{name}_data\s*=\s*\[(.*?)\]\]", text, re.DOTALL)
    if match is None:
        msg = f"{name}: _{name}_data not found"
        raise ColormapError(msg)
    rows = [
        [float(v) for v in triplet.split(",")]
        for triplet in re.findall(r"\[([^\[\]]+)\]", match.group(1) + "]")
    ]
    return check_table(name, rows)


def sha256(path: Path) -> str:
    """Hexadecimal SHA-256 of a file.

    Parameters
    ----------
    path : Path
        File.

    Returns
    -------
    str
        Digest.
    """
    return hashlib.sha256(path.read_bytes()).hexdigest()


def constant(name: str, prefix: str = "CM_") -> str:
    """Fortran name of the table constant of a map.

    Parameters
    ----------
    name : str
        Map name.
    prefix : str
        Constant name prefix: ``CM_`` palettes, ``CS_`` categorical orders.

    Returns
    -------
    str
        Constant name, e.g. ``CM_BATLOWK``.
    """
    return f"{prefix}{name.upper()}"


def fortran_table(
    name: str, colors: list[tuple[int, int, int]], origin: str, prefix: str = "CM_"
) -> list[str]:
    """Source lines of the table constant of a map.

    Parameters
    ----------
    name : str
        Map name.
    colors : list of tuple of int
        The colors.
    origin : str
        Short credit for the docstring.
    prefix : str
        Constant name prefix.

    Returns
    -------
    list of str
        The ``character(len=*), parameter`` statement.
    """
    hexes = "".join(f"{r:02x}{g:02x}{b:02x}" for r, g, b in colors)
    step = 6 * PER_LINE
    chunks = [hexes[i : i + step] for i in range(0, len(hexes), step)]
    lines = [f"character(len=*), parameter :: {constant(name, prefix)} = &"]
    lines += [f"   '{c}' // &" for c in chunks[:-1]]
    lines.append(f"   '{chunks[-1]}' !< {name}, {origin}.")
    return lines


def fortran_module(
    maps: list[tuple[str, list[tuple[int, int, int]], str]],
    sources: list[str],
    notices: list[str],
    categoricals: list[tuple[str, list[tuple[int, int, int]]]],
) -> str:
    """The whole generated module.

    Parameters
    ----------
    maps : list of tuple
        ``(name, colors, origin)`` per map, in table order.
    sources : list of str
        One line per input file: what, where, sha256.
    notices : list of str
        Further licence notices, one comment line each.
    categoricals : list of tuple
        ``(name, colors)`` per categorical order (100 colors), in table order.

    Returns
    -------
    str
        Fortran source.
    """
    count = len(maps)
    names = ", ".join(f"'{n:<{NAME_LEN}}'" for n, _, _ in maps)
    tables = ", ".join(constant(n) for n, _, _ in maps)
    out = [
        "!< foresight_colormaps, the tables of the named palettes (generated: do not edit).",
        "module foresight_colormaps",
        "!< foresight_colormaps, the tables of the named palettes (generated: do not edit).",
        "!<",
        "!< Generated by `scripts/gen_colormaps.py` from:",
        *[f"!< {s}" for s in sources],
        "!<",
        "!< Each map is 256 colors `rrggbb`: Crameri's 8-bit tables, the matplotlib ones rounded half up from 0..1.",
        "!<",
        "!< The Scientific colour maps (the first 40 tables) are licensed under the MIT License:",
        "!<",
        "!< Copyright (c) 2023, Fabio Crameri",
        "!<",
        "!< Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated",
        '!< documentation files (the "Software"), to deal in the Software without restriction, including without limitation',
        "!< the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and",
        "!< to permit persons to whom the Software is furnished to do so, subject to the following conditions:",
        "!<",
        "!< The above copyright notice and this permission notice shall be included in all copies or substantial portions of",
        "!< the Software.",
        "!<",
        '!< THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO',
        "!< THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE",
        "!< AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF",
        "!< CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER",
        "!< DEALINGS IN THE SOFTWARE.",
        "!<",
        "!< Cite them as: Crameri, F. (2018). Scientific colour maps. Zenodo, doi:10.5281/zenodo.1243862; Crameri, F.,",
        "!< Shephard, G. E., Heron, P. J. (2020). The misuse of colour in science communication. Nature Communications 11,",
        "!< 5444, doi:10.1038/s41467-020-19160-7.",
        "!<",
        "!< magma, inferno, plasma and viridis (mpl-colormaps, Nathaniel J. Smith, Stefan van der Walt and Eric Firing) are",
        "!< dedicated to the public domain (CC0 1.0).",
        "!<",
        "!< black_body (Kenneth Moreland, https://www.kennethmoreland.com/color-advice/) is dedicated to the public",
        "!< domain (CC0).",
        *[f"!< {n}".rstrip() for n in notices],
        "use penf, only : I4P",
        "",
        "implicit none",
        "private",
        "public :: COLORMAPS",
        "public :: COLORMAP_NAMES",
        "public :: colormap_hex",
        "public :: colormap_id",
        "public :: CATEGORICALS",
        "public :: CATEGORICAL_NAMES",
        "public :: CATEGORICAL_LEVELS",
        "public :: categorical_hex",
        "public :: categorical_id",
        "",
        f"integer(I4P), parameter :: COLORMAPS = {count}_I4P !< Number of named palettes.",
    ]
    for name, colors, origin in maps:
        out += fortran_table(name, colors, origin)
    out += [
        f"character(len={NAME_LEN}), parameter :: COLORMAP_NAMES(COLORMAPS) = [ &",
        *wrap(names, "   ", " &"),
        "   ] !< Names, canonical case.",
        f"character(len={6 * LEVELS}), parameter :: TABLES(COLORMAPS) = [ &",
        *wrap(tables, "   ", " &"),
        "   ] !< Tables, in the order of the names.",
        "",
        f"integer(I4P), parameter :: CATEGORICALS = {len(categoricals)}_I4P !< Number of categorical orders.",
        f"integer(I4P), parameter :: CATEGORICAL_LEVELS = {CATEGORICAL_LEVELS}_I4P !< Colors of an order.",
        *[
            line
            for n, c in categoricals
            for line in fortran_table(n, c, "Crameri's categorical order", "CS_")
        ],
        f"character(len={NAME_LEN}), parameter :: CATEGORICAL_NAMES(CATEGORICALS) = [ &",
        *wrap(", ".join(f"'{n:<{NAME_LEN}}'" for n, _ in categoricals), "   ", " &"),
        "   ] !< Categorical order names (`batlowS`: batlow's colors, the most distinct first).",
        f"character(len={6 * CATEGORICAL_LEVELS}), parameter :: CATEGORICAL_TABLES(CATEGORICALS) = [ &",
        *wrap(", ".join(constant(n, "CS_") for n, _ in categoricals), "   ", " &"),
        "   ] !< Categorical tables, in the order of the names.",
        "",
        "contains",
        "   pure function colormap_id(name) result(id)",
        "   !< Index of the named palette `name`, case-insensitive; 0 if unknown.",
        "   character(len=*), intent(in) :: name !< Palette name.",
        "   integer(I4P)                 :: id   !< Index in `COLORMAP_NAMES`, 0 if unknown.",
        "",
        f"   if (len_trim(name) > {NAME_LEN}) then",
        "      id = 0_I4P",
        "      return",
        "   endif",
        "   do id = 1_I4P, COLORMAPS",
        "      if (lower(trim(name)) == lower(trim(COLORMAP_NAMES(id)))) return",
        "   enddo",
        "   id = 0_I4P",
        "   endfunction colormap_id",
        "",
        "   pure function colormap_hex(id, k) result(hex)",
        f"   !< Color `k` (0 to {LEVELS - 1}, clamped) of the named palette `id`, as `rrggbb`.",
        "   integer(I4P), intent(in) :: id  !< Palette index, 1 to `COLORMAPS`.",
        "   integer(I4P), intent(in) :: k   !< Color index.",
        "   character(len=6)         :: hex !< Color.",
        "   integer(I4P)             :: j   !< Clamped color index.",
        "",
        f"   j = min({LEVELS - 1}_I4P, max(0_I4P, k))",
        "   hex = TABLES(id)(6 * j + 1:6 * j + 6)",
        "   endfunction colormap_hex",
        "",
        "   pure function categorical_id(name) result(id)",
        "   !< Index of the categorical order `name` (`batlowS`, ...), case-insensitive; 0 if unknown.",
        "   character(len=*), intent(in) :: name !< Order name.",
        "   integer(I4P)                 :: id   !< Index in `CATEGORICAL_NAMES`, 0 if unknown.",
        "",
        f"   if (len_trim(name) > {NAME_LEN}) then",
        "      id = 0_I4P",
        "      return",
        "   endif",
        "   do id = 1_I4P, CATEGORICALS",
        "      if (lower(trim(name)) == lower(trim(CATEGORICAL_NAMES(id)))) return",
        "   enddo",
        "   id = 0_I4P",
        "   endfunction categorical_id",
        "",
        "   pure function categorical_hex(id, k) result(hex)",
        f"   !< Color `k` (1 to {CATEGORICAL_LEVELS}, clamped) of the categorical order `id`, as `rrggbb`.",
        "   integer(I4P), intent(in) :: id  !< Order index, 1 to `CATEGORICALS`.",
        "   integer(I4P), intent(in) :: k   !< Color index.",
        "   character(len=6)         :: hex !< Color.",
        "   integer(I4P)             :: j   !< Clamped color index, from 0.",
        "",
        f"   j = min({CATEGORICAL_LEVELS - 1}_I4P, max(0_I4P, k - 1_I4P))",
        "   hex = CATEGORICAL_TABLES(id)(6 * j + 1:6 * j + 6)",
        "   endfunction categorical_hex",
        "",
        "   pure function lower(s) result(l)",
        "   !< `s` in lower case (ASCII).",
        "   character(len=*), intent(in) :: s !< String.",
        "   character(len=len(s))        :: l !< Lower case string.",
        "   integer(I4P)                 :: i !< Character counter.",
        "",
        "   l = s",
        "   do i = 1_I4P, len(s, kind=I4P)",
        "      if (s(i:i) >= 'A' .and. s(i:i) <= 'Z') l(i:i) = achar(iachar(s(i:i)) + 32)",
        "   enddo",
        "   endfunction lower",
        "endmodule foresight_colormaps",
        "",
    ]
    return "\n".join(out)


def wrap(items: str, indent: str, cont: str, width: int = 116) -> list[str]:
    """Wrap a comma-separated list into continuation lines.

    Parameters
    ----------
    items : str
        ``a, b, c`` list.
    indent : str
        Line indent.
    cont : str
        Continuation suffix of every line but the last.
    width : int
        Maximum line width before the suffix.

    Returns
    -------
    list of str
        The lines.
    """
    words = items.split(", ")
    lines: list[str] = []
    line = indent
    for i, w in enumerate(words):
        piece = w + ("," if i < len(words) - 1 else "")
        if len(line) + len(piece) + 1 > width and line.strip():
            lines.append(line.rstrip() + cont)
            line = indent
        line += piece + " "
    lines.append(line.rstrip() + cont)
    return lines


def cividis_notices(mpl_license: Path, battelle_license: Path) -> list[str]:
    """Licence notices of the cividis table, as comment lines.

    cividis was contributed to matplotlib by its author (matplotlib PR #9871, 2017), a later
    table than the one of pnnl/cmaputil; the notices of both carry over.

    Parameters
    ----------
    mpl_license : Path
        matplotlib's ``LICENSE/LICENSE``; its agreement for versions 1.3.0 and later is kept.
    battelle_license : Path
        pnnl/cmaputil's ``LICENSE``.

    Returns
    -------
    list of str
        The lines.

    Raises
    ------
    ColormapError
        If matplotlib's agreement is not found.
    """
    mpl = mpl_license.read_text(encoding="utf-8")
    end = mpl.find("License agreement for matplotlib versions prior to 1.3.0")
    if not mpl.startswith("License agreement for matplotlib versions 1.3.0") or end < 0:
        msg = "matplotlib LICENSE: agreement for versions 1.3.0 and later not found"
        raise ColormapError(msg)
    battelle = battelle_license.read_text(encoding="utf-8")
    battelle = battelle.replace("\u201c", '"').replace("\u201d", '"')
    lines = [
        "",
        "cividis (Nunez, J. R., Anderton, C. R., Renslow, R. S. (2018). Optimizing colormaps with consideration for",
        "color vision deficiency to enable accurate interpretation of scientific data. PLoS ONE 13(7), e0199239,",
        "doi:10.1371/journal.pone.0199239) is the table its author contributed to matplotlib (PR #9871). Changes",
        "made: the 256 colors of `_cividis_data` rounded half up to 8 bits and written as `rrggbb`. matplotlib's",
        "notice and licence agreement:",
        "",
        "Copyright (c) 2012- Matplotlib Development Team; All Rights Reserved",
        "",
        *mpl[:end].rstrip().splitlines(),
        "",
        "and the notice, licence and disclaimers of its origin, pnnl/cmaputil:",
        "",
        *battelle.rstrip().splitlines(),
        "",
        *textwrap.wrap(PNNL_DISCLAIMER, 112),
    ]
    if any(not line.isascii() for line in lines):
        msg = "cividis notices: non-ASCII text"
        raise ColormapError(msg)
    return lines


def main(argv: list[str] | None = None) -> int:
    """Command line entry point.

    Parameters
    ----------
    argv : list of str, optional
        Arguments, ``sys.argv[1:]`` if None.

    Returns
    -------
    int
        Exit status.
    """
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--crameri",
        type=Path,
        required=True,
        help="extracted ScientificColourMaps8 dir",
    )
    parser.add_argument(
        "--crameri-zip", type=Path, help="ScientificColourMaps8.zip, for its sha256"
    )
    parser.add_argument(
        "--bids", type=Path, required=True, help="BIDS/colormap colormaps.py"
    )
    parser.add_argument(
        "--cividis",
        type=Path,
        required=True,
        help="matplotlib lib/matplotlib/_cm_listed.py",
    )
    parser.add_argument(
        "--mpl-license", type=Path, required=True, help="matplotlib LICENSE/LICENSE"
    )
    parser.add_argument(
        "--battelle-license", type=Path, required=True, help="pnnl/cmaputil LICENSE"
    )
    parser.add_argument(
        "--black-body",
        type=Path,
        required=True,
        help="Moreland's black-body-table-byte-0256.csv",
    )
    parser.add_argument(
        "--output", type=Path, required=True, help="Fortran module to write"
    )
    args = parser.parse_args(argv)
    try:
        maps = [
            (
                n,
                read_crameri(args.crameri, n),
                "Scientific colour maps 8.0.1, F. Crameri",
            )
            for n in CRAMERI
        ]
        bids_text = args.bids.read_text(encoding="utf-8")
        maps += [(n, read_bids(bids_text, n), "mpl-colormaps (CC0)") for n in BIDS]
        mpl_text = args.cividis.read_text(encoding="utf-8")
        maps.append(("cividis", read_bids(mpl_text, "cividis"), "J. R. Nunez et al."))
        maps.append(("black_body", read_moreland(args.black_body), "K. Moreland (CC0)"))
        categoricals = [
            (f"{n}S", read_categorical(args.crameri, n)) for n in CATEGORICAL
        ]
        notices = cividis_notices(args.mpl_license, args.battelle_license)
    except (ColormapError, OSError, ValueError) as err:
        print(f"gen_colormaps: {err}", file=sys.stderr)
        return 1
    zip_sum = sha256(args.crameri_zip) if args.crameri_zip else "not recorded"
    sources = [
        "- Scientific colour maps 8.0.1, F. Crameri: `NAME/NAME.lut` of ScientificColourMaps8.zip,",
        "  https://zenodo.org/records/8409685,",
        f"  sha256 {zip_sum};",
        "- mpl-colormaps: colormaps.py of https://github.com/BIDS/colormap, commit bc549477db0c,",
        f"  sha256 {sha256(args.bids)};",
        "- cividis: lib/matplotlib/_cm_listed.py of https://github.com/matplotlib/matplotlib, commit 5c4c028dcca3,",
        f"  sha256 {sha256(args.cividis)};",
        "- black_body: black-body-table-byte-0256.csv of",
        "  https://www.kennethmoreland.com/color-advice/black-body/,",
        f"  sha256 {sha256(args.black_body)}.",
    ]
    args.output.write_text(
        fortran_module(maps, sources, notices, categoricals), encoding="ascii"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
