#run pe04 foresight pe04_unsupported.gp; echo "returned $?"
# region unsupported
# a gnuplot command foresight does not have stops the script at its line, with its name
set terminal svg size 600,320
set output 'pe04.svg'
set loadpath 'macros'
plot sin(x)
# endregion unsupported
