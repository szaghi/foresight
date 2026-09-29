// foresight interactive viewer: gnuplot-like zoom, pan and hotkeys on a foresight SVG plot.
//
// The page is fully drawn by foresight; this script only changes the plot area viewBox and
// regenerates ticks and grid. The tick rules mirror src/lib/foresight_ticks.F90 and the tick
// formats src/lib/foresight_format.F90 line by line: keep them in sync.
// Embedded into src/lib/foresight_viewer_js.F90 by scripts/embed_js.sh (lines <= 100 characters).
(function () {
  "use strict";

  var TOL = 1e-9, TICK_SPACING = 50, SCI_HIGH = 1e5, SCI_LOW = 1e-3, MAX_TICKS = 1000;
  var MAX_POWER = 10000;
  var TICK_MAJOR = 6, TICK_MINOR = 3, GAP = 6;
  var FRAME_COLOR = "black", GRID_COLOR = "#a0a0a0", GRID_DASHES = "2,3";
  var ZOOM_FACTOR = 1.25, MIN_BOX = 4;
  var NS = "http://www.w3.org/2000/svg";
  var POW10 = [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14,
    1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22];

  // ---- tick rules (mirror of foresight_ticks.F90) ----

  // x * 10**e with a single rounding for |e| <= 22 (exact powers of ten), beyond in steps of
  // 1e22 (mirror of grid_value)
  function scale10(x, e) {
    var y = x, k = e;
    while (k > 22) { y *= 1e22; k -= 22; }
    while (k < -22) { y /= 1e22; k += 22; }
    return k >= 0 ? y * POW10[k] : y / POW10[-k];
  }

  function modulo(a, b) { return ((a % b) + b) % b; }

  function niceStep(raw) {
    var e = Math.floor(Math.log10(raw)), f = scale10(raw, -e), m;
    if (f < 1.5) m = 1;
    else if (f < 3) m = 2;
    else if (f < 7) m = 5;
    else { m = 1; e += 1; }
    return {m: m, e: e};
  }

  function decimalStr(n, ndec) {
    if (n === 0) return "0";
    var digits = String(Math.abs(n)), str, fraction;
    if (ndec <= 0) {
      str = digits + "0".repeat(-ndec);
    } else {
      if (digits.length <= ndec) digits = "0".repeat(ndec - digits.length + 1) + digits;
      fraction = digits.slice(digits.length - ndec).replace(/0+$/, "");
      str = digits.slice(0, digits.length - ndec) + (fraction ? "." + fraction : "");
    }
    return n < 0 ? "-" + str : str;
  }

  function isScientific(magnitude) {
    return magnitude >= SCI_HIGH || (magnitude > 0 && magnitude < SCI_LOW);
  }

  // ---- user tick formats (mirror of foresight_format.F90) ----

  // exact value of a decimal text as n * 10**e, no trailing zeros in n; null if malformed
  function parseDecimal(text) {
    var m = /^([+-]?)(\d*)(?:\.(\d*))?(?:[eEdD]([+-]?\d{1,4}))?$/.exec(text), digits, n, e;
    if (!m || (m[2] + (m[3] || "")).length === 0) return null;
    digits = (m[2] + (m[3] || "")).replace(/^0+(?=\d)/, "");
    if (digits.length > 18) return null;
    n = Number(digits);
    e = Number(m[4] || 0) - (m[3] || "").length;
    if (n === 0) e = 0;
    while (n !== 0 && n % 10 === 0) { n /= 10; e += 1; }
    return {n: m[1] === "-" ? -n : n, e: e};
  }

  // v rounded to 15 significant digits, as n * 10**e (mirror of decimal_of)
  function decimalOf(v) {
    var a = Math.abs(v), e, n;
    if (v === 0) return {n: 0, e: 0};
    e = Math.floor(Math.log10(a));
    n = Math.round(scale10(a, 14 - e));
    if (n < 1e14) { e -= 1; n = Math.round(scale10(a, 14 - e)); }
    if (n >= 1e15) { n = Math.trunc(n / 10); e += 1; }
    e -= 14;
    while (n % 10 === 0) { n /= 10; e += 1; }
    return {n: v < 0 ? -n : n, e: e};
  }

  // split a format around its one conversion; null if unsupported
  function splitFormat(format) {
    var f = {prefix: "", suffix: "", flags: "", width: 0, prec: -1, type: ""}, found = false;
    var i = 0, m, re = /^%([-+ 0]*)(\d{0,3})(?:\.(\d{0,2}))?([feEgGh])/;
    while (i < format.length) {
      if (format[i] !== "%") {
        if (found) f.suffix += format[i]; else f.prefix += format[i];
        i += 1;
      } else if (format[i + 1] === "%") {
        if (found) f.suffix += "%"; else f.prefix += "%";
        i += 2;
      } else {
        m = re.exec(format.slice(i));
        if (found || !m) return null;
        found = true;
        f.flags = m[1];
        f.width = Number(m[2] || 0);
        f.prec = m[3] === undefined ? -1 : Number(m[3] || 0);
        f.type = m[4];
        i += m[0].length;
      }
    }
    return found ? f : null;
  }

  // integer digits with the last drop ones removed, rounded half to even (mirror of round_digits)
  function roundDigits(digits, drop) {
    var work, tail, kept, up, k, a;
    if (drop <= 0) return (digits + "0".repeat(-drop)).replace(/^0+(?=\d)/, "");
    work = "0".repeat(Math.max(0, drop + 1 - digits.length)) + digits;
    tail = work.slice(work.length - drop);
    kept = work.slice(0, work.length - drop);
    if (tail[0] !== "5") up = tail[0] > "5";
    else if (/[1-9]/.test(tail.slice(1))) up = true;
    else up = "13579".indexOf(kept[kept.length - 1]) >= 0;
    if (up) {
      a = kept.split("");
      for (k = a.length - 1; k >= 0 && a[k] === "9"; k--) a[k] = "0";
      if (k < 0) a.unshift("1"); else a[k] = String(Number(a[k]) + 1);
      kept = a.join("");
    }
    return kept.replace(/^0+(?=\d)/, "");
  }

  function fixedDigits(digits, e, prec) {
    var units = roundDigits(digits, -prec - e), text;
    if (units.length <= prec) units = "0".repeat(prec - units.length + 1) + units;
    text = units.slice(0, units.length - prec);
    return prec > 0 ? text + "." + units.slice(units.length - prec) : text;
  }

  function expDigits(digits, e, prec) {
    var kept, x;
    if (/^0+$/.test(digits)) {
      kept = "0".repeat(prec + 1);
      x = 0;
    } else {
      x = digits.length - 1 + e;
      kept = roundDigits(digits, digits.length - prec - 1);
      if (kept.length > prec + 1) { kept = kept.slice(0, prec + 1); x += 1; }
    }
    return {mantissa: kept[0] + (prec > 0 ? "." + kept.slice(1) : ""), x: x};
  }

  function expText(letter, x) {
    var d = String(Math.abs(x));
    return letter + (x < 0 ? "-" : "+") + (d.length < 2 ? "0" + d : d);
  }

  function stripZeros(text) {
    return text.indexOf(".") < 0 ? text : text.replace(/0+$/, "").replace(/\.$/, "");
  }

  // printf-like format applied to the exact value n * 10**e (mirror of format_decimal)
  function formatDecimal(format, n, e) {
    var f = splitFormat(format), digits, body, sup = "", sign = "", r, p, pad;
    if (!f) return {label: format, sup: ""};
    digits = String(Math.abs(n));
    if (f.type === "f") {
      body = fixedDigits(digits, e, f.prec < 0 ? 6 : f.prec);
    } else if (f.type === "e" || f.type === "E") {
      r = expDigits(digits, e, f.prec < 0 ? 6 : f.prec);
      body = r.mantissa + expText(f.type, r.x);
    } else {
      p = f.prec < 0 ? 6 : Math.max(1, f.prec);
      r = expDigits(digits, e, p - 1);
      if (r.x < p && r.x >= -4) {
        body = stripZeros(fixedDigits(digits, e, p - 1 - r.x));
      } else {
        body = stripZeros(r.mantissa);
        if (f.type === "h") { body += "x10"; sup = String(r.x); }
        else body += expText(f.type === "G" ? "E" : "e", r.x);
      }
    }
    if (n < 0) sign = "-";
    else if (f.flags.indexOf("+") >= 0) sign = "+";
    else if (f.flags.indexOf(" ") >= 0) sign = " ";
    pad = f.width - sign.length - body.length;
    if (pad > 0) {
      if (f.flags.indexOf("-") >= 0) body += " ".repeat(pad);
      else if (f.flags.indexOf("0") >= 0 && !sup) body = "0".repeat(pad) + body;
      else sign = " ".repeat(pad) + sign;
    }
    return {label: f.prefix + sign + body + f.suffix, sup: sup};
  }

  function formatLabel(n, e, sci) {
    if (!sci || n === 0) return {label: decimalStr(n, -e), sup: ""};
    var nn = Math.abs(n), ee = e, digits, label;
    while (nn % 10 === 0) { nn /= 10; ee += 1; }
    digits = String(nn);
    label = digits[0] + (digits.length > 1 ? "." + digits.slice(1) : "");
    return {label: (n < 0 ? "-" : "") + label + "x10", sup: String(ee + digits.length - 1)};
  }

  // user tick settings from the panel attributes: {mode, start, step, end, format}
  function readTics(positions, format) {
    var tics = {mode: "auto", start: "", step: "", end: "", format: format || ""}, p;
    if (positions === "none") tics.mode = "none";
    else if (positions) {
      p = positions.split(" ");
      tics.mode = "fixed";
      tics.start = p[0] === "*" ? "" : p[0];
      tics.step = p[1];
      tics.end = p[2] === "*" ? "" : p[2];
    }
    return tics;
  }

  function tickLabel(n, e, sci, tics) {
    return tics && tics.format ? formatDecimal(tics.format, n, e) : formatLabel(n, e, sci);
  }

  // mantissas of step, start, end at their smallest common exponent, each below 1e15; or null
  function fixedValues(tics) {
    var d = [parseDecimal(tics.step), tics.start ? parseDecimal(tics.start) : null,
      tics.end ? parseDecimal(tics.end) : null], n = [], e, k, shift;
    if (!d[1]) d[1] = {n: 0, e: d[0].e};
    if (!d[2]) d[2] = {n: 0, e: d[0].e};
    e = Math.min(d[0].e, d[1].e, d[2].e);
    for (k = 0; k < 3; k++) {
      shift = d[k].e - e;
      if (shift > 15 || Math.abs(d[k].n) >= Math.pow(10, 15 - shift)) return null;
      n.push(d[k].n * POW10[shift]);
    }
    return {n: n, e: e, hasStart: tics.start !== "", hasEnd: tics.end !== ""};
  }

  // ticks at start + k * step within [start, end] (mirror of fixed_linear_ticks, no extension)
  function fixedLinearTicks(lo, hi, tics) {
    var f = fixedValues(tics), ticks = [], step, offset, kmin, kmax, sci, k, t, v;
    if (!f) return ticks;
    step = scale10(f.n[0], f.e);
    offset = f.n[1] / f.n[0];
    if (Math.max(Math.abs(lo), Math.abs(hi)) / step + Math.abs(offset) > 1e15) return ticks;
    kmin = Math.ceil(Math.min(lo, hi) / step - offset - TOL);
    kmax = Math.floor(Math.max(lo, hi) / step - offset + TOL);
    if (f.hasStart) kmin = Math.max(kmin, 0);
    if (f.hasEnd) {
      if (f.n[2] < f.n[1]) return ticks;
      kmax = Math.min(kmax, Math.trunc((f.n[2] - f.n[1]) / f.n[0]));
    }
    if (kmax < kmin || kmax - kmin >= MAX_TICKS) return ticks;
    sci = isScientific(Math.max(Math.abs(lo), Math.abs(hi)));
    for (k = kmin; k <= kmax; k++) {
      t = tickLabel(f.n[1] + k * f.n[0], f.e, sci, tics);
      v = scale10(f.n[1] + k * f.n[0], f.e);
      ticks.push({value: v, major: true, label: t.label, sup: t.sup});
    }
    return ticks;
  }

  // first * factor**k by |k| multiplications or divisions (mirror of power)
  function power(first, factor, k) {
    var v = first, j;
    for (j = 0; j < Math.abs(k); j++) v = k > 0 ? v * factor : v / factor;
    return v;
  }

  // ticks at start * step**k on a log axis (mirror of fixed_log_ticks)
  function fixedLogTicks(lo, hi, tics) {
    var f = fixedValues(tics), ticks = [], factor, first, last, lf, kmin, kmax, sci, k, v, d, t;
    if (!f) return ticks;
    factor = scale10(f.n[0], f.e);
    first = f.hasStart ? scale10(f.n[1], f.e) : 1;
    last = scale10(f.n[2], f.e);
    if (factor <= 1 || first <= 0) return ticks;
    lf = Math.log10(factor);
    if (Math.max(Math.abs(Math.log10(lo)), Math.abs(Math.log10(hi)),
      Math.abs(Math.log10(first))) / lf > MAX_POWER) return ticks;
    kmin = Math.ceil((Math.log10(Math.min(lo, hi)) - Math.log10(first)) / lf - TOL);
    kmax = Math.floor((Math.log10(Math.max(lo, hi)) - Math.log10(first)) / lf + TOL);
    if (f.hasStart) kmin = Math.max(kmin, 0);
    if (f.hasEnd) {
      if (last <= 0) return ticks;
      kmax = Math.min(kmax, Math.floor((Math.log10(last) - Math.log10(first)) / lf + TOL));
    }
    if (kmax < kmin || kmax - kmin >= MAX_TICKS) return ticks;
    sci = isScientific(Math.max(lo, hi));
    v = power(first, factor, kmin);
    for (k = kmin; k <= kmax; k++) {
      d = decimalOf(v);
      t = tickLabel(d.n, d.e, sci, tics);
      ticks.push({value: v, major: true, label: t.label, sup: t.sup});
      v *= factor;
    }
    return ticks;
  }

  // major ticks of a linear axis spanning [lo, hi] (either order) over npx pixels, no extension
  function linearTicks(lo, hi, npx, tics) {
    if (tics && tics.mode === "none") return [];
    if (tics && tics.mode === "fixed") return fixedLinearTicks(lo, hi, tics);
    var ns = niceStep(Math.abs(hi - lo) / Math.max(2, npx / TICK_SPACING));
    var step = scale10(ns.m, ns.e), ticks = [], k, t;
    var kmin = Math.ceil(Math.min(lo, hi) / step - TOL);
    var kmax = Math.floor(Math.max(lo, hi) / step + TOL);
    if (kmax - kmin >= MAX_TICKS) return ticks;
    var sci = isScientific(Math.max(Math.abs(lo), Math.abs(hi)));
    for (k = kmin; k <= kmax; k++) {
      t = tickLabel(k * ns.m, ns.e, sci, tics);
      ticks.push({value: scale10(k * ns.m, ns.e), major: true, label: t.label, sup: t.sup});
    }
    return ticks;
  }

  // ticks of a base-10 log axis spanning [lo, hi] (either order, > 0) over npx pixels
  function logTicks(lo, hi, npx, tics) {
    if (tics && tics.mode === "none") return [];
    if (tics && tics.mode === "fixed") return fixedLogTicks(lo, hi, tics);
    var ta = Math.log10(Math.min(lo, hi)), tb = Math.log10(Math.max(lo, hi));
    var ns = niceStep((tb - ta) / Math.max(2, npx / TICK_SPACING));
    var s = ns.e >= 0 ? ns.m * scale10(1, ns.e) : 1, custom = !!(tics && tics.format);
    var kmin = Math.ceil(ta - TOL), kmax = Math.floor(tb + TOL), ticks = [], k, d, v, t;
    var nmajor = 0, plain;
    if (kmax - kmin >= MAX_TICKS) return ticks;
    for (k = kmin; k <= kmax; k++) if (modulo(k, s) === 0) nmajor++;
    plain = nmajor < 2;
    for (k = kmin; k <= kmax; k++) {
      if (modulo(k, s) !== 0) continue;
      if (custom) t = formatDecimal(tics.format, 1, k);
      else t = {label: plain ? decimalStr(1, -k) : "10", sup: plain ? "" : String(k)};
      ticks.push({value: scale10(1, k), major: true, label: t.label, sup: t.sup});
    }
    if (s === 1 && tb - ta <= 10) {
      for (k = Math.floor(ta - TOL); k <= Math.floor(tb + TOL); k++) {
        for (d = 2; d <= 9; d++) {
          v = scale10(d, k);
          t = Math.log10(v);
          if (t < ta - TOL || t > tb + TOL) continue;
          t = plain && custom ? formatDecimal(tics.format, d, k)
            : {label: plain ? decimalStr(d, -k) : "", sup: ""};
          ticks.push({value: v, major: plain, label: t.label, sup: t.sup});
        }
      }
    }
    if (ticks.filter(function (x) { return x.major; }).length < 2) {
      ticks = linearTicks(lo, hi, npx, tics).filter(function (x) { return x.value > 0; });
    }
    return ticks;
  }

  var core = {niceStep: niceStep, decimalStr: decimalStr, linearTicks: linearTicks,
    logTicks: logTicks, formatDecimal: formatDecimal, parseDecimal: parseDecimal,
    decimalOf: decimalOf, readTics: readTics};
  if (typeof module === "object" && module.exports) {
    module.exports = core;
    return;
  }

  // ---- axis mapping: unit coordinate [0, 1] <-> data value ----

  function Axis(range, log, tics) {
    this.log = log;
    this.tics = tics;
    this.a = log ? Math.log10(range[0]) : range[0];
    this.b = log ? Math.log10(range[1]) : range[1];
  }
  Axis.prototype.toUnit = function (v) {
    return ((this.log ? Math.log10(v) : v) - this.a) / (this.b - this.a);
  };
  Axis.prototype.toData = function (u) {
    var t = this.a + u * (this.b - this.a);
    return this.log ? Math.pow(10, t) : t;
  };
  Axis.prototype.ticks = function (u0, u1, npx) {
    var lo = this.toData(u0), hi = this.toData(u1);
    return this.log ? logTicks(lo, hi, npx, this.tics) : linearTicks(lo, hi, npx, this.tics);
  };

  // ---- SVG helpers ----

  function numbers(text) { return text.split(" ").map(Number); }

  function element(parent, name, attributes) {
    var node = document.createElementNS(NS, name);
    Object.keys(attributes).forEach(function (k) { node.setAttribute(k, attributes[k]); });
    if (parent) parent.appendChild(node);
    return node;
  }

  function line(parent, x1, y1, x2, y2, color, width, dashes) {
    var attributes = {x1: x1, y1: y1, x2: x2, y2: y2, stroke: color, "stroke-width": width};
    if (dashes) attributes["stroke-dasharray"] = dashes;
    return element(parent, "line", attributes);
  }

  function label(parent, x, y, tick, anchor) {
    var node = element(parent, "text", {x: x, y: y, "text-anchor": anchor});
    node.appendChild(document.createTextNode(tick.label));
    if (tick.sup) {
      element(node, "tspan", {dy: "-0.45em", "font-size": "0.75em"}).textContent = tick.sup;
    }
  }

  function clear(node) { while (node.firstChild) node.removeChild(node.firstChild); }

  function shortNumber(v) { return String(Number(v.toPrecision(6))); }

  // ---- plot panel ----

  function Panel(svg, group, index) {
    var area = numbers(group.getAttribute("data-area"));
    var logs = numbers(group.getAttribute("data-log"));
    this.svg = svg;
    this.suffix = index > 0 ? String(index) : "";
    this.left = area[0];
    this.right = area[1];
    this.top = area[2];
    this.bottom = area[3];
    this.x = new Axis(numbers(group.getAttribute("data-x")), logs[0] === 1,
      readTics(group.getAttribute("data-xtics"), group.getAttribute("data-xformat")));
    this.y = new Axis(numbers(group.getAttribute("data-y")), logs[1] === 1,
      readTics(group.getAttribute("data-ytics"), group.getAttribute("data-yformat")));
    this.fontSize = Number(group.getAttribute("data-font-size"));
    this.grid = group.getAttribute("data-grid") === "1";
    this.plot = group.querySelector(".fs-plot");
    this.gridGroup = group.querySelector(".fs-grid");
    this.xticks = group.querySelector(".fs-xticks");
    this.yticks = group.querySelector(".fs-yticks");
    this.caps = group.querySelector(".fs-caps");
    this.bars = readBars(group);
    this.original = [this.gridGroup.innerHTML, this.xticks.innerHTML, this.yticks.innerHTML,
      this.caps ? this.caps.innerHTML : ""];
    this.view = {u0: 0, u1: 1, v0: 0, v1: 1};
    this.history = [];
  }

  // error bars of the plot area: segments in viewBox coordinates (unit square, y downward)
  function readBars(group) {
    var bars = [], pattern = /M([^,]+),([^L]+)L([^,]+),([^M]+)/g;
    group.querySelectorAll(".fs-ybars, .fs-xbars").forEach(function (path) {
      var d = path.getAttribute("d").replace(/\s+/g, ""), m;
      var style = {vertical: path.getAttribute("class") === "fs-ybars",
        cap: Number(path.getAttribute("data-cap")), color: path.getAttribute("stroke"),
        width: path.getAttribute("stroke-width")};
      while ((m = pattern.exec(d)) !== null) {
        bars.push({style: style, ends: [[+m[1], +m[2]], [+m[3], +m[4]]]});
      }
    });
    return bars;
  }

  Panel.prototype.isHome = function () {
    var v = this.view;
    return v.u0 === 0 && v.u1 === 1 && v.v0 === 0 && v.v1 === 1;
  };

  Panel.prototype.contains = function (p) {
    return p.x >= this.left && p.x <= this.right && p.y >= this.top && p.y <= this.bottom;
  };

  // page pixel -> current view unit coordinates
  Panel.prototype.unitAt = function (p) {
    var v = this.view;
    return {u: v.u0 + (p.x - this.left) / (this.right - this.left) * (v.u1 - v.u0),
      v: v.v0 + (this.bottom - p.y) / (this.bottom - this.top) * (v.v1 - v.v0)};
  };

  Panel.prototype.setView = function (view, record) {
    if (!(view.u1 - view.u0 > 1e-12 && view.v1 - view.v0 > 1e-12)) return;
    if (record) this.history.push(this.view);
    this.view = view;
    this.redraw();
    this.saveState();
  };

  Panel.prototype.redraw = function () {
    var v = this.view;
    this.plot.setAttribute("viewBox", [v.u0, 1 - v.v1, v.u1 - v.u0, v.v1 - v.v0].join(" "));
    this.gridGroup.setAttribute("display", this.grid ? "inline" : "none");
    if (this.isHome()) {
      this.gridGroup.innerHTML = this.original[0];
      this.xticks.innerHTML = this.original[1];
      this.yticks.innerHTML = this.original[2];
      if (this.caps) this.caps.innerHTML = this.original[3];
    } else {
      this.drawTicks();
      this.drawCaps();
    }
  };

  // error bar caps keep their pixel length: recomputed in the pixel overlay for the current view
  Panel.prototype.drawCaps = function () {
    var self = this, v = this.view;
    var w = this.right - this.left, h = this.bottom - this.top;
    if (!this.caps) return;
    clear(this.caps);
    this.bars.forEach(function (bar) {
      var half = bar.style.cap / 2;
      bar.ends.forEach(function (end) {
        var x = (end[0] - v.u0) / (v.u1 - v.u0) * w;
        var y = (end[1] - (1 - v.v1)) / (v.v1 - v.v0) * h;
        if (bar.style.vertical) {
          line(self.caps, x - half, y, x + half, y, bar.style.color, bar.style.width);
        } else {
          line(self.caps, x, y - half, x, y + half, bar.style.color, bar.style.width);
        }
      });
    });
  };

  // regenerate ticks, tick labels and grid for the current view (mirror of draw_frame/draw_grid)
  Panel.prototype.drawTicks = function () {
    var self = this, v = this.view, fs = this.fontSize;
    var w = this.right - this.left, h = this.bottom - this.top;
    clear(this.gridGroup);
    clear(this.xticks);
    clear(this.yticks);
    this.x.ticks(v.u0, v.u1, w).forEach(function (t) {
      var p = self.left + (self.x.toUnit(t.value) - v.u0) / (v.u1 - v.u0) * w;
      var length = t.major ? TICK_MAJOR : TICK_MINOR;
      if (p < self.left - 0.5 || p > self.right + 0.5) return;
      line(self.xticks, p, self.bottom, p, self.bottom - length, FRAME_COLOR, 1);
      line(self.xticks, p, self.top, p, self.top + length, FRAME_COLOR, 1);
      if (!t.major) return;
      label(self.xticks, p, self.bottom + GAP + fs, t, "middle");
      line(self.gridGroup, p, self.bottom, p, self.top, GRID_COLOR, 0.5, GRID_DASHES);
    });
    this.y.ticks(v.v0, v.v1, h).forEach(function (t) {
      var p = self.bottom - (self.y.toUnit(t.value) - v.v0) / (v.v1 - v.v0) * h;
      var length = t.major ? TICK_MAJOR : TICK_MINOR;
      if (p < self.top - 0.5 || p > self.bottom + 0.5) return;
      line(self.yticks, self.left, p, self.left + length, p, FRAME_COLOR, 1);
      line(self.yticks, self.right, p, self.right - length, p, FRAME_COLOR, 1);
      if (!t.major) return;
      label(self.yticks, self.left - GAP, p + 0.35 * fs, t, "end");
      line(self.gridGroup, self.left, p, self.right, p, GRID_COLOR, 0.5, GRID_DASHES);
    });
  };

  // zoom by factors (fx, fy) about the page point p
  Panel.prototype.zoomAt = function (p, fx, fy) {
    var c = this.unitAt(p), v = this.view;
    this.setView({u0: c.u + (v.u0 - c.u) * fx, u1: c.u + (v.u1 - c.u) * fx,
      v0: c.v + (v.v0 - c.v) * fy, v1: c.v + (v.v1 - c.v) * fy}, false);
  };

  // zoom to the page-pixel box between points p and q
  Panel.prototype.zoomBox = function (p, q) {
    var a = this.unitAt(p), b = this.unitAt(q);
    this.setView({u0: Math.min(a.u, b.u), u1: Math.max(a.u, b.u),
      v0: Math.min(a.v, b.v), v1: Math.max(a.v, b.v)}, true);
  };

  Panel.prototype.unzoom = function () {
    if (this.history.length) this.setView(this.history.pop(), false);
  };

  Panel.prototype.autoscale = function () {
    if (!this.isHome()) this.setView({u0: 0, u1: 1, v0: 0, v1: 1}, true);
  };

  Panel.prototype.toggleGrid = function () {
    this.grid = !this.grid;
    this.redraw();
    this.saveState();
  };

  // zoom and grid persist in the URL hash as data values, so a reload with new data keeps the view;
  // keys are g, x, y for the first panel, g1, x1, y1 for the second, and so on
  Panel.prototype.state = function () {
    var v = this.view, n = this.suffix, items = ["g" + n + "=" + (this.grid ? 1 : 0)];
    if (!this.isHome()) {
      items.push("x" + n + "=" + [this.x.toData(v.u0), this.x.toData(v.u1)].join(","));
      items.push("y" + n + "=" + [this.y.toData(v.v0), this.y.toData(v.v1)].join(","));
    }
    return items;
  };

  Panel.prototype.saveState = function () {
    var state = [].concat.apply([], panels.map(function (p) { return p.state(); })).join("&");
    try {
      history.replaceState(null, "", "#" + state);
    } catch (e) {
      // file:// pages may refuse history updates: a fragment-only replace is always allowed
      location.replace("#" + state);
    }
  };

  Panel.prototype.loadState = function () {
    var state = {}, x, y, view, n = this.suffix;
    location.hash.slice(1).split("&").forEach(function (item) {
      var pair = item.split("=");
      if (pair.length === 2) state[pair[0]] = pair[1];
    });
    if (state["g" + n] === "0" || state["g" + n] === "1") this.grid = state["g" + n] === "1";
    if (state["x" + n] && state["y" + n]) {
      x = state["x" + n].split(",").map(Number);
      y = state["y" + n].split(",").map(Number);
      view = {u0: this.x.toUnit(x[0]), u1: this.x.toUnit(x[1]),
        v0: this.y.toUnit(y[0]), v1: this.y.toUnit(y[1])};
      if ([view.u0, view.u1, view.v0, view.v1].every(isFinite)) this.view = view;
    }
    this.redraw();
  };

  // ---- page: overlays and input handling ----

  var panels = [];

  function start() {
    var svg = document.querySelector("svg");
    if (!svg || !svg.querySelector(".fs-axes")) return;
    svg.querySelectorAll(".fs-axes").forEach(function (group, k) {
      panels.push(new Panel(svg, group, k));
    });
    var panel = panels[0];
    var height = Number(svg.getAttribute("height"));
    var refresh = Number(svg.getAttribute("data-refresh") || 0);
    var readout = element(svg, "text", {x: 4, y: height - 4, "font-size": 10, fill: "#555"});
    var box = element(svg, "rect", {fill: "none", stroke: "#555", "stroke-dasharray": "3,3",
      display: "none"});
    var help = helpOverlay(svg);
    var drag = null;

    function point(evt) {
      var p = svg.createSVGPoint();
      p.x = evt.clientX;
      p.y = evt.clientY;
      return p.matrixTransform(svg.getScreenCTM().inverse());
    }

    // panel under the page point p, or null
    function panelAt(p) {
      // topmost first: a panel drawn later (an inset) lies over the earlier ones
      for (var k = panels.length - 1; k >= 0; k--) if (panels[k].contains(p)) return panels[k];
      return null;
    }

    function showReadout(p) {
      var c, hit = panelAt(p);
      if (!hit) { readout.textContent = ""; return; }
      panel = hit;
      c = panel.unitAt(p);
      readout.textContent = "x = " + shortNumber(panel.x.toData(c.u)) +
        "   y = " + shortNumber(panel.y.toData(c.v));
    }

    svg.addEventListener("contextmenu", function (evt) { evt.preventDefault(); });
    svg.addEventListener("wheel", function (evt) {
      var p = point(evt), f;
      if (!panelAt(p)) return;
      panel = panelAt(p);
      evt.preventDefault();
      f = evt.deltaY < 0 ? 1 / ZOOM_FACTOR : ZOOM_FACTOR;
      panel.zoomAt(p, evt.ctrlKey ? 1 : f, evt.shiftKey ? 1 : f);
    }, {passive: false});
    svg.addEventListener("mousedown", function (evt) {
      var p = point(evt);
      if (!panelAt(p)) return;
      panel = panelAt(p);
      evt.preventDefault();
      drag = {button: evt.button, start: p, view: panel.view};
    });
    window.addEventListener("mousemove", function (evt) {
      var p = point(evt), v, du, dv;
      showReadout(p);
      if (!drag) return;
      if (drag.button === 0) {
        v = drag.view;
        du = (p.x - drag.start.x) / (panel.right - panel.left) * (v.u1 - v.u0);
        dv = (p.y - drag.start.y) / (panel.bottom - panel.top) * (v.v1 - v.v0);
        panel.setView({u0: v.u0 - du, u1: v.u1 - du, v0: v.v0 + dv, v1: v.v1 + dv}, false);
      } else if (drag.button === 2) {
        box.setAttribute("x", Math.min(p.x, drag.start.x));
        box.setAttribute("y", Math.min(p.y, drag.start.y));
        box.setAttribute("width", Math.abs(p.x - drag.start.x));
        box.setAttribute("height", Math.abs(p.y - drag.start.y));
        box.setAttribute("display", "inline");
      }
    });
    window.addEventListener("mouseup", function (evt) {
      var p = point(evt);
      if (drag && drag.button === 2) {
        box.setAttribute("display", "none");
        if (Math.abs(p.x - drag.start.x) >= MIN_BOX && Math.abs(p.y - drag.start.y) >= MIN_BOX) {
          panel.zoomBox(drag.start, p);
        }
      }
      drag = null;
    });
    document.addEventListener("keydown", function (evt) {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) return;
      if (evt.key === "u") panel.unzoom();
      else if (evt.key === "a") panel.autoscale();
      else if (evt.key === "g") panel.toggleGrid();
      else if (evt.key === "h" || evt.key === "?") {
        help.setAttribute("display", help.getAttribute("display") === "none" ? "inline" : "none");
      }
    });

    panels.forEach(function (p) { p.loadState(); });
    if (refresh > 0) {
      (function reload() {
        setTimeout(function () { if (drag) reload(); else location.reload(); }, refresh * 1000);
      })();
    }
  }

  function helpOverlay(svg) {
    var lines = ["wheel: zoom (shift: x only, ctrl: y only)", "left drag: pan",
      "right drag: zoom box", "u: undo zoom", "a: autoscale", "g: toggle grid",
      "h: toggle this help"];
    var group = element(svg, "g", {display: "none"});
    element(group, "rect", {x: 20, y: 20, width: 260, height: 16 * lines.length + 12,
      fill: "white", stroke: "#555", opacity: 0.95});
    lines.forEach(function (text, i) {
      element(group, "text", {x: 30, y: 38 + 16 * i, "font-size": 12}).textContent = text;
    });
    return group;
  }

  start();
})();
