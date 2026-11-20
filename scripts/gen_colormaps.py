#!/usr/bin/env python3
"""Generate ``src/lib/foresight_colormaps.F90``, the tables of the named palettes.

The tables come from the original releases, never from a translation:

- the 40 continuous maps of the *Scientific colour maps* v8.0.1 by Fabio Crameri (MIT),
  Crameri's 8-bit ``<name>/<name>.lut`` files of ``ScientificColourMaps8.zip`` (checked
  against the 6-decimal ``<name>/<name>.txt``: within 1 per channel),
  https://zenodo.org/records/8409685 (doi:10.5281/zenodo.8409685);
- magma, inferno, plasma and viridis by Nathaniel J. Smith, Stefan van der Walt and
  Eric Firing (CC0), ``colormaps.py`` of https://github.com/BIDS/colormap.

The matplotlib colors, 0 to 1 per channel, are rounded half up to 8 bits; the 256 colors of a map are
written as ``rrggbb``. The inputs are parsed as text, never executed. Run by hand (it
needs the downloaded inputs, not available in CI):

    python3 scripts/gen_colormaps.py --crameri DIR --bids colormaps.py \
        --output src/lib/foresight_colormaps.F90
"""

from __future__ import annotations

import argparse
import hashlib
import math
import re
import sys
from pathlib import Path

CRAMERI = (
    "acton bam bamako bamO batlow batlowK batlowW berlin bilbao broc brocO buda bukavu "
    "cork corkO davos devon fes glasgow grayC hawaii imola lajolla lapaz lipari lisbon "
    "managua navia naviaW nuuk oleron oslo roma romaO tofino tokyo turku vanimo vik vikO"
).split()
BIDS = ("magma", "inferno", "plasma", "viridis")
LEVELS = 256
PER_LINE = 12  # colors per source line, as the former VIRIDIS constant
NAME_LEN = 7


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


def constant(name: str) -> str:
    """Fortran name of the table constant of a map.

    Parameters
    ----------
    name : str
        Map name.

    Returns
    -------
    str
        Constant name, e.g. ``CM_BATLOWK``.
    """
    return f"CM_{name.upper()}"


def fortran_table(
    name: str, colors: list[tuple[int, int, int]], origin: str
) -> list[str]:
    """Source lines of the table constant of a map.

    Parameters
    ----------
    name : str
        Map name.
    colors : list of tuple of int
        The 256 colors.
    origin : str
        Short credit for the docstring.

    Returns
    -------
    list of str
        The ``character(len=*), parameter`` statement.
    """
    hexes = "".join(f"{r:02x}{g:02x}{b:02x}" for r, g, b in colors)
    step = 6 * PER_LINE
    chunks = [hexes[i : i + step] for i in range(0, len(hexes), step)]
    lines = [f"character(len=*), parameter :: {constant(name)} = &"]
    lines += [f"   '{c}' // &" for c in chunks[:-1]]
    lines.append(f"   '{chunks[-1]}' !< {name}, {origin}.")
    return lines


def fortran_module(
    maps: list[tuple[str, list[tuple[int, int, int]], str]], sources: list[str]
) -> str:
    """The whole generated module.

    Parameters
    ----------
    maps : list of tuple
        ``(name, colors, origin)`` per map, in table order.
    sources : list of str
        One line per input file: what, where, sha256.

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
        "use penf, only : I4P",
        "",
        "implicit none",
        "private",
        "public :: COLORMAPS",
        "public :: COLORMAP_NAMES",
        "public :: colormap_hex",
        "public :: colormap_id",
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
    except (ColormapError, OSError, ValueError) as err:
        print(f"gen_colormaps: {err}", file=sys.stderr)
        return 1
    zip_sum = sha256(args.crameri_zip) if args.crameri_zip else "not recorded"
    sources = [
        "- Scientific colour maps 8.0.1, F. Crameri: <name>/<name>.lut of ScientificColourMaps8.zip,",
        "  https://zenodo.org/records/8409685,",
        f"  sha256 {zip_sum};",
        "- mpl-colormaps: colormaps.py of https://github.com/BIDS/colormap, commit bc549477db0c,",
        f"  sha256 {sha256(args.bids)}.",
    ]
    args.output.write_text(fortran_module(maps, sources), encoding="ascii")
    return 0


if __name__ == "__main__":
    sys.exit(main())
