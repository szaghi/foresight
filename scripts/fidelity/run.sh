#!/usr/bin/env bash
# run.sh FORESIGHT TAG [-j N] [demo.dem ...]: render the demos page by page with gnuplot 6.0 and with FORESIGHT (the
# CLI binary), then score every page pair (score.py) into $W/scores_TAG.txt.
#
#   $W = $FORESIGHT_FIDELITY (default ~/.cache/foresight-fidelity), prepared by fetch.sh
#   gnuplot's pages go to $W/gp once (delete the directory to render them again), foresight's to $W/fs_TAG
#   the demos default to scripts/fidelity/demos.txt; -j sets the parallel jobs (default: the processors)
#
# Compare two runs with compare.py, e.g. against the committed baseline:
#   python3 scripts/fidelity/compare.py scripts/fidelity/baseline/scores.txt $W/scores_TAG.txt
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
W=${FORESIGHT_FIDELITY:-$HOME/.cache/foresight-fidelity}
F=$(readlink -f "$1"); TAG=$2; shift 2
J=$(nproc)
if [ "${1:-}" = -j ]; then J=$2; shift 2; fi
[ -d "$W/demo" ] || { echo "run.sh: $W/demo missing: run scripts/fidelity/fetch.sh first" >&2; exit 1; }
if [ $# -gt 0 ]; then list="$*"; else list=$(cat "$here/demos.txt"); fi
mkdir -p "$W/gp" "$W/fs_$TAG"
render() {  # render DEMO: gnuplot (when its first page is missing) and foresight, in a private copy of demo/
  local d=$1 b=${1%.dem} job=$W/jobs/${1%.dem}
  # demos write side files (fit.log, *.tmp, tables) where they run: each demo runs in its own copy (6.7 MB)
  rm -rf "$job"; cp -r "$W/demo" "$job"; cd "$job" || return 0
  if ! ls "$W/gp/${b}_p01.svg" > /dev/null 2>&1; then
    timeout 60 gnuplot -c "fid_$d" "$W/gp" < /dev/null > /dev/null 2>&1
    rm -rf "$job"; cp -r "$W/demo" "$job"; cd "$job" || return 0
  fi
  rm -f "$W/fs_$TAG/${b}"_p[0-9][0-9].svg
  timeout 60 "$F" -c "fid_$d" "$W/fs_$TAG" < /dev/null > /dev/null 2> "$W/fs_$TAG/$b.err"
  cd "$W"; rm -rf "$job"
  return 0
}
export -f render
export W F TAG
mkdir -p "$W/jobs"
printf '%s\n' $list | xargs -P "$J" -I{} bash -c 'render "$@"' _ {}
echo "run.sh: rendered $(printf '%s\n' $list | wc -l) demos into $W/fs_$TAG"
printf '%s\n' $list > "$W/fs_$TAG/demos.txt"
python3 -I "$here/score.py" "$TAG" -j "$J"
