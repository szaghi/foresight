// DOM tests of the viewer: key entries hiding series, linked x zoom of the panels, following the
// end of the data, and the state kept in the URL across a reload. They run src/js/viewer.js (not
// the copy embedded in the page) on the tutorial dashboard, docs/public/examples/ch7.html: two
// panels over the same iterations, with three and one series, markers and error bar caps. The page
// is parsed by linkedom; the SVG geometry the viewer asks for (bounding boxes, screen transforms)
// is stubbed, page pixels being client coordinates.
//
// Usage: npm ci --prefix src/js && node src/js/viewer_dom_test.js
//        (also `fobis rule --ex test-js-dom`, or `npm test --prefix src/js` for both viewer tests)
"use strict";

var fs = require("fs");
var path = require("path");
var parseHTML = require("linkedom").parseHTML;

var examples = path.join(__dirname, "..", "..", "docs", "public", "examples");
var page = fs.readFileSync(path.join(examples, "ch7.html"), "utf8")
  .replace(/<script>[\s\S]*<\/script>/, "");
var viewer = fs.readFileSync(path.join(__dirname, "viewer.js"), "utf8");
var checks = [];

function check(name, passed) {
  checks.push(passed);
  console.log((passed ? "  PASS  " : "  FAIL  ") + name);
}

// a fresh page with the URL fragment `hash`, the viewer started on it
function load(hash) {
  var dom = parseHTML(page), proto = Object.getPrototypeOf(dom.document.querySelector("svg"));
  var location = {hash: hash, replace: function (u) { this.hash = u; }, reload: function () {}};
  var history = {replaceState: function (s, t, u) { location.hash = u; }};
  proto.getBBox = function () { return {x: 0, y: 0, width: 10, height: 10}; };
  proto.createSVGPoint = function () {
    return {x: 0, y: 0, matrixTransform: function () { return {x: this.x, y: this.y}; }};
  };
  proto.getScreenCTM = function () { return {inverse: function () { return null; }}; };
  new Function("document", "window", "location", "history", "setTimeout", viewer)(
    dom.document, dom.window, location, history, function () {});
  return {window: dom.window, document: dom.document, location: location};
}

var p = load("");

function fire(target, type, props) {
  var evt = new p.window.Event(type, {bubbles: true, cancelable: true});
  Object.assign(evt, {button: 0, clientX: 0, clientY: 0, deltaY: 0, ctrlKey: false,
    shiftKey: false, metaKey: false, altKey: false}, props);
  target.dispatchEvent(evt);
}
function key(name) { fire(p.document, "keydown", {key: name}); }
function panel(k) { return p.document.querySelectorAll(".fs-axes")[k]; }
// plot area viewBox of panel k: u0, 1 - v1, width, height (unit square)
function box(k) {
  return panel(k).querySelector(".fs-plot").getAttribute("viewBox").split(" ").map(Number);
}
// the page point at fractions (fx, fy) of the plot area of panel k, from its top left
function at(k, fx, fy, extra) {
  var a = panel(k).getAttribute("data-area").split(" ").map(Number);
  return Object.assign({clientX: a[0] + fx * (a[1] - a[0]), clientY: a[2] + fy * (a[3] - a[2])},
    extra);
}
function wheel(k, extra) {
  fire(p.document.querySelector("svg"), "wheel",
    at(k, 0.5, 0.5, Object.assign({deltaY: -1}, extra)));
}
function series(k, n) { return panel(k).querySelector('.fs-series[data-series="' + n + '"]'); }
function entry(k, n) { return panel(k).querySelectorAll(".fs-key-entry")[n - 1]; }
function inHash(item) { return new RegExp("(^|[#&])" + item + "(&|$)").test(p.location.hash); }
function close(a, b) { return Math.abs(a - b) < 1e-12; }

check("two panels, three key entries in the first",
  p.document.querySelectorAll(".fs-axes").length === 2 &&
  panel(0).querySelectorAll(".fs-key-entry").length === 3);
check("key entries get a click box", entry(0, 1).querySelector("rect") !== null);

// a key entry hides its series, and shows it again
fire(entry(0, 2).querySelector("text"), "mousedown", {});
check("click hides series 2", series(0, 2).getAttribute("display") === "none" &&
  series(0, 1).getAttribute("display") === "inline");
check("its entry dimmed", entry(0, 2).getAttribute("opacity") === "0.3");
check("hidden series in the URL", inHash("s=2"));
fire(entry(0, 2).querySelector("text"), "mousedown", {});
check("second click shows it", series(0, 2).getAttribute("display") === "inline" &&
  !/s=/.test(p.location.hash));

// linked x zoom: the wheel on panel 1 zooms the x of panel 2, not its y
var before = box(1), b0, b1;
wheel(0);
b0 = box(0);
b1 = box(1);
check("wheel zooms panel 1", b0[2] < 1 && b0[3] < 1);
check("panel 2 takes its x window", close(b1[0], b0[0]) && close(b1[2], b0[2]));
check("panel 2 keeps its y", b1[1] === before[1] && b1[3] === before[3]);
check("both views in the URL", inHash("x=[^&]*") && inHash("x1=[^&]*"));
check("markers regenerated, numbered",
  panel(1).querySelectorAll(".fs-marks path[data-series]").length > 0);
key("a");
check("a resets both", box(0)[2] === 1 && box(1)[2] === 1);

// a box zoom is recorded on both, u undoes it on both
fire(p.document.querySelector("svg"), "mousedown", at(0, 0.6, 0.2, {button: 2}));
fire(p.window, "mousemove", at(0, 0.9, 0.8, {button: 2}));
fire(p.window, "mouseup", at(0, 0.9, 0.8, {button: 2}));
check("box zoom on panel 1, x on panel 2",
  close(box(0)[2], 0.3) && close(box(1)[0], box(0)[0]) && close(box(1)[2], 0.3));
key("u");
check("u undoes both", box(0)[2] === 1 && box(1)[2] === 1);

// unlinked, panel 2 stays
key("l");
wheel(0);
check("l unlinks: panel 2 unchanged", box(1)[2] === 1 && box(0)[2] < 1);
check("unlinked in the URL", inHash("l=0"));
key("l");

// follow: a narrow x window slides to the end of the axis, y fits the points shown
key("a");
for (var k = 0; k < 8; k++) wheel(0, {shiftKey: true});
key("f");
b0 = box(0);
check("f: the x window ends at the axis end", close(b0[0] + b0[2], 1) && b0[2] < 1);
check("f: y fits the window", b0[3] < 1);
check("following in the URL", inHash("f=1"));

// a reload restores hidden series (markers and caps too) and keeps following
fire(entry(1, 1).querySelector("text"), "mousedown", {});
p = load(p.location.hash);
check("reload keeps the series hidden", series(1, 1).getAttribute("display") === "none");
check("and its markers and caps", Array.prototype.every.call(
  panel(1).querySelectorAll('.fs-marks [data-series="1"], .fs-caps [data-series="1"]'),
  function (n) { return n.getAttribute("display") === "none"; }));
b0 = box(0);
check("reload keeps following", close(b0[0] + b0[2], 1) && b0[2] < 1);

console.log("Are all tests passed? " + (checks.every(Boolean) ? "T" : "F"));
process.exit(checks.every(Boolean) ? 0 : 1);
