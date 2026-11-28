# the runs of a mesh study (mesh.dat: a header row, then one run per line) as a Markdown table
set datafile columnheaders
set table 'pf02_runs.md' markdown
plot 'mesh.dat' using (strcol(1)):'cells':'error':'time' with table
unset table
