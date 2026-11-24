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
// the labels' font of an axis: size, weight, style, family (URI-encoded)
var fonted = viewer.readTics("font 8e0 1 0 Lucida%20Sans color #ff0000 * 1 *", "");
check("tics font", fonted.font.size === 8 && fonted.font.bold && !fonted.font.italic &&
  fonted.font.family === "Lucida Sans" && fonted.color === "#ff0000" && fonted.step === "1");
ticks = viewer.linearTicks(0, 3, 500, viewer.readTics("* 0.25 *", "%.2f"));
check("fixed step format", ticks[0].label === "0.00" && ticks[12].label === "3.00");
ticks = viewer.logTicks(1, 1000, 400, viewer.readTics("* 3 *", ""));
check("log factor", labels(ticks).length === 7 && ticks[0].label === "1" &&
  ticks[6].label === "729");
ticks = viewer.logTicks(1, 1000, 400, viewer.readTics("2 10 *", ""));
check("log factor from start", labels(ticks).length === 3 && ticks[2].label === "200");
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
// minor ticks (set mxtics [N]), as gnuplot 6.0: counts of majors + minors
function counts(t) { return labels(t).length + "+" + (t.length - labels(t).length); }
check("minor auto",
  counts(viewer.linearTicks(0, 7, 500, viewer.readTics("auto minor auto", ""))) === "8+28");
check("minor auto step 2",
  counts(viewer.linearTicks(0, 8, 500, viewer.readTics("* 2 * minor auto", ""))) === "5+4");
check("minor N partial ends",
  counts(viewer.linearTicks(0.3, 7.7, 500, viewer.readTics("auto minor auto", ""))) === "7+30");
check("minor bounded series",
  counts(viewer.linearTicks(0, 10, 500, viewer.readTics("2 2 6 minor 2", ""))) === "3+2");
check("minor log N",
  counts(viewer.logTicks(1, 1000, 400, viewer.readTics("auto minor 2", ""))) === "4+3");
check("minor log none",
  counts(viewer.logTicks(1, 1000, 400, viewer.readTics("auto minor 0", ""))) === "4+0");
check("minor log factor",
  counts(viewer.logTicks(1, 1e6, 400, viewer.readTics("* 100 * minor 4", ""))) === "4+9");
// outward ticks and rotated labels (set xtics out rotate by A right)
tics = viewer.readTics("0 2 * minor 4 out rotate 4.5e1 end labels 3e0:c", "");
check("out and rotate", tics.mode === "fixed" && tics.step === "2" && tics.minor === 4 &&
  tics.out && tics.rotate === 45 && tics.anchor === "end" && tics.add && tics.labels.length === 1);
tics = viewer.readTics("auto rotate 9e1 end", "");
check("rotate alone", tics.mode === "auto" && !tics.out && tics.rotate === 90);
check("minor log wide",
  counts(viewer.logTicks(1, 1e20, 400, viewer.readTics("auto minor 2", ""))) === "5+4");
check("minor log wide default",
  counts(viewer.logTicks(1, 1e20, 400, viewer.readTics("", ""))) === "5+32");
check("minor log one decade default",
  counts(viewer.logTicks(1, 1000, 400, viewer.readTics("", ""))) === "4+24");

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

// time axes: the labels gnuplot 6.0 writes over the same ranges (as foresight_ticks_test.F90)
function timeLabels(lo, hi) {
  return labels(viewer.timeTicks(lo, hi, viewer.readTics("", ""), "%s")).map(function (t) {
    return t.label;
  }).join("|");
}
check("time seconds", timeLabels(0, 30) === "00:00|00:05|00:10|00:15|00:20|00:25|00:30");
check("time minutes", timeLabels(1709287200, 1709288400) ===
  "00:00|02:00|04:00|06:00|08:00|10:00|12:00|14:00|16:00|18:00|20:00");
check("time hours", timeLabels(1709287200, 1709366400) === ["01/03\n10:00", "01/03\n12:00",
  "01/03\n14:00", "01/03\n16:00", "01/03\n18:00", "01/03\n20:00", "01/03\n22:00", "02/03\n00:00",
  "02/03\n02:00", "02/03\n04:00", "02/03\n06:00", "02/03\n08:00"].join("|"));
check("time weeks", timeLabels(1709251200, 1714521600) ===
  "07/03|14/03|21/03|28/03|04/04|11/04|18/04|25/04");
check("time years", timeLabels(946684800, 1577836800) === "01/01/00|01/01/02|01/01/04|" +
  "01/01/06|01/01/08|01/01/10|01/01/12|01/01/14|01/01/16|01/01/18|01/01/20");
check("time half seconds", timeLabels(1709287201.5, 1709287205) ===
  "00:01|00:02|00:02|00:03|00:03|00:04|00:04|00:05");
// strftime: gnuplot 6.0's own conversions (probed)
check("strftime", viewer.strftime(
  "%a|%A|%b|%B|%d|%D|%F|%T|%r|%j|%s|%y|%w|%U|%W|%.3S|%tH|%tM|%tS", 1709287265.4321) ===
  "Fri|Friday|Mar|March|01|03/01/24|2024-03-01|10:01:05|10:01:05 am|061|" +
  "1709287265|24|05|09|09|05.432|474802|01|05");
check("strftime before 1970",
  viewer.strftime("%F %T %p %k|%l|%tH|%tM|%tS", -86400 * 400 + 5025.5) ===
  "1968-11-27 01:23:45 am  1| 1|-9598|36|14");

// enhanced text: the same <tspan> elements as foresight_enhanced (foresight_enhanced_test, 12 px)
function spans(text) {
  var r = viewer.runsSpans(viewer.enhancedRuns(text), 12);
  if (r.length === 1 && Object.keys(r[0].attributes).length === 0) return r[0].text;
  return r.map(function (x) {
    return "<tspan" + Object.keys(x.attributes).map(function (k) {
      return " " + k + "=\"" + x.attributes[k] + "\"";
    }).join("") + ">" + x.text + "</tspan>";
  }).join("");
}
check("enhanced nested", spans("x^{a^b}") === "<tspan>x</tspan><tspan font-size=\"9.6\" dy=\"-6\">a</tspan>" +
  "<tspan font-size=\"7.68\" dy=\"-4.8\">b</tspan>" &&
  spans("x_{i_j}") === "<tspan>x</tspan><tspan font-size=\"9.6\" dy=\"3.6\">i</tspan>" +
  "<tspan font-size=\"7.68\" dy=\"2.88\">j</tspan>");
check("enhanced sub after sup", spans("x^2_3") === "<tspan>x</tspan><tspan font-size=\"9.6\" dy=\"-6\">2</tspan>" +
  "<tspan font-size=\"9.6\" dy=\"9.6\">3</tspan>");
check("enhanced & @ ~", spans("a&{bb}c") === "<tspan>a</tspan><tspan fill=\"none\">bb</tspan><tspan>c</tspan>" &&
  spans("a@_bc") === "<tspan>a</tspan><tspan font-size=\"9.6\" dy=\"3.6\">b</tspan>" +
  "<tspan dx=\"-5.28\" dy=\"-3.6\">c</tspan>" &&
  spans("~a{.8-}") === "<tspan>a</tspan><tspan dx=\"-6.6\" dy=\"-9.6\">-</tspan>");
check("enhanced fonts", spans("{/=8 s}{/*1.5 L}") ===
  "<tspan font-size=\"8\">s</tspan><tspan font-size=\"18\">L</tspan>" &&
  spans("{/:Italic i}{/:Bold=16 b}") === "<tspan font-style=\"italic\">i</tspan>" +
  "<tspan font-size=\"16\" font-weight=\"bold\">b</tspan>" &&
  spans("{/Helvetica:Italic h}") === "<tspan font-style=\"italic\" font-family=\"Helvetica\">h</tspan>" &&
  spans("{/Symbol abg}") === "\u03b1\u03b2\u03b3");
check("enhanced unicode and symbols", spans("a\\U+2192b") === "a\u{2192b}" &&
  spans("a\\U+2192 b") === "a\u2192 b" && spans("{/Symbol \u00f2\u00a5}") === "\u222b\u221e");
check("enhanced escapes", spans("x\\^2") === "x^2" && spans("a\\_1") === "a_1" &&
  !viewer.hasMarkup("x**2 + 1 (m/s)") && viewer.hasMarkup("t_1"));
check("tics noenhanced", viewer.readTics("noenhanced", "").plain === true &&
  viewer.readTics("noenhanced", "").mode === "auto" && !viewer.readTics("", "").plain &&
  viewer.readTics("noenhanced * 0.4 * out", "").step === "0.4" &&
  viewer.readTics("noenhanced labels 0:a_0", "").mode === "labels" &&
  !viewer.readTics("noenhanced labels 0:a_0", "").add);

// gnuplot 6.0 gprintf power conversions (expected: gnuplot 6.0 output, base 10 as tick labels)
check("format powers", [
  ["%t", 996, -2, "0.996000"],
  ["%T", 95, -1, "0"],
  ["%.1t*10^{%T}", 125, -1, "1.3*10^{1}"],
  ["%.1t*10^{%T}", 255, 0, "2.5*10^{2}"],
  ["%S", -345, -5, "-3"],
  ["%.1s%c", 12345, -1, "1.2k"],
  ["%.1s%c", 602, 21, "602.0Z"],
  ["%c", 3, -30, "e-30"],
  ["%3.0s %cm", 1, -3, "  1 mm"],
  ["%B", 1536, 0, "ki"],
  ["%.2b%B", 1048576, 0, "1.00Mi"],
  ["%.3P", 314159265358979, -14, "1.000"],
  ["%x", -1, 0, "ffffffffffffffff"],
  ["%X", 255, 0, "FF"],
  ["%o", 255, 0, "377"],
  ["%05.1t", -345, -5, "-03.4"]
].every(function (c) {
  var got = label(c[0], c[1], c[2]);
  if (got !== c[3]) console.log("    " + c[0] + " " + c[1] + "e" + c[2] + ": " + got + " (gnuplot " + c[3] + ")");
  return got === c[3];
}));

check("tics label style", (function () {
  var t = viewer.readTics("offset 0 -1 color #ff0000 * 0.5 *", "");
  return t.offset[0] === 0 && t.offset[1] === -1 && t.color === "#ff0000" && t.mode === "fixed" &&
    t.step === "0.5";
}()));

check("tics placement", (function () {
  var t = viewer.readTics("axis rangelimited -1e0 3e0 * 1 *", "");
  return t.axis === true && t.range[0] === -1 && t.range[1] === 3 && t.mode === "fixed" && t.step === "1";
}()));

var failed = checks.filter(function (c) { return !c.passed; });
checks.forEach(function (c) { console.log((c.passed ? "  PASS  " : "  FAIL  ") + c.name); });
console.log("Are all tests passed? " + (failed.length === 0 ? "T" : "F"));
process.exit(failed.length === 0 ? 0 : 1);
