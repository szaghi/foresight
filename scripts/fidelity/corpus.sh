#!/usr/bin/env bash
# corpus.sh FORESIGHT TAG [-j N]: run every gnuplot 6.0 demo (the whole demo/ directory of fetch.sh, not only
# demos.txt) through FORESIGHT, its own terminal and outputs, and count the demos it draws.
#
# Writes $W/corpus_2d_TAG.txt and $W/corpus_splot_TAG.txt, one line per demo:
#   name|exit status|pages written|first foresight error|warnings (distinct, ';' separated)
# A demo draws when foresight exits 0 having written at least one page ("foresight: <file>" lines on stdout).
# Prints the counts ("splot drawn/total", "2d drawn/total"); with --check, compares them with baseline/corpus_*.txt
# and exits 1 when a demo drawing there no longer draws.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
W=${FORESIGHT_FIDELITY:-$HOME/.cache/foresight-fidelity}
F=$(readlink -f "$1"); TAG=$2; shift 2
J=$(nproc); check=0
while [ $# -gt 0 ]; do
  case $1 in -j) J=$2; shift 2;; --check) check=1; shift;; *) echo "corpus.sh: unknown $1" >&2; exit 2;; esac
done
[ -d "$W/demo" ] || { echo "corpus.sh: $W/demo missing: run scripts/fidelity/fetch.sh first" >&2; exit 1; }
one() {  # one DEMO: a line of the table, in a private copy of demo/
  local f=$1 job=$W/cjobs/${1%.dem} r p e w
  rm -rf "$job"; cp -r "$W/demo" "$job"; cd "$job" || return 0
  r=$(timeout 60 "$F" "$f" < /dev/null > f3.out 2> f3.err; echo $?)
  p=$(grep -c '^foresight: ' f3.out)
  e=$(grep -m1 "foresight: .*:[0-9]*:" f3.err | sed 's/^foresight: //')
  [ -z "$e" ] && [ "$r" != 0 ] && e=$(head -c 200 f3.err | tr '\n' ' ')
  w=$(grep -o 'foresight: warning: .*' f3.err | sort -u | sed 's/foresight: warning: //' | tr '\n' ';')
  echo "$f|$r|$p|$e|$w"
  cd "$W"; rm -rf "$job"
}
export -f one
export W F
mkdir -p "$W/cjobs"
cd "$W/demo"
splot=$(grep -l "^\s*splot\b" *.dem | grep -v -E '^(all|fid_.*)\.dem$' | sort)
twod=$(grep -L "^\s*splot\b" *.dem | grep -v -E '^(all|fid_.*)\.dem$' | sort)
status=0
for mode in splot 2d; do
  if [ $mode = splot ]; then list=$splot; else list=$twod; fi
  out=$W/corpus_${mode}_$TAG.txt
  printf '%s\n' $list | xargs -P "$J" -I{} bash -c 'one "$@"' _ {} | LC_ALL=C sort > "$out"
  n=$(wc -l < "$out"); d=$(awk -F'|' '$2 == 0 && $3 > 0' "$out" | wc -l)
  echo "corpus.sh: $mode $d/$n -> $out"
  if [ $check = 1 ]; then
    base=$here/baseline/corpus_$mode.txt
    lost=$(LC_ALL=C comm -12 <(awk -F'|' '$2 == 0 && $3 > 0 {print $1}' "$base" | LC_ALL=C sort) \
                             <(awk -F'|' '!($2 == 0 && $3 > 0) {print $1}' "$out" | LC_ALL=C sort) | tr '\n' ' ')
    if [ -n "$lost" ]; then echo "corpus.sh: NO LONGER DRAWN ($mode): $lost"; status=1; fi
    bd=$(awk -F'|' '$2 == 0 && $3 > 0' "$base" | wc -l)
    echo "corpus.sh: $mode baseline $bd/$(wc -l < "$base")"
  fi
done
exit $status
