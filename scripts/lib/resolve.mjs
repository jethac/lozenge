// Shared sys-token resolver — the single implementation of the axis math.
// Consumed by check-contrast.mjs (CI proof), build-dart-tokens.mjs (Flutter
// fixture), and any future engine target. Mirrors the CSS emitted by
// build-tokens.mjs; change one, change all.

import { converter, clampChroma } from "culori";

const toOklch = converter("oklch");
const toRgb = converter("rgb");

export const clamp01 = (x) => Math.max(0, Math.min(1, x));

// Resolve a sys token to {color: oklch, alpha, overshoot} for a context.
export function resolveToken(
  ramps,
  sys,
  name,
  scheme,
  dial,
  accentHue,
  accentChroma = 1
) {
  const def = sys.tokens[name]?.[scheme];
  if (!def) throw new Error(`unknown sys token: ${name} (${scheme})`);
  const [rampName, step] = def.ref.split(".");
  let base;
  if (rampName === "accent") {
    const b = toOklch(ramps.blue[step]);
    base = {
      mode: "oklch",
      l: b.l,
      c: (b.c ?? 0) * accentChroma,
      h: accentHue,
    };
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
  const rgb = toRgb(color);
  const overshoot = Math.max(
    ...["r", "g", "b"].map((ch) => Math.max(rgb[ch] - 1, -rgb[ch], 0))
  );
  return { color, alpha: def.alpha ?? 1, overshoot };
}

// sRGB alpha compositing (what the browser paints).
export function composite(fgTok, bgRgb) {
  const rgb = toRgb(clampChroma(fgTok.color, "oklch"));
  const a = fgTok.alpha;
  return {
    mode: "rgb",
    r: clamp01(rgb.r) * a + bgRgb.r * (1 - a),
    g: clamp01(rgb.g) * a + bgRgb.g * (1 - a),
    b: clamp01(rgb.b) * a + bgRgb.b * (1 - a),
  };
}

export function solidRgb(tok, underRgb) {
  return tok.alpha < 1 && underRgb
    ? composite(tok, underRgb)
    : composite(tok, { r: 1, g: 1, b: 1 });
}

// Gamut-clamped sRGB (pre-composite) with alpha preserved — what a
// non-compositing engine (Flutter) should produce per token.
export function clampedRgba(tok) {
  const rgb = toRgb(clampChroma(tok.color, "oklch"));
  return {
    r: clamp01(rgb.r),
    g: clamp01(rgb.g),
    b: clamp01(rgb.b),
    a: tok.alpha,
  };
}
