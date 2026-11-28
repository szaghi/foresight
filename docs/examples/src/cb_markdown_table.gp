#run cb_markdown_table foresight cb_markdown_table.gp && cat cb_markdown_table.md
# region table
set datafile columnheaders
set table 'cb_markdown_table.md' markdown
plot 'mesh.dat' using (strcol(1)):'cells':'error' with table
unset table
# endregion table
