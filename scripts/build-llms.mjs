#!/usr/bin/env node
// build-llms — generates llms.txt at the repo root from specs/*.json and
// tokens/sys.json. Output is deterministic (derived purely from inputs,
// no timestamps).
//
// Usage: node scripts/build-llms.mjs

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const specsDir = path.join(repoRoot, "specs");
const sysTokensPath = path.join(repoRoot, "tokens", "sys.json");
const outPath = path.join(repoRoot, "llms.txt");

// ---------------------------------------------------------------- specs

const blocks = [];
const topSpecs = fs.readdirSync(specsDir).filter((x) => x.endsWith(".json")).sort()
  .map((f) => JSON.parse(fs.readFileSync(path.join(specsDir, f), "utf8")))
  // Alphabetical by DISPLAY name, not filename (backlog lives in
  // planning.json, select in listbox.json).
  .sort((a, b) => (a.component < b.component ? -1 : a.component > b.component ? 1 : 0));
for (const spec of topSpecs) {
  blocks.push(spec);
  for (const sub of spec.subcomponents ?? []) blocks.push(sub);
}

// ---------------------------------------------------------------- tokens

const sys = JSON.parse(fs.readFileSync(sysTokensPath, "utf8")).tokens;

const TOKEN_GROUPS = [
  { title: "Text", note: "Foreground text colors; -on-bold/-inverse sit on bold/status backgrounds.", match: (n) => n.startsWith("text") },
  { title: "Links", note: "Anchor colors for rest/hover/active states.", match: (n) => n.startsWith("link") },
  { title: "Surfaces", note: "Background layers: base page, sunken wells, raised cards, overlay popups.", match: (n) => n.startsWith("surface") },
  { title: "Borders & separators", note: "Hairline borders on controls and dividers between regions.", match: (n) => n === "border" || n === "separator" },
  { title: "Focus & selection", note: "Focus ring and selected-item background/text.", match: (n) => n === "focus-ring" || n.startsWith("selected-") },
  { title: "Interaction states", note: "Translucent hover/pressed washes and the modal blanket.", match: (n) => n.startsWith("interaction-") || n === "blanket" },
  { title: "Bold action colors", note: "Solid button fills (accent/danger/warning) with hovered/pressed steps.", match: (n) => /^(accent|danger|warning)-bold/.test(n) },
  { title: "Form controls", note: "Input backgrounds, toggle track, progress track, tooltip surface.", match: (n) => n.startsWith("input-") || n === "toggle-off" || n === "track" || n.startsWith("tooltip-") },
  { title: "Status", note: "Per-family (neutral/info/warning/danger/success/discovery) subtle bg+text and bold bg+on-bold pairs used by lozenge, message, banner, flag.", match: (n) => n.startsWith("status-") },
];

function groupTokens() {
  const names = Object.keys(sys); // JSON insertion order — deterministic
  const grouped = TOKEN_GROUPS.map((g) => ({ ...g, names: [] }));
  const rest = [];
  for (const n of names) {
    const g = grouped.find((x) => x.match(n));
    if (g) g.names.push(n);
    else rest.push(n);
  }
  if (rest.length) grouped.push({ title: "Other", note: "Ungrouped system tokens.", names: rest });
  return grouped.filter((g) => g.names.length);
}

// ---------------------------------------------------------------- render

const out = [];

out.push(`# Lozenge

Lozenge is a Jira-flavoured design system: SCSS + CSS custom properties, plain
class-based HTML components (no JavaScript required for core components — tabs,
accordions, modals and dropdowns ride on radios, <details>, <dialog> and
popover/anchor positioning).

Theming is runtime-parametric via four CSS custom properties on :root:

- --lz-contrast      contrast boost, 0..1 (shifts lightness/chroma of system colors)
- --lz-accent-hue    OKLCH hue of the accent ramp (default 260.48 — Jira blue)
- --lz-accent-chroma accent chroma multiplier (0 = grayscale accent)
- --lz-glass         frosted-glass materials on/off (navbar, modal, dropdown, flag, consent, mega-menu)

Dark scheme: set data-theme="dark" on <html> (system tokens carry light and dark
values; components never hard-code scheme colors).

Color layers: --lz-ref-* are raw ramps (accent ramp is parametric); --lz-sys-*
are the semantic tokens components consume. Always style with --lz-sys-*.

Markup contracts below are machine-checked by scripts/lozenge-lint.mjs against
specs/*.json. Rules of thumb: variant classes on one axis are mutually
exclusive; "required" axes must have exactly one class; glass surfaces
(navbar, dropdown-menu, modal, flag, consent, mega-menu) must never nest
inside each other.
`);

out.push("## Components\n");

for (const b of blocks) {
  const root = b.root;
  out.push(`### ${b.component}`);
  out.push("");
  out.push(b.intent.trim());
  out.push("");
  const el = root.element?.length ? ` (element: ${root.element.join(" | ")})` : "";
  out.push(`- Root: \`${root.selector}\`${el}`);
  for (const [axis, def] of Object.entries(b.variants ?? {})) {
    const flags = [def.required ? "required" : "optional", def.exclusive ? "pick one" : "combinable"].join(", ");
    out.push(`- Variants (${axis}; ${flags}): ${def.classes.map((c) => `\`${c}\``).join(", ")}`);
  }
  if (b.modifiers?.length) {
    out.push(`- Modifiers: ${b.modifiers.map((c) => `\`${c}\``).join(", ")}`);
  }
  const reqStruct = (b.structure ?? []).filter((s) => s.required);
  if (reqStruct.length) {
    out.push(`- Required structure: ${reqStruct.map((s) => `\`${s.selector}\``).join(", ")}`);
  }
  if (b.examples?.length) {
    out.push("");
    out.push("```html");
    out.push(b.examples[0]);
    out.push("```");
  }
  out.push("");
}

out.push("## Material / Flutter → Lozenge cheat sheet\n");
out.push(
  "If you know Google's Material or Flutter widget names, translate with this table (full version: /docs/material.html).\n"
);
{
  const map = JSON.parse(
    fs.readFileSync(path.join(repoRoot, "tokens", "material-map.json"), "utf8")
  );
  for (const sec of map.sections) {
    out.push(`### ${sec.title}`);
    out.push("");
    for (const r of sec.rows) {
      const note = r.note ? ` — ${r.note}` : "";
      out.push(`- ${r.material} (${r.flutter}) → \`${r.lozenge}\`${note}`);
    }
    out.push("");
  }
}

out.push("## System tokens (--lz-sys-*)\n");
out.push("Consume these as CSS custom properties, e.g. `color: var(--lz-sys-text)`.\n");

for (const g of groupTokens()) {
  out.push(`### ${g.title}`);
  out.push("");
  out.push(g.note);
  out.push("");
  for (const n of g.names) out.push(`- \`--lz-sys-${n}\``);
  out.push("");
}

const body = out.join("\n").replace(/\n{3,}/g, "\n\n").trimEnd() + "\n";
fs.writeFileSync(outPath, body);
// Also into public/ so Vite ships it to the deployed site's root.
fs.writeFileSync(path.join(repoRoot, "public", "llms.txt"), body);
console.log(`wrote ${path.relative(repoRoot, outPath)} (+public/) (${blocks.length} components, ${Object.keys(sys).length} sys tokens)`);
