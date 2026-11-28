// Markdown tables written by foresight (`set table ... markdown`, `with table markdown`), parsed back by markdown-it, the
// CommonMark reader VitePress renders with (GFM tables on): every golden table_markdown_N.md gives the expected cells.
// The goldens are checked byte for byte against foresight's output by foresight_script_test (check 303).
//
// Usage: node src/js/markdown_tables_test.js (from the repository root or src/js; `npm ci` in src/js first)
'use strict';

const fs = require('fs');
const path = require('path');
const MarkdownIt = require('markdown-it');

const goldens = path.join(__dirname, '..', 'tests', 'goldens');

// each file: its tables, each [header, rows...] and the paragraph before it (the series title), null if none
const expected = {
  'table_markdown_1.md': [
    { title: 'x squared', align: ['right', 'right'],
      cells: [['x', 'y'], ['0', '0.000'], ['0.5', '0.250'], ['1', '1.000']] },
    { title: null, align: ['right', 'right'],
      cells: [['x', 'y'], ['0', '1.000'], ['0.5', '0.500'], ['1', '0.000']] },
  ],
  'table_markdown_2.md': [
    { title: null, align: ['right', 'right'],
      cells: [['2', '($3*1e3)'], ['32', '12'], ['64', '3.1'], ['128', '0.79']] },
  ],
  'table_markdown_3.md': [
    { title: null, align: [null, 'right', null],
      cells: [['case', 'error', "(sprintf('%d|%d', $2, 2*$2))"], ['coarse', '0.012', '32|64'],
              ['medium', '0.0031', '64|128'], ['fine', '0.00079', '128|256']] },
  ],
  'table_markdown_4.md': [
    { title: 'Runs', align: ['right', 'right', null],
      cells: [['x', 'y', 'label'], ['32 K', '0.012', 'coarse'], ['64 K', '0.0031', 'medium'],
              ['128 K', '0.00079', 'fine']] },
  ],
};

// the tables of a token stream: cells as text, column alignments, the paragraph right before each
function tables(tokens) {
  const out = [];
  let paragraph = null;
  let current = null;
  let row = null;
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t.type === 'paragraph_open' && !current) {
      paragraph = tokens[i + 1].content;
    } else if (t.type === 'table_open') {
      current = { title: paragraph, align: [], cells: [] };
      paragraph = null;
    } else if (t.type === 'tr_open') {
      row = [];
    } else if ((t.type === 'th_open' || t.type === 'td_open') && current) {
      const style = t.attrGet('style');
      if (t.type === 'th_open') current.align.push(style ? style.replace('text-align:', '') : null);
      row.push(tokens[i + 1].content);
    } else if (t.type === 'tr_close') {
      current.cells.push(row);
    } else if (t.type === 'table_close') {
      out.push(current);
      current = null;
    } else if (t.type === 'paragraph_close') {
      // a paragraph not followed by a table is no title
    } else if (!current && t.type !== 'inline') {
      paragraph = null;
    }
  }
  return out;
}

const md = new MarkdownIt();
let failed = 0;
let checked = 0;
for (const [file, want] of Object.entries(expected)) {
  const got = tables(md.parse(fs.readFileSync(path.join(goldens, file), 'utf8'), {}));
  const same = JSON.stringify(got) === JSON.stringify(want);
  checked += 1;
  if (!same) {
    failed += 1;
    console.log(`FAIL ${file}\n  got:      ${JSON.stringify(got)}\n  expected: ${JSON.stringify(want)}`);
  }
}
console.log(`${checked - failed}/${checked} Markdown tables parsed back into their cells`);
process.exit(failed ? 1 : 0);
