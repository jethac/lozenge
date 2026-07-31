# Lozenge

A Jira-flavoured design system with **runtime theme axes** — built as original CSS on the published Atlassian palette anchors, with Bootstrap-style class ergonomics.

**Demo: [lozenge.jethachan.net](https://lozenge.jethachan.net)** · Not affiliated with Atlassian.

What makes it different from a themeable CSS framework:

- **Continuous contrast dial.** `--lz-contrast` is a numeric axis from −1 to +1, resolved through OKLCH relative color at runtime — no rebuild, animatable, drivable from a slider, your own logic, or a physical knob. OS `prefers-contrast` maps onto it (including *reduced* contrast for photophobic users). Every declared text/surface pair is CI-verified against WCAG 2.2 ratios at every dial position, in both schemes, across a 12-hue accent sweep (`npm run check`).
- **Parametric accent.** `--lz-accent-hue` / `--lz-accent-chroma` rotate the entire accent system live; Jira blue is just the dial's resting position.
- **Glass materials.** Overlay surfaces (navbar, menus, modals, flags) are frosted glass whose alpha is a function of the contrast dial — glass fades to solid as contrast rises — gated behind `@supports`, `prefers-reduced-transparency`, and forced-colors, with the solid rendering as the designed-first canonical state (`--lz-glass`).
- **The platform is the behavior layer.** Modals are native `<dialog>` (+ `commandfor`), dropdowns are `popover` + CSS anchor positioning (with `@supports` fallback), accordions are `<details name>`, tabs are radios + `:has()`. Lozenge ships **zero runtime JavaScript**.
- **Compile-time components.** `<lz-modal title="…">`-style tags macro-expand to canonical HTML at build time (Vite plugin or `lz-expand` CLI). The shipped artifact is inert HTML+CSS any stack can consume; `--react` emits JSX-friendly output.
- **Agent-readable contracts.** Every component publishes a `specs/*.json` markup contract (structure, variants, ARIA); `lozenge-lint` validates rendered HTML against them in CI, and `llms.txt` compiles the whole system into agent context.

## Quick start

```bash
npm install
npm run dev        # vite: demo with SCSS HMR + theme-axis control panel
npm run build      # tokens → dist/lozenge.css + dist/lozenge.min.css
npm run check      # contrast/gamut contract (also runs in CI)
```

Drop-in use:

```html
<link rel="stylesheet" href="dist/lozenge.min.css">
<button class="btn btn-primary">Create</button>
<span class="lozenge lozenge-inprogress">In progress</span>
```

Theme at runtime — everything below is live, no rebuild:

```js
const root = document.documentElement;
root.dataset.theme = "dark";                          // scheme
root.style.setProperty("--lz-contrast", 0.5);          // more contrast
root.style.setProperty("--lz-accent-hue", 152);        // green accent
root.style.setProperty("--lz-glass", 0);               // solid materials
```

## Token architecture

Three tiers, generated from `tokens/ramps.json` + `tokens/sys.json` by `scripts/build-tokens.mjs`:

1. **Reference** — `--lz-ref-<ramp>-<step>`: OKLCH ramps fitted to the Atlassian hex anchors, plus a parametric accent ramp derived from the blue ramp's lightness/chroma curve with hue/chroma taken from the dials.
2. **System** — `--lz-sys-*`: semantic roles (`text`, `surface-overlay`, `status-danger-subtle-bg`, …) expressed as relative-color functions of the reference tier and the contrast dial. Light scheme on `:root`, dark under `[data-theme="dark"]` (with `prefers-color-scheme` fallback).
3. **Component** — Sass-level tokens consumed by the ~20 components.

The same `sys.json` is evaluated numerically by `scripts/check-contrast.mjs` — the CSS and the CI proof cannot drift. A DTCG v2025.10 export is generated at `tokens/lozenge.tokens.json`.

Sass consumers can still override compile-time tokens Bootstrap-style:

```scss
@use "lozenge/scss/tokens" with ($font-size-base: 15px);
@use "lozenge/scss/lozenge";
```

## Authoring tags

```html
<lz-board-column title="In progress" count="3">
  <lz-issue-card type="story" key="LOZ-9">
    Dark mode token pass
    <lz-lozenge slot="meta" status="inprogress">In progress</lz-lozenge>
    <lz-avatar slot="meta" size="sm">AB</lz-avatar>
  </lz-issue-card>
</lz-board-column>
```

Expanded by the Vite plugin at serve/build time, or `node scripts/lz-expand.mjs --write page.html`. Templates live in `templates/` and version-lock with the CSS; expanded roots are stamped `data-lz-version`, and `lz-expand --check` flags stale output after an upgrade.

## Components

Buttons, lozenges, badges, tags, avatars, forms (inputs/selects/checks/toggles), cards + issue cards, kanban board, navbar, sidebar (`<details name>` groups), tabs (CSS-only tabset), breadcrumbs, dropdown (`popover`+anchor), modal (`<dialog>`), tooltips (CSS-only), section messages, banners, flags, tables, progress, spinners — plus text/bg/spacing/flex utilities on the 8px grid and an `h100–h900` type scale.

## Accessibility

WCAG 2.2 AA ratios are the normative CI gate (APCA advisory only). Forced-colors mode gets a dedicated pass (transparent borders for elevation, outline-based focus, system Highlight selection, glass/dial disabled). `prefers-reduced-motion` collapses all motion. The negative half of the contrast dial deliberately serves `prefers-contrast: less`.

## Flutter

`packages/lozenge_flutter` is the Flutter arm: the same `tokens/*.json` generates a Dart token engine (`tokens.g.dart`) with the identical four runtime axes — `LzThemeData(dark:, contrast:, accentHue:, accentChroma:, glass:)` — resolved through a Dart OKLCH implementation whose output is CI-proven to match the web engine within ±2/255 per channel (a generated fixture of resolved colors is asserted by `flutter test`). `AnimatedLzTheme` makes axis changes sweep implicitly. On top: a Jira-flavoured widget set (`LzButton`, `LzLozenge`, `LzIssueCard`, `LzBoard`, `LzModal`, `LzMenu`, `LzSidebar`, trackers, skeletons, comments, …) plus a kitchen-sink example app with live axis sliders.

## Structure

```
tokens/        ramps.json, sys.json, pairs.json — the design source of truth
scripts/       build-tokens, check-contrast, expand, lz-expand, lozenge-lint
scss/          tokens, mixins, reset, typography, a11y, utilities, components/
templates/     lz-* expansion templates
specs/         per-component markup contracts (agent-readable)
demo/          kitchen-sink + lz-tags demo + theme panel
```
