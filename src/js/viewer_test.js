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

var failed = checks.filter(function (c) { return !c.passed; });
checks.forEach(function (c) { console.log((c.passed ? "  PASS  " : "  FAIL  ") + c.name); });
console.log("Are all tests passed? " + (failed.length === 0 ? "T" : "F"));
process.exit(failed.length === 0 ? 0 : 1);
