#!/usr/bin/env bash
# Build and run the documentation examples, regenerating everything the pages include from them.
#
#   docs/examples/src/*.f90    example programs (hand-written), with marker comments:
#                                !run ID COMMAND                    a run shown in the pages
#                                !region NAME ... !endregion NAME   a part of the program included on its own
#   docs/examples/src/*.gp     example scripts, run by the foresight command line, with the same markers written
#                              #run ID COMMAND, # region NAME, # endregion NAME; a script without #run lines is run as
#                              `foresight SCRIPT` with its output not shown
#   docs/examples/files/       input files, copied into the directory where the runs happen
#   docs/examples/snippets/    generated: each source without the markers, and <source>-<region>.<ext>, dedented
#   docs/examples/output/      generated: <ID>.txt, "$ COMMAND" then its output (standard output and error)
#   docs/public/examples/      generated: every plot the runs write (.svg, .html), served as /examples/<file> and
#                              embedded live by the pages
#
# The program solver runs first: it writes the logs (run.dat, run.csv) the other examples read. Then the other programs
# and the scripts run, in the order of the files and of the lines. foresight writes byte-identical files from the same
# input (its golden tests check it), so the outputs depend on the sources only. A run happens in a scratch directory with
# a minimal environment. The CI fails when the committed snippets, outputs or plots differ from the regenerated ones.
#
# Usage: bash scripts/docs_examples.sh            (FC=gfortran-14 bash scripts/docs_examples.sh: another compiler)
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ex=$root/docs/examples
public=$root/docs/public/examples
build=$root/build/docs-examples # git-ignored
run_dir=$build/run
home=/home/user                 # how the run directory is shown

fc=${FC:-gfortran}
mkdir -p "$root/build"
# one compilation job at a time: the examples are small, the machine may be busy
(cd "$root" && fobis build --mode foresight-static-gnu --fc "$fc" --jobs 1 && \
               fobis build --mode foresight-gnu --fc "$fc" --jobs 1) > "$root/build/docs-examples.log" 2>&1 || {
  cat "$root/build/docs-examples.log"; echo "docs_examples: library build failed" >&2; exit 1; }
rm -rf -- "$build"
mkdir -p "$build/bin" "$run_dir" "$ex/snippets" "$ex/output" "$public"
rm -f -- "$ex"/snippets/* "$ex"/output/*.txt "$public"/*.svg "$public"/*.html "$public"/*.txt

# snippets: the whole source and each region, without the markers, dedented
markers='^ *(!run |!region |!endregion |#run |# region |# endregion )'
dedent() { awk '{l[NR]=$0; if ($0 ~ /[^ ]/) {match($0, /^ */); if (m == "" || RLENGTH < m) m = RLENGTH}}
                END {for (i = 1; i <= NR; i++) print substr(l[i], m + 1)}' "$1"; }
for src in "$ex"/src/*.f90 "$ex"/src/*.gp; do
  file=$(basename "$src"); name=${file%.*}; ext=${file##*.}
  grep -Ev "$markers" "$src" > "$ex/snippets/$file" || true
  for region in $(sed -n 's/^ *\(!\|# \)region \([A-Za-z0-9_-]*\).*/\2/p' "$src"); do
    awk -v r="$region" '($1 == "!endregion" && $2 == r) || ($1 == "#" && $2 == "endregion" && $3 == r) {on = 0}
                        on && $0 !~ /^ *(!run |!region |!endregion |#run |# region |# endregion )/ {print}
                        ($1 == "!region" && $2 == r) || ($1 == "#" && $2 == "region" && $3 == r) {on = 1}' \
      "$src" > "$build/region"
    dedent "$build/region" > "$ex/snippets/$name-$region.$ext"
  done
done

# programs and the command line
mod=$(find "$root/lib" -name foresight.mod -printf '%h\n' | head -n 1)
for src in "$ex"/src/*.f90; do
  "$fc" -I"$mod" -o "$build/bin/$(basename "$src" .f90)" "$src" "$root/lib/libforesight.a"
done
cp "$root/bin/foresight" "$build/bin/"

# runs, in the run directory holding the input files and the scripts
if [ -d "$ex/files" ]; then cp -R "$ex/files/." "$run_dir/"; fi
cp "$ex"/src/*.gp "$run_dir/"
run() { # run ID COMMAND
  local id=$1; shift
  {
    printf '$ %s\n' "$*"
    (cd "$run_dir" && env -i HOME="$run_dir" PATH="$build/bin:/usr/bin:/bin" LC_ALL=C \
                     GFORTRAN_UNBUFFERED_PRECONNECTED=y bash -c "$*" 2>&1) || printf '[exit status %d]\n' "$?"
  } | sed -e "s|$run_dir|$home|g" > "$ex/output/$id.txt"
}
runs() { # runs SOURCE MARKER: the marked runs of SOURCE
  while IFS= read -r line; do
    line=${line#*"$2" }
    run "${line%% *}" "${line#* }"
  done < <(grep -E "^ *$2 " "$1" || true)
}
runs "$ex/src/solver.f90" '!run'
for src in "$ex"/src/*.f90; do
  [ "$(basename "$src")" = solver.f90 ] || runs "$src" '!run'
done
for src in "$ex"/src/*.gp; do
  if grep -qE '^ *#run ' "$src"; then
    runs "$src" '#run'
  else
    (cd "$run_dir" && env -i HOME="$run_dir" PATH="$build/bin:/usr/bin:/bin" LC_ALL=C \
                     foresight "$(basename "$src")" > /dev/null) || { echo "docs_examples: $src failed" >&2; exit 1; }
  fi
done

# plots
find "$run_dir" -maxdepth 1 \( -name '*.svg' -o -name '*.html' \) -exec cp {} "$public/" \;
if grep -l 'exit status' "$ex"/output/*.txt; then echo "docs_examples: a run failed (see above)" >&2; exit 1; fi
echo "docs_examples: $(ls "$ex"/src/*.f90 "$ex"/src/*.gp | wc -l) sources, $(ls "$ex"/output/*.txt | wc -l) shown runs," \
     "$(ls "$public" | wc -l) plots"
