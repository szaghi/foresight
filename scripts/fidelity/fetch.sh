#!/usr/bin/env bash
# fetch.sh [--tarball FILE]: prepare the fidelity work directory from gnuplot 6.0.0's release tarball.
#
#   $FORESIGHT_FIDELITY (default ~/.cache/foresight-fidelity) receives
#     gnuplot-6.0.0.tar.gz   the tarball, downloaded once and checked against its SHA-256
#     demo/                  the tarball's demo/ directory, plus binary1-3 (gnuplot's bf_test) and the fid_*.dem copies
#
# The fid_*.dem copies write one 600x400 SVG page per pause (prep.py). The work directory is outside the repository:
# about 110 MB here, 1-2 GB more per scored run.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
W=${FORESIGHT_FIDELITY:-$HOME/.cache/foresight-fidelity}
URL=https://sourceforge.net/projects/gnuplot/files/gnuplot/6.0.0/gnuplot-6.0.0.tar.gz/download
SHA=635a28f0993f6ab0d1179e072ad39b8139d07f51237f841d93c6c2ff4b1758ec
tarball=
if [ "${1:-}" = --tarball ]; then tarball=$2; fi
mkdir -p "$W"
T=$W/gnuplot-6.0.0.tar.gz
if [ -n "$tarball" ]; then cp "$tarball" "$T"; fi
if [ ! -f "$T" ]; then  # SourceForge's mirrors drop connections: retry, resuming the partial file
  for attempt in 1 2 3 4 5; do
    curl -fsSL --retry 3 -C - -o "$T.part" "$URL" && break
    echo "fetch.sh: download attempt $attempt failed" >&2
    sleep 5
  done
  mv "$T.part" "$T"
fi
echo "$SHA  $T" | sha256sum -c --quiet - || { echo "fetch.sh: $T: SHA-256 mismatch (delete it to download again)" >&2; exit 1; }
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
tar xzf "$T" -C "$src" gnuplot-6.0.0/demo gnuplot-6.0.0/src/bf_test.c
rm -rf "$W/demo"
mv "$src/gnuplot-6.0.0/demo" "$W/demo"
# binary1-3: gnuplot's demo Makefile writes them with src/bf_test (config.h unused by it)
mkdir -p "$src/inc"
: > "$src/inc/config.h"
cc -DHAVE_STDLIB_H -I"$src/inc" "$src/gnuplot-6.0.0/src/bf_test.c" -lm -o "$src/bf_test"
(cd "$W/demo" && "$src/bf_test")
python3 -I "$here/prep.py" "$here/demos.txt" "$W/demo"
echo "fetch.sh: $W/demo ready ($(ls "$W/demo" | wc -l) files)"
