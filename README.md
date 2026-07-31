# Lozenge

A Jira-flavoured, Bootstrap-style SASS component framework. Original CSS written against the Atlassian design-token palette — the familiar Jira look (N800 text, B400 blues, 8px grid, 3px radii, the lozenge status pill) with Bootstrap-esque class naming (`.btn .btn-primary`, `.badge`, `.modal`, spacing utilities).

**Not affiliated with Atlassian.** No code was copied from Jira; this is an independent implementation of the visual style for internal projects.

## Quick start

```bash
npm install          # pulls dart-sass + vite
npm run dev          # vite dev server, opens the kitchen-sink demo with SCSS HMR
npm run build        # -> dist/lozenge.css + dist/lozenge.min.css
npm run watch        # rebuild on change
```

Drop the compiled sheet into any page:

```html
<link rel="stylesheet" href="dist/lozenge.min.css">
<button class="btn btn-primary">Create</button>
<span class="lozenge lozenge-inprogress">In progress</span>
```

Or consume the source with your own Sass build, overriding tokens Bootstrap-style:

```scss
// Configure tokens BEFORE loading the framework — !default values yield to yours.
@use "lozenge/scss/tokens" with (
  $primary: #6554C0,
  $font-size-base: 15px,
);
@use "lozenge/scss/lozenge";
```

A curated set of tokens is also emitted as CSS custom properties (`--lz-primary`, `--lz-text-subtle`, `--lz-shadow-overlay`, …) for JS and plain-CSS use.

## What's in the box

| Area | Classes |
| --- | --- |
| Buttons | `.btn`, `.btn-primary/-warning/-danger/-subtle/-link/-subtle-link`, `.btn-compact`, `.btn-icon`, `.btn-block`, `.btn-group`, `.active`, `:disabled` |
| Lozenges | `.lozenge` + `-default/-inprogress/-moved/-new/-removed/-success`, `.lozenge-bold` |
| Badges & tags | `.badge` (+`-primary/-important/-added/-removed`), `.tag`, `.tag-rounded`, `.tag-remove` |
| Avatars | `.avatar` + `-xs/-sm/-md/-lg/-xl`, `.avatar-square`, presence `-online/-busy/-offline`, `.avatar-group` |
| Forms | `.form-group/-label/-text`, `.form-control` (+`-compact/-subtle`), `.form-select`, `.is-invalid`, `.form-check`, `.toggle` (+`-lg`) |
| Cards & board | `.card` (+header/body/footer), `.issue-card`, `.issue-type-story/-bug/-task/-epic`, `.board`, `.board-column` |
| Navigation | `.navbar` (+`-primary`), `.nav-link`, `.sidebar`, `.sidebar-item/-section`, `.tabs`/`.tab`, `.breadcrumbs` |
| Overlays | `.dropdown`/`.dropdown-menu` (open via `.open`/`.show`), `.blanket`, `.modal` (+`-small/-medium/-large/-xlarge`), `[data-tooltip]` (+`.tooltip-bottom/-left/-right`) |
| Feedback | `.message` + `-info/-warning/-error/-success/-discovery`, `.banner` (+`-warning/-error`), `.flag` (+bold variants, `.flag-fixed`), `.progress` (+segmented), `.spinner` |
| Tables | `.table`, `.table-hover/-striped/-compact`, `.sortable` |
| Typography | `h1–h6` mapped to the Atlassian scale, `.h100–.h900` classes |
| Utilities | text/bg colors, `.shadow-raised/-overlay/-modal`, spacing `.m*/.p*` 0–8 on the 8px grid, flex/display, `.gap-*`, borders/radii |

## Demo

`npm run dev` serves the kitchen-sink demo at `http://localhost:5173/demo/` — it imports `scss/lozenge.scss` directly, so any token or component edit hot-reloads in the browser.

## Structure

```
scss/
  lozenge.scss        entry point
  _tokens.scss        all design tokens (palette, type, spacing, shadows) — !default
  _mixins.scss        focus-ring, heading(), truncate, visually-hidden
  _reset.scss         base element styles
  _root.scss          CSS custom properties
  _typography.scss    heading scale
  _utilities.scss     Bootstrap-style utility classes
  components/         one file per component
```
