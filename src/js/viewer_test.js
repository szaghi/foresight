// Tests of the viewer tick rules: the same cases as src/tests/foresight_ticks_test.F90, which must
// give identical results (the viewer regenerates foresight ticks after a zoom).
//
// Usage: node src/js/viewer_test.js   (also `fobis rule --ex test-js`)
"use strict";

var viewer = require("./viewer.js");
var checks = [];

function check(name, passed) { checks.push({name: name, passed: passed}); }
function labels(ticks) { return ticks.filter(function (t) { return t.major; }); }

var ns = viewer.niceStep(0.4);
check("nice step 0.4", ns.m === 5 && ns.e === -1);
ns = viewer.niceStep(1000);
check("nice step 1000", ns.m === 1 && ns.e === 3);

// gnuplot's step, independent of the length (gnuplot 6.0, 150 to 1200 px): [-2:2] 0.5, [0:1] 0.2,
// [0:13] 2, [0:100] 20, [0:7] 1, [0:0.3] 0.05
function step(ns) { return ns.m * Math.pow(10, ns.e); }
check("gnuplot steps", Math.abs(step(viewer.gnuplotStep(4)) - 0.5) < 1e-12 &&
  Math.abs(step(viewer.gnuplotStep(1)) - 0.2) < 1e-12 && step(viewer.gnuplotStep(13)) === 2 &&
  step(viewer.gnuplotStep(100)) === 20 && step(viewer.gnuplotStep(7)) === 1 &&
  Math.abs(step(viewer.gnuplotStep(0.3)) - 0.05) < 1e-12);

var ticks = viewer.linearTicks(0, 10, 500);
check("linear [0:10]", ticks.length === 6 && ticks[1].label === "2" && ticks[5].label === "10");
check("linear any length", viewer.linearTicks(0, 10, 150).length === 6 &&
  viewer.linearTicks(0, 10, 1500).length === 6);

ticks = viewer.linearTicks(0, 0.3, 150);
check("linear exact labels", ticks.length === 7 && ticks[6].label === "0.3");

ticks = viewer.linearTicks(0, 2e-4, 200);
check("linear scientific", ticks[1].label === "5x10" && ticks[1].sup === "-5" &&
  ticks[3].label === "1.5x10" && ticks[3].sup === "-4" && ticks[0].label === "0");

ticks = viewer.linearTicks(10, 0, 500);
check("linear reversed", ticks.length === 6);

ticks = viewer.logTicks(1e-5, 10, 400);
check("log decades", labels(ticks).length === 7 && ticks.length === 7 + 6 * 8);
check("log labels", ticks[0].label === "10" && ticks[0].sup === "-5");

ticks = viewer.logTicks(2, 8, 400);
check("log plain", labels(ticks).length === 7 && ticks[0].label === "2" && ticks[6].label === "8");

ticks = viewer.logTicks(2.1, 2.3, 150);
// 2.3 - 2.1 is 0.19999999999999996: gnuplot steps by 0.02 too
check("log linear fallback", ticks.length === 11 && ticks[0].label === "2.1" &&
  ticks[10].label === "2.3");

check("decimal strings", viewer.decimalStr(-5, 3) === "-0.005" &&
  viewer.decimalStr(15, -2) === "1500" && viewer.decimalStr(100, 2) === "1");

// user tick settings (the same cases as foresight_ticks_test.F90, on the already extended ranges)
var tics = viewer.readTics("* 0.4 *", "");
ticks = viewer.linearTicks(0, 3.2, 500, tics);
check("fixed step", ticks.length === 9 && ticks[1].label === "0.4" && ticks[8].label === "3.2");
ticks = viewer.linearTicks(0.07, 2.93, 500, viewer.readTics("0.5 0.4 2", ""));
check("fixed start and end", ticks.length === 4 && ticks[0].label === "0.5" &&
  ticks[3].label === "1.7");
check("no ticks", viewer.linearTicks(0, 1, 500, viewer.readTics("none", "")).length === 0);
ticks = viewer.linearTicks(0, 3, 500, viewer.readTics("* 0.25 *", "%.2f"));
check("fixed step format", ticks[0].label === "0.00" && ticks[12].label === "3.00");
ticks = viewer.logTicks(1, 1000, 400, viewer.readTics("* 3 *", ""));
check("log factor", ticks.length === 7 && ticks[0].label === "1" && ticks[6].label === "729");
ticks = viewer.logTicks(1, 1000, 400, viewer.readTics("2 10 *", ""));
check("log factor from start", ticks.length === 3 && ticks[2].label === "200");
// explicit tick lists (set xtics ("label" pos level, ...)): alone, or added to the ticks
ticks = viewer.linearTicks(0, 6.7, 500, viewer.readTics("labels 1e0:a 2.5e0! 5e0:c 9e0:out", ""));
check("list alone", ticks.length === 3 && ticks[0].label === "a" && !ticks[1].major &&
  ticks[1].label === "" && ticks[2].label === "c");
ticks = viewer.linearTicks(0, 7, 500, viewer.readTics("auto labels 3e0:three 3.14e0:pi", ""));
check("list added", ticks.length === 9 && ticks[6].label === "7" && ticks[7].label === "three" &&
  ticks[8].label === "pi" && ticks.every(function (t) { return t.label !== "3"; }));
ticks = viewer.linearTicks(0, 8, 500, viewer.readTics("* 2 * labels 3.14e0:pi", ""));
check("list added to a step", ticks.length === 6 && ticks[1].label === "2" &&
  ticks[5].label === "pi");
ticks = viewer.linearTicks(0, 8, 500, viewer.readTics("labels 2e0:1.5x10^6", ""));
check("list superscript", ticks[0].label === "1.5x10" && ticks[0].sup === "6");
ticks = viewer.linearTicks(0, 4, 500, viewer.readTics("labels 1e0:a%20b 3e0:c", ""));
check("data labels", ticks.length === 2 && ticks[0].label === "a b" && ticks[0].major);

// tick formats (the same cases as foresight_format_test.F90, checked against C printf)
function label(format, n, e) { return viewer.formatDecimal(format, n, e).label; }
check("format half even", label("%.2f", 125, -3) === "0.12" && label("%.0f", 25, -1) === "2" &&
  label("%.0f", 35, -1) === "4");
check("format carry", label("%.1e", 99999, -4) === "1.0e+01");
check("format g", label("%g", 1, 6) === "1e+06" && label("%g", 12345, -2) === "123.45");
check("format flags", label("%+08.3f", -15, -1) === "-001.500" &&
  label("%-6.1f|", 5, -1) === "0.5   |");
check("format text", label("t=%.1fs %%", 3, 0) === "t=3.0s %");
var h = viewer.formatDecimal("%h", 15, 5);
check("format h", h.label === "1.5x10" && h.sup === "6");
var d = viewer.parseDecimal("-0.2500");
check("parse decimal", d.n === -25 && d.e === -2 && viewer.parseDecimal("1.2.3") === null);
d = viewer.decimalOf(0.1);
check("decimal of", d.n === 1 && d.e === -1);

var failed = checks.filter(function (c) { return !c.passed; });
checks.forEach(function (c) { console.log((c.passed ? "  PASS  " : "  FAIL  ") + c.name); });
console.log("Are all tests passed? " + (failed.length === 0 ? "T" : "F"));
process.exit(failed.length === 0 ? 0 : 1);
