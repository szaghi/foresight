#!/usr/bin/env bash
# build_paper.sh [OUT]: build the example paper of path C (docs/examples/paper/paper.tex) with Tectonic, or LuaLaTeX
# when Tectonic is absent, and check it: it compiles, its log has no warning about the figures (a missing or
# oversized graphic, a float too large), and pdffonts lists every font of the paper embedded (the paper's own and the
# figures' Type 3 fonts). The figures are the PDFs of the docs examples (docs/public/examples: run
# scripts/docs_examples.sh first). Writes OUT (default build/paper/paper.pdf).
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out=$(realpath -m "${1:-$root/build/paper/paper.pdf}")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/docs/examples/paper" "$(dirname "$out")"
cp "$root/docs/examples/paper/paper.tex" "$work/docs/examples/paper/"
cp -R "$root/docs/public" "$work/docs/"
cd "$work/docs/examples/paper"
if command -v tectonic > /dev/null; then
  engine=tectonic
  tectonic --keep-logs paper.tex > build.out 2>&1 || { cat build.out; exit 1; }
else
  engine=lualatex
  for pass in 1 2; do
    lualatex -interaction=nonstopmode -halt-on-error paper.tex > build.out 2>&1 || { tail -40 build.out; exit 1; }
  done
fi
# warnings about the figures: a graphic not found or not included, an overfull line of a figure, a float too large
if grep -E "LaTeX Warning: (File|Float too large)|not found|Overfull \\\\hbox|pdf inclusion" paper.log > warnings.txt; then
  echo "build_paper: warnings ($engine):"; cat warnings.txt; exit 1
fi
fonts=$(pdffonts paper.pdf | tail -n +3)
if echo "$fonts" | awk '{ if ($(NF-4) != "yes") bad = 1 } END { exit !bad }'; then
  echo "build_paper: a font is not embedded:"; echo "$fonts"; exit 1
fi
cp paper.pdf "$out"
echo "build_paper: $out ($engine, $(pdfinfo paper.pdf | awk '/^Pages/ {print $2}') pages, $(echo "$fonts" | wc -l) fonts, all embedded)"
