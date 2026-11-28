---
title: F3. The report
---

# F3. The report

**Goal:** a whole report, written by the program that has the results: text, three figures with their alternative
texts and numbered captions, a table of statistics and a table of the history.

<<< @/examples/output/pf_report.txt{console}

<<< @/examples/output/pf_report-head.txt{console}

The page it writes is [the run report](./report/report): open it to see the result as VitePress renders it. The
program reads the logs of path A's solver; its parts are below, the whole of it in
[pf_report.f90](https://github.com/szaghi/foresight/blob/master/docs/examples/src/pf_report.f90).

A figure drawn by a script, its caption set there:

<<< @/examples/snippets/pf_report-script-figure.f90{fortran}

A figure of the library:

<<< @/examples/snippets/pf_report-library-figure.f90{fortran}

Each figure goes into the page the same way, numbered:

<<< @/examples/snippets/pf_report-add-figure.f90{fortran}

A table written by the program, of the `stats` of the last iterations:

<<< @/examples/snippets/pf_report-stats-table.f90{fortran}

A table written by a script into the same page, appended after the program closed it:

<<< @/examples/snippets/pf_report-script-table.f90{fortran}

## Why it works

- The report is plain Markdown written with `write`: no dependency, the program decides what is said. The figures and
  tables are files next to it, referenced relatively, so the directory moves as a whole (to a wiki, a repository, a
  web page).
- Scripts and library meet in the same program: `gp%figure` is the figure a script built, saved again with `info` to
  read its alternative text and caption.
- The numbers in the text come from the run, not from a copy: a new run writes a new report.

## Try this

- Render the report outside the site: `pandoc report/report.md -o report.html --standalone`.
- Add a figure of the timing (`timestep.dat` of the cookbook) and a table of its `stats`.

## Pitfalls

- Close the page before a script appends to it, and reopen it with `position='append'` to go on writing.
- Relative image paths are relative to the page: write the figures where the page is, or adjust the paths.
- [BARUCH](https://github.com/szaghi/BARUCH), the Markdown reader and writer of this family of libraries, will write
  such reports with a streaming writer (headings, lists, tables, escapes) when released; foresight does not depend on
  it, and the `figure_info` above is all it needs.
