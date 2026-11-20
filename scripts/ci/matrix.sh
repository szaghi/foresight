#!/usr/bin/env bash
# The project's pipeline on one toolchain, run by .github/workflows/matrix.yml on each toolchain of the fobos
# [scaffold] matrix, with the fortran-toolchains environment contract: FC, CC, CXX, TOOLCHAIN, TOOLCHAIN_OS and
# TOOLCHAIN_FAMILY (gnu, nvf, intel). Created once by fobis scaffold, then the project's: edit it freely. The same
# script runs locally, in `docker run <image>` and in CI.
#
# foresight: the suite in the debug and the optimized mode of the toolchain (tests-nvf-debug, tests-nvf, ...): the
# nvfortran 26.9 miscompilations worked around in the library show at -O0 or only at -O2 (#3).
set -euo pipefail
echo "toolchain: $TOOLCHAIN ($TOOLCHAIN_OS, $TOOLCHAIN_FAMILY), FC=$FC"
# the matrix workflow does not fetch the dependencies (PENF, BeFoR64, FACE, StringiFor)
fobis fetch
for mode in "tests-$TOOLCHAIN_FAMILY-debug" "tests-$TOOLCHAIN_FAMILY"; do
   echo "::group::$mode"
   rm -rf exe
   fobis build --mode "$mode"
   bash scripts/run_tests.sh
   echo "::endgroup::"
done
