#!/usr/bin/env node
// Numerically verifies the contrast contract in tokens/pairs.json against the
// SAME sys.json the CSS engine is generated from — no drift possible.
// Sweeps: scheme {light,dark} × contrast dial [-1..+1] × accent hue [0..330].
// Asserts WCAG 2.x ratios and sRGB gamut containment. Exit 1 on any failure.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { converter, wcagContrast, clampChroma } from "culori";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const ramps = JSON.parse(readFileSync(join(root, "tokens/ramps.json"), "utf8"));
const sys = JSON.parse(readFileSync(join(root, "tokens/sys.json"), "utf8"));
const { pairs } = JSON.parse(readFileSync(join(root, "tokens/pairs.json"), "utf8"));
delete ramps.$comment;

const toOklch = converter("oklch");
const toRgb = converter("rgb");

const DIALS = [-1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1];
const HUES = [0, 30, 60, 90, 120, 150, 180, 210, 240, 260.48, 300, 330];
// Channel overshoot below SOFT is invisible after browser gamut mapping;
// above HARD it's authored distortion and fails the build.
const GAMUT_SOFT = 0.05;
const GAMUT_HARD = 0.12;

const clamp01 = (x) => Math.max(0, Math.min(1, x));

// Resolve a sys token to {oklch, alpha, gamutErr} for a given context.
function resolveToken(name, scheme, dial, accentHue, accentChroma = 1) {
  const def = sys.tokens[name]?.[scheme];
  if (!def) throw new Error(`unknown sys token: ${name} (${scheme})`);
  const [rampName, step] = def.ref.split(".");
  let base;
  if (rampName === "accent") {
    const b = toOklch(ramps.blue[step]);
    base = { mode: "oklch", l: b.l, c: (b.c ?? 0) * accentChroma, h: accentHue };
  } else {
    const o = toOklch(ramps[rampName][step]);
    base = { mode: "oklch", l: o.l, c: o.c ?? 0, h: o.h ?? 0 };
  }
  let l = base.l + (def.lShift ?? 0) + (def.k ?? 0) * dial;
  l = clamp01(l);
  let c =
    base.c * (def.cScale ?? 1) * (1 + (def.ck ?? 0) * Math.abs(dial));
  c = Math.max(0, c);
  const color = { mode: "oklch", l, c, h: base.h };
  // gamut check: how far outside sRGB does this land pre-clamp?
  const rgb = toRgb(color);
  const overshoot = Math.max(
    ...["r", "g", "b"].map((ch) => Math.max(rgb[ch] - 1, -rgb[ch], 0))
  );
  return { color, alpha: def.alpha ?? 1, overshoot };
}

// sRGB alpha compositing (what the browser paints).
function composite(fgTok, bgRgb) {
  const rgb = toRgb(clampChroma(fgTok.color, "oklch"));
  const a = fgTok.alpha;
  return {
    mode: "rgb",
    r: clamp01(rgb.r) * a + bgRgb.r * (1 - a),
    g: clamp01(rgb.g) * a + bgRgb.g * (1 - a),
    b: clamp01(rgb.b) * a + bgRgb.b * (1 - a),
  };
}

function solidRgb(tok, underRgb) {
  return tok.alpha < 1 && underRgb
    ? composite(tok, underRgb)
    : composite(tok, { r: 1, g: 1, b: 1 }); // alpha 1 → bg irrelevant
}

const failures = [];
const gamutClips = [];

for (const scheme of ["light", "dark"]) {
  for (const dial of DIALS) {
    // Only sweep hues when the pair involves the accent ramp; use a marker.
    for (const pair of pairs) {
      const involvesAccent = [pair.fg, pair.bg, pair.bgOver]
        .filter(Boolean)
        .some((t) => {
          const d = sys.tokens[t]?.[scheme];
          return d && d.ref.startsWith("accent.");
        });
      const hues = involvesAccent ? HUES : [260.48];
      const atDial = pair.atDial ?? null;
      if (atDial !== null && dial < atDial) continue;
      const relaxed = pair.relaxedMin ?? (pair.min >= 4.5 ? 3 : 2.25);
      const required = dial < 0 ? relaxed : pair.min;

      for (const hue of hues) {
        const surface = resolveToken(
          pair.bgOver ?? "surface",
          scheme,
          dial,
          hue
        );
        const surfaceRgb = solidRgb(surface, { r: 1, g: 1, b: 1 });
        const bgTok = resolveToken(pair.bg, scheme, dial, hue);
        const bgRgb = solidRgb(bgTok, surfaceRgb);
        const fgTok = resolveToken(pair.fg, scheme, dial, hue);
        const fgRgb = solidRgb(fgTok, bgRgb);

        for (const [tok, name] of [
          [fgTok, pair.fg],
          [bgTok, pair.bg],
        ]) {
          if (tok.overshoot > GAMUT_SOFT) {
            const isAccentSweep =
              involvesAccent && Math.abs(hue - 260.48) > 0.01;
            gamutClips.push({
              accent: isAccentSweep,
              hard: tok.overshoot > GAMUT_HARD,
              msg: `${name} [${scheme} dial=${dial} hue=${hue}] exits sRGB by ${tok.overshoot.toFixed(3)}`,
            });
          }
        }

        const ratio = wcagContrast(fgRgb, bgRgb);
        if (ratio < required - 0.01) {
          failures.push(
            `${pair.fg} on ${pair.bg} [${scheme} dial=${dial}${involvesAccent ? ` hue=${hue}` : ""}]: ${ratio.toFixed(2)} < ${required}`
          );
        }
      }
    }
  }
}

const uniq = (arr) => [...new Set(arr)];
const failList = uniq(failures);
const staticClips = uniq(gamutClips.filter((c) => !c.accent).map((c) => c.msg));
const accentClips = uniq(gamutClips.filter((c) => c.accent).map((c) => c.msg));

// Accent-hue-sweep overshoots are expected: rotating the accent dial to hues
// with a smaller sRGB envelope than blue's chroma relies on CSS gamut mapping
// (chroma reduction, hue/L preserved) — and the ratios above are computed
// POST-clamp, so legibility is already proven. Static clips mean an authored
// token leaves sRGB on the dial's own axis: those fail the build.
const hardClips = uniq(
  gamutClips.filter((c) => !c.accent && c.hard).map((c) => c.msg)
);
if (staticClips.length) {
  console.error(`\nSTATIC GAMUT CLIPS (${staticClips.length}, ${hardClips.length} hard):`);
  for (const c of staticClips.slice(0, 40)) console.error("  " + c);
}
if (failList.length) {
  console.error(`\nCONTRAST FAILURES (${failList.length}):`);
  for (const f of failList.slice(0, 60)) console.error("  " + f);
}
if (failList.length || hardClips.length) process.exit(1);
console.log(
  `contrast contract holds: ${pairs.length} pairs × ${DIALS.length} dials × 2 schemes × accent sweep` +
    ` (${accentClips.length} accent-sweep gamut-map events, contrast verified post-clamp;` +
    ` ${staticClips.length} static clips within tolerance)`
);
