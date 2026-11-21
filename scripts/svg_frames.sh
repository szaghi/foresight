#!/usr/bin/env bash
# Assemble frames into one animated SVG that loops (SMIL, shown by browsers also in an <img>): each frame is a group
# visible during its share of the loop, the first one visible without animation.
#
#   svg_frames.sh OUT SECONDS FRAME.svg ...                  SVG frames written by foresight
#   svg_frames.sh --text WIDTH,HEIGHT BG,FG OUT SECONDS FRAME.txt ...
#                                                           text frames (a terminal: dumb or block output) drawn as
#                                                           monospace lines on a WIDTHxHEIGHT page, colors BG and FG
#
# SECONDS is the time of each frame; repeat a file to hold it longer. Used by scripts/docs_examples.sh.
set -euo pipefail

text=0
if [ "${1:-}" = --text ]; then
  text=1 size=$2 colors=$3; shift 3
  width=${size%,*} height=${size#*,} bg=${colors%,*} fg=${colors#*,}
fi
out=$1 dt=$2; shift 2
n=$#
[ "$n" -gt 0 ] || { echo "svg_frames: no frame" >&2; exit 1; }

frame_body() { # frame_body FILE: the drawing of a frame, without the XML declaration and the root element
  if [ "$text" = 1 ]; then
    awk -v fg="$fg" 'function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); return s }
                     { printf "<text x=\"8\" y=\"%.1f\" xml:space=\"preserve\" fill=\"%s\">%s</text>\n", 16 + 14 * (NR - 1), fg, esc($0) }' "$1"
  else
    awk 'NR == 1 && /^<\?xml/ { next }
         !root && /^<svg/ { root = 1; next }
         { line[++m] = $0 }
         END { for (i = 1; i < m; i++) print line[i]; if (line[m] != "</svg>") print line[m] }' "$1"
  fi
}

{
  if [ "$text" = 1 ]; then
    printf '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s"' "$width" "$height" "$width" "$height"
    printf ' font-family="DejaVu Sans Mono,Menlo,Consolas,monospace" font-size="12">\n'
    printf '<rect x="0" y="0" width="%s" height="%s" fill="%s"/>\n' "$width" "$height" "$bg"
  else
    sed -n '1,2p' "$1"
  fi
  k=0
  for f in "$@"; do
    if [ "$k" = 0 ]; then
      printf '<g>\n'
      awk -v n="$n" -v dt="$dt" 'BEGIN { printf "<animate attributeName=\"visibility\" values=\"visible;hidden\" keyTimes=\"0;%.6f\" calcMode=\"discrete\" dur=\"%gs\" repeatCount=\"indefinite\"/>\n", 1 / n, n * dt }'
    else
      printf '<g visibility="hidden">\n'
      awk -v k="$k" -v n="$n" -v dt="$dt" 'BEGIN { printf "<animate attributeName=\"visibility\" values=\"hidden;visible;hidden\" keyTimes=\"0;%.6f;%.6f\" calcMode=\"discrete\" dur=\"%gs\" repeatCount=\"indefinite\"/>\n", k / n, (k + 1) / n, n * dt }'
    fi
    frame_body "$f"
    printf '</g>\n'
    k=$((k + 1))
  done
  printf '</svg>\n'
} > "$out"
