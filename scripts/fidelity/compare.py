#!/usr/bin/env python3
"""compare.py BASE NEW [--tol T] [--worse W]: compare two score files written by score.py.

Prints the totals over the pages drawn by both programs in both runs, the pages whose flag changed (drawn now, no longer
drawn), and the pages worse by more than W (default 0.005), worst first. With --tol T, also checks that every page
present in both files has the same score to T (a reproduction check) and exits 1 when one does not. Exits 1 when a page
is worse by more than W or stopped being drawn. --volatile FILE lists pages left out of the --tol check (volatile.txt:
pages whose gnuplot drawing shows the day they are rendered).
"""

from __future__ import annotations

import argparse
import sys


def load(path: str) -> dict[str, tuple[float, str]]:
    """Page -> (score, flag)."""
    out: dict[str, tuple[float, str]] = {}
    with open(path) as f:
        for line in f:
            parts = line.split(maxsplit=2)
            if len(parts) >= 2:
                out[parts[1]] = (float(parts[0]), parts[2].strip() if len(parts) > 2 else "")
    return out


def main() -> None:
    """Compare and report."""
    ap = argparse.ArgumentParser()
    ap.add_argument("base")
    ap.add_argument("new")
    ap.add_argument("--tol", type=float)
    ap.add_argument("--worse", type=float, default=0.005)
    ap.add_argument("--volatile", help="pages left out of --tol (first word of each line, # comments)")
    a = ap.parse_args()
    base, new = load(a.base), load(a.new)
    common = sorted(set(base) & set(new))
    drawn = [p for p in common if not base[p][1] and not new[p][1]]
    tb, tn = sum(base[p][0] for p in drawn), sum(new[p][0] for p in drawn)
    print(f"pages: base {len(base)}, new {len(new)}, common {len(common)}, drawn by both in both runs {len(drawn)}")
    print(f"total over those: base {tb:.4f}, new {tn:.4f}, change {tn - tb:+.4f}")
    fail = False
    gained = [p for p in common if base[p][1] and not new[p][1]]
    lost = [p for p in common if not base[p][1] and new[p][1]]
    for p in gained:
        print(f"now drawn: {p} (was {base[p][1]})")
    for p in lost:
        print(f"NO LONGER DRAWN: {p} ({new[p][1]})")
        fail = True
    for p in sorted(set(base) - set(new)):
        print(f"only in base: {p}")
    for p in sorted(set(new) - set(base)):
        print(f"only in new: {p}")
    worse = sorted(((new[p][0] - base[p][0], p) for p in drawn if new[p][0] - base[p][0] > a.worse), reverse=True)
    for d, p in worse:
        print(f"worse by {d:.4f}: {p} ({base[p][0]:.4f} -> {new[p][0]:.4f})")
    fail = fail or bool(worse)
    if a.tol is not None:
        skip: set[str] = set()
        if a.volatile:
            with open(a.volatile) as f:
                skip = {line.split()[0] for line in f if line.strip() and not line.startswith("#")}
        checked = [p for p in common if p not in skip]
        off = [(1.0, p) for p in checked if base[p][1] != new[p][1]]
        off += [
            (abs(new[p][0] - base[p][0]), p)
            for p in checked
            if base[p][1] == new[p][1] and abs(new[p][0] - base[p][0]) > a.tol + 1e-12
        ]
        for d, p in sorted(off, reverse=True):
            print(f"NOT REPRODUCED by {d:.4f}: {p} ({base[p][0]:.4f} {base[p][1]} / {new[p][0]:.4f} {new[p][1]})")
        if set(base) != set(new):
            print("NOT REPRODUCED: the page sets differ")
            off.append((1.0, ""))
        print(f"reproduction to {a.tol}: {len(checked) - len(off)}/{len(checked)} pages ({len(skip & set(common))} volatile)")
        fail = fail or bool(off)
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
