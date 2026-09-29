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

var ticks = viewer.linearTicks(0, 10, 500);
check("linear [0:10]", ticks.length === 11 && ticks[1].label === "1" && ticks[10].label === "10");

ticks = viewer.linearTicks(0, 0.3, 150);
check("linear exact labels", ticks.length === 4 && ticks[3].label === "0.3");

ticks = viewer.linearTicks(0, 2e-4, 200);
check("linear scientific", ticks[1].label === "5x10" && ticks[1].sup === "-5" &&
  ticks[3].label === "1.5x10" && ticks[3].sup === "-4" && ticks[0].label === "0");

ticks = viewer.linearTicks(10, 0, 500);
check("linear reversed", ticks.length === 11);

ticks = viewer.logTicks(1e-5, 10, 400);
check("log decades", labels(ticks).length === 7 && ticks.length === 7 + 6 * 8);
check("log labels", ticks[0].label === "10" && ticks[0].sup === "-5");

ticks = viewer.logTicks(2, 8, 400);
check("log plain", labels(ticks).length === 7 && ticks[0].label === "2" && ticks[6].label === "8");

ticks = viewer.logTicks(2.1, 2.3, 150);
check("log linear fallback", ticks.length === 5 && ticks[0].label === "2.1" &&
  ticks[4].label === "2.3");

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
