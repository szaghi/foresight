#!/usr/bin/env python3
"""prep.py LIST DEMODIR: for each demo in LIST, write DEMODIR/fid_<name>.dem, a copy writing one SVG page per pause.

The copy sets `set terminal svg size 600,400`, comments out the demo's own `set terminal` lines and opens a new output
`ARG1/<name>_pNN.svg` at each `pause`, so gnuplot 6.0 and foresight render the same pages into the directory given as
the script's first argument (`gnuplot -c fid_x.dem DIR`, `foresight -c fid_x.dem DIR`).
"""

from __future__ import annotations

import os
import re
import sys

TERM = re.compile(r"^\s*set\s+(term|termi|termin|termina|terminal)\b(?!option)")
PAUSE = re.compile(r"^\s*pause\b")


def prepare(name: str, demodir: str) -> None:
    """Write the paged copy of one demo."""
    with open(os.path.join(demodir, name), errors="replace") as f:
        src = f.read().split("\n")
    base = name[:-4]
    lines = [
        "set terminal svg size 600,400",
        "FID_N = 1",
        "FID_DIR = ARG1",
        f"set output sprintf('%s/{base}_p%02d.svg', FID_DIR, FID_N)",
    ]
    cont = False
    for line in src:
        if not cont and TERM.match(line):
            lines.append("# " + line)
        elif not cont and PAUSE.match(line):
            lines.append(f"FID_N = FID_N + 1; set output sprintf('%s/{base}_p%02d.svg', FID_DIR, FID_N)")
        else:
            lines.append(line)
        cont = line.rstrip().endswith("\\")
    lines.append("set output")
    with open(os.path.join(demodir, "fid_" + name), "w") as f:
        f.write("\n".join(lines) + "\n")


def main() -> None:
    """Prepare every demo of the list."""
    with open(sys.argv[1]) as f:
        names = [line.strip() for line in f if line.strip()]
    for name in names:
        prepare(name, sys.argv[2])


if __name__ == "__main__":
    main()
