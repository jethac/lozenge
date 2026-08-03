// build-docs — static documentation site generator for Lozenge.
//
// Reads specs/*.json + tokens/sys.json and emits docs/*.html: an overview
// page (theme axes, token tiers, full sys-token table) plus one page per
// top-level component contract. Pages are plain HTML that import the design
// system itself (scss + theme panel) and use Lozenge's own components for
// their chrome. Output is deterministic — no timestamps.
//
// Usage: node scripts/build-docs.mjs   (or: npm run docs)

import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expandLozenge } from "./expand.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const outDir = join(root, "docs");
const specsDir = join(root, "specs");

// ---------------------------------------------------------------- helpers

const esc = (s) =>
  String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

// Spec examples may reference image files that don't exist in this repo
// (e.g. avatar photos). Swap unresolvable relative srcs for an inline SVG
// placeholder so Vite's asset resolution doesn't fail the build.
const IMG_PLACEHOLDER =
  "data:image/svg+xml," +
  encodeURIComponent(
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'>" +
      "<rect width='32' height='32' fill='#6554C0'/>" +
      "<text x='16' y='21' font-size='13' text-anchor='middle' fill='#fff' font-family='sans-serif'>DK</text></svg>"
  );

const liveHtml = (html) =>
  html.replace(/src="(?!https?:|data:|\/|#)[^"]*"/g, `src="${IMG_PLACEHOLDER}"`);

// .card may not be used as the example container when the rendered example
// itself contains a .card or .issue-card root (the contracts forbid nesting
// them inside .card) — or a marketing-surface root like .hero/.promo, whose
// contracts forbid living inside a card at all — fall back to a plain
// bordered box.
function hasCardConflict(html) {
  for (const m of html.matchAll(/class="([^"]*)"/g)) {
    const tokens = m[1].split(/\s+/);
    if (
      tokens.includes("card") ||
      tokens.includes("issue-card") ||
      tokens.includes("hero") ||
      tokens.includes("promo")
    )
      return true;
  }
  return false;
}

/** An example container: live render first, escaped source(s) after. */
function exampleCard(title, renderedHtml, sources) {
  const conflict = hasCardConflict(renderedHtml);
  const [box, head, body] = conflict
    ? ["doc-box", "doc-box-header", "doc-box-body"]
    : ["card", "card-header", "card-body"];
  const pres = sources
    .map(
      ({ label, code }) =>
        (label ? `<p class="doc-src-label text-subtlest">${esc(label)}</p>` : "") +
        `<pre><code>${esc(code)}</code></pre>`
    )
    .join("\n");
  return `<div class="${box} doc-example">
  <div class="${head}">${esc(title)}</div>
  <div class="${body}">
    <div class="doc-live">${liveHtml(renderedHtml)}</div>
${pres}
  </div>
</div>`;
}

// ------------------------------------------------------------- page shell

const NAV_LINKS = [
  ["Home", "/"],
  ["Components", "/docs/"],
  ["Demo", "/demo/"],
  ["Tags", "/demo/tags.html"],
  ["GitHub", "https://github.com/jethac/lozenge"],
];

const DOCS_CSS = `
  .docs-shell { display: flex; align-items: stretch; }
  .docs-shell > .sidebar { flex-shrink: 0; min-height: calc(100vh - 56px); }
  .docs-main { flex: 1; min-width: 0; max-width: 880px; padding: 24px 32px 96px; }
  .docs-main section { margin-top: 40px; }
  .doc-example { margin: 12px 0 24px; }
  .doc-box { border: 1px solid var(--lz-sys-border); border-radius: 3px; background: var(--lz-sys-surface); }
  .doc-box-header { padding: 8px 16px; border-bottom: 1px solid var(--lz-sys-separator); font-weight: 600; }
  .doc-box-body { padding: 16px; }
  .doc-live { margin-bottom: 12px; }
  .doc-src-label { margin: 12px 0 4px; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }
  .doc-example pre { margin: 0 0 4px; }
  pre { background: var(--lz-sys-surface-sunken); border: 1px solid var(--lz-sys-separator); border-radius: 3px; padding: 12px; overflow-x: auto; font-size: 12px; line-height: 1.5; }
  pre code { font-family: inherit; }
  .doc-swatch { width: 48px; height: 24px; border: 1px solid var(--lz-sys-border); border-radius: 3px; }
  .doc-table-wrap { overflow-x: auto; }
  .doc-axis-pane { flex: 1 1 240px; min-width: 240px; padding: 16px; border: 1px solid var(--lz-sys-border); border-radius: 3px; background: var(--lz-sys-surface); color: var(--lz-sys-text); }
`;

function pageShell({ title, activeSlug, components, content }) {
  const navItems = NAV_LINKS.map(([label, href]) => {
    const active = label === "Components";
    return `    <li><a class="nav-link${active ? " active" : ""}" href="${href}">${label}</a></li>`;
  }).join("\n");

  const sideItem = (slug, label) => {
    const active = slug === activeSlug;
    return `      <a class="sidebar-item${active ? " active" : ""}" href="${
      slug === "index" ? "index.html" : `${slug}.html`
    }"${active ? ' aria-current="page"' : ""}>${label}</a>`;
  };

  const componentItems = components
    .map((c) => sideItem(c, cap(c)))
    .join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)} — Lozenge</title>
<script type="module">import "../scss/lozenge.scss";</script>
<script type="module" src="../demo/theme-panel.js"></script>
<style>${DOCS_CSS}</style>
</head>
<body>

<nav class="navbar" aria-label="Main">
  <a class="navbar-brand" href="/">Lozenge</a>
  <ul class="navbar-nav">
${navItems}
  </ul>
</nav>

<div class="docs-shell">
  <aside class="sidebar">
    <div class="sidebar-section">Guide</div>
    <nav aria-label="Guide">
${sideItem("index", "Overview")}
${sideItem("material", "Material → Lozenge")}
    </nav>
    <div class="sidebar-section">Components</div>
    <nav aria-label="Components">
${componentItems}
    </nav>
  </aside>
  <main class="docs-main">
${content}
  </main>
</div>

</body>
</html>
`;
}

// -------------------------------------------------- authoring-tag examples

// Hand-written <lz-*> snippets for components whose page has a matching
// expansion template in templates/. The source is shown escaped; the
// expanded HTML (produced here at build time) is rendered live.
const AUTHORING = {
  lozenge: {
    title: "Authoring tags — <lz-lozenge>",
    source: `<lz-lozenge status="inprogress">In progress</lz-lozenge>
<lz-lozenge status="success" bold>Done</lz-lozenge>`,
  },
  badge: {
    title: "Authoring tags — <lz-badge>",
    source: `<lz-badge>25</lz-badge>
<lz-badge appearance="important">8</lz-badge>`,
  },
  avatar: {
    title: "Authoring tags — <lz-avatar>",
    source: `<lz-avatar presence="online">JC</lz-avatar>
<lz-avatar size="lg" square>P</lz-avatar>`,
  },
  message: {
    title: "Authoring tags — <lz-message> and <lz-flag>",
    source: `<lz-message variant="warning" title="Trial ending">
  <p>Your trial expires in 3 days.</p>
</lz-message>
<lz-flag title="Issue created" icon="story" actions="true">
  LOZ-42 has been added to the backlog.
  <a slot="actions" href="#">View issue</a>
</lz-flag>`,
  },
  card: {
    title: "Authoring tags — <lz-issue-card>",
    source: `<lz-issue-card type="bug" key="LOZ-14">
  Login page throws redirect loop on expired session
  <lz-avatar slot="meta" size="sm">DK</lz-avatar>
</lz-issue-card>`,
  },
  board: {
    title: "Authoring tags — <lz-board-column>",
    source: `<div class="board">
  <lz-board-column title="To do" count="2">
    <lz-issue-card type="task" key="LOZ-12">
      Set up CI pipeline for nightly builds
      <lz-badge slot="meta">3</lz-badge>
      <lz-avatar slot="meta" size="sm">JC</lz-avatar>
    </lz-issue-card>
    <lz-issue-card type="bug" key="LOZ-14">
      Login page throws redirect loop on expired session
      <lz-avatar slot="meta" size="sm">DK</lz-avatar>
    </lz-issue-card>
  </lz-board-column>
</div>`,
  },
};

// ------------------------------------------------------- component pages

function variantTable(block) {
  const axes = Object.entries(block.variants ?? {});
  const mods = block.modifiers ?? [];
  const rows = [];
  for (const [axis, def] of axes) {
    const rules = [
      def.required ? "one required" : "optional",
      def.exclusive ? "exclusive" : null,
    ]
      .filter(Boolean)
      .join(" · ");
    for (const cls of def.classes) {
      rows.push(
        `      <tr><td><code>${esc(cls)}</code></td><td>${esc(axis)}</td><td>${rules}</td></tr>`
      );
    }
  }
  for (const m of mods) {
    rows.push(
      `      <tr><td><code>${esc(m)}</code></td><td>modifier</td><td>optional</td></tr>`
    );
  }
  if (!rows.length) return "";
  return `  <h3>Variants &amp; modifiers</h3>
  <div class="doc-table-wrap"><table class="table table-compact">
    <thead><tr><th>Class</th><th>Axis</th><th>Rules</th></tr></thead>
    <tbody>
${rows.join("\n")}
    </tbody>
  </table></div>`;
}

function structureTable(block) {
  const entries = block.structure ?? [];
  if (!entries.length) return "";
  const rows = entries
    .map(
      (e) =>
        `      <tr><td><code>${esc(e.selector)}</code></td><td>${
          e.required ? "required" : "optional"
        }</td><td>${esc(e.description ?? "")}</td></tr>`
    )
    .join("\n");
  return `  <h3>Structure</h3>
  <div class="doc-table-wrap"><table class="table table-compact">
    <thead><tr><th>Selector</th><th>Required</th><th>Description</th></tr></thead>
    <tbody>
${rows}
    </tbody>
  </table></div>`;
}

function ariaSection(block) {
  const rules = block.aria ?? [];
  const notes = block.a11yNotes;
  if (!rules.length && !notes) return "";
  let out = "  <h3>Accessibility</h3>";
  if (rules.length) {
    const rows = rules
      .map(
        (r) =>
          `      <tr><td><code>${esc(r.on)}</code></td><td><code>${esc(r.attr)}</code></td><td>${
            r.required ? "required" : "recommended"
          }</td><td>${esc(r.when ?? "")}</td></tr>`
      )
      .join("\n");
    out += `
  <div class="doc-table-wrap"><table class="table table-compact">
    <thead><tr><th>On</th><th>Attribute</th><th>Level</th><th>When</th></tr></thead>
    <tbody>
${rows}
    </tbody>
  </table></div>`;
  }
  if (notes) out += `\n  <p class="text-subtle">${esc(notes)}</p>`;
  return out;
}

function nestingSection(block) {
  const n = block.nesting;
  if (!n) return "";
  const list = (items) => items.map((i) => `<li><code>${esc(i)}</code></li>`).join(" ");
  let out = "  <h3>Nesting</h3>";
  if (n.allowedIn?.length)
    out += `\n  <p>Allowed in:</p>\n  <ul>${list(n.allowedIn)}</ul>`;
  if (n.disallowed?.length)
    out += `\n  <p>Never inside (or containing):</p>\n  <ul>${list(n.disallowed)}</ul>`;
  return out;
}

function rootLine(block) {
  const r = block.root;
  if (!r) return "";
  const els = (r.element ?? []).map((e) => `<code>&lt;${esc(e)}&gt;</code>`).join(", ");
  return `  <p class="text-subtlest">Root: <code>${esc(r.selector)}</code>${
    els ? ` on ${els}` : ""
  }</p>`;
}

function exampleSection(block, headingLevel = 3) {
  const examples = block.examples ?? [];
  if (!examples.length) return "";
  const cards = examples
    .map((ex, i) =>
      exampleCard(`Example${examples.length > 1 ? ` ${i + 1}` : ""}`, ex, [
        { label: "", code: ex },
      ])
    )
    .join("\n");
  return `  <h${headingLevel}>Example${examples.length > 1 ? "s" : ""}</h${headingLevel}>\n${cards}`;
}

function blockSections(block) {
  return [variantTable(block), structureTable(block), ariaSection(block), nestingSection(block)]
    .filter(Boolean)
    .join("\n");
}

function componentPage(spec, components) {
  const name = spec.component;
  const parts = [];

  parts.push(`<h1>${esc(cap(name))}</h1>`);
  parts.push(`<p class="text-subtle">${esc(spec.intent)}</p>`);
  parts.push(rootLine(spec));

  parts.push(`<section>\n${exampleSection(spec, 2).replace(/^ {2}<h2/, "<h2")}`);

  const authoring = AUTHORING[name];
  if (authoring) {
    const expanded = expandLozenge(authoring.source);
    parts.push(
      exampleCard(authoring.title, expanded, [
        { label: "Authoring source", code: authoring.source },
        { label: "Expands to", code: expanded },
      ])
    );
    parts.push(
      `<p class="text-subtle">Authoring tags are macro-expanded to the canonical HTML above at build time (Vite plugin or <code>lz-expand</code> CLI) — the shipped artifact has no runtime.</p>`
    );
  }
  parts.push(`</section>`);

  const contract = blockSections(spec);
  if (contract) parts.push(`<section>\n<h2>Contract</h2>\n${contract}\n</section>`);

  const subs = spec.subcomponents ?? [];
  if (subs.length) {
    parts.push(`<section>\n<h2>Subcomponents</h2>`);
    for (const sub of subs) {
      parts.push(`<section id="${esc(sub.component)}">`);
      parts.push(`<h3>${esc(cap(sub.component))}</h3>`);
      parts.push(`<p class="text-subtle">${esc(sub.intent)}</p>`);
      parts.push(rootLine(sub));
      parts.push(exampleSection(sub, 4));
      const subContract = blockSections(sub)
        .replaceAll("<h3>", "<h4>")
        .replaceAll("</h3>", "</h4>");
      if (subContract) parts.push(subContract);
      parts.push(`</section>`);
    }
    parts.push(`</section>`);
  }

  return pageShell({
    title: cap(name),
    activeSlug: name,
    components,
    content: parts.filter(Boolean).join("\n"),
  });
}

// ---------------------------------------------------------- overview page

const SYS_CATEGORIES = [
  ["Text", (n) => n.startsWith("text")],
  ["Links", (n) => n.startsWith("link")],
  ["Surfaces", (n) => n.startsWith("surface") || n === "blanket"],
  ["Borders & separators", (n) => n === "border" || n === "separator"],
  ["Focus & selection", (n) => n.startsWith("focus") || n.startsWith("selected")],
  ["Interaction states", (n) => n.startsWith("interaction")],
  ["Bold accents", (n) => /^(accent|danger|warning)-bold/.test(n)],
  ["Controls", (n) => n.startsWith("input") || n.startsWith("toggle") || n === "track" || n.startsWith("tooltip")],
  ["Status", (n) => n.startsWith("status-")],
  ["Other", () => true],
];

function refLabel(entry) {
  if (!entry) return "";
  const extras = [];
  if (entry.k !== undefined) extras.push(`k ${entry.k}`);
  if (entry.ck !== undefined) extras.push(`ck ${entry.ck}`);
  if (entry.alpha !== undefined) extras.push(`α ${entry.alpha}`);
  return `<code>${esc(entry.ref)}</code>${
    extras.length ? ` <span class="text-subtlest">(${esc(extras.join(", "))})</span>` : ""
  }`;
}

function sysTokenTables(sys) {
  const names = Object.keys(sys.tokens);
  const grouped = new Map(SYS_CATEGORIES.map(([label]) => [label, []]));
  for (const name of names) {
    const [label] = SYS_CATEGORIES.find(([, test]) => test(name));
    grouped.get(label).push(name);
  }
  const sections = [];
  for (const [label, group] of grouped) {
    if (!group.length) continue;
    const rows = group
      .map((name) => {
        const t = sys.tokens[name];
        return `      <tr>
        <td><code>--lz-sys-${esc(name)}</code></td>
        <td><div class="doc-swatch" style="background: var(--lz-sys-${esc(name)})"></div></td>
        <td>${refLabel(t.light)}</td>
        <td>${refLabel(t.dark)}</td>
      </tr>`;
      })
      .join("\n");
    sections.push(`  <h3>${esc(label)}</h3>
  <div class="doc-table-wrap"><table class="table table-compact">
    <thead><tr><th>Token</th><th>Swatch</th><th>Light ref</th><th>Dark ref</th></tr></thead>
    <tbody>
${rows}
    </tbody>
  </table></div>`);
  }
  return sections.join("\n");
}

function axisCard(title, renderedHtml, code) {
  return exampleCard(title, renderedHtml, [{ label: "Set it from JS", code }]);
}

function overviewPage(components, sys) {
  const axisSamples = `<div class="d-flex flex-wrap" style="gap: 8px; align-items: center;">
  <button class="btn btn-primary">Create</button>
  <button class="btn">Cancel</button>
  <a href="#">A link</a>
  <span class="lozenge lozenge-inprogress">In progress</span>
  <span class="lozenge lozenge-success lozenge-bold">Done</span>
  <span class="badge badge-primary">99+</span>
</div>`;

  const schemeExample = `<div class="d-flex flex-wrap" style="gap: 16px;">
  <div class="doc-axis-pane">
    <p class="text-subtlest">Page scheme</p>
    <button class="btn btn-primary">Create</button>
    <span class="lozenge lozenge-inprogress">In progress</span>
  </div>
  <div class="doc-axis-pane" data-theme="dark">
    <p class="text-subtlest">Forced dark subtree (<code>data-theme="dark"</code>)</p>
    <button class="btn btn-primary">Create</button>
    <span class="lozenge lozenge-inprogress">In progress</span>
  </div>
</div>`;

  const glassExample = `<div class="flag" role="status">
  <div class="flag-content">
    <div class="flag-title">Changes saved</div>
    <div class="flag-description">Flags, menus, modals and the navbar are frosted-glass surfaces; the glass alpha is a function of the contrast dial.</div>
  </div>
  <button class="flag-dismiss" aria-label="Dismiss">×</button>
</div>`;

  const content = `<h1>Lozenge</h1>
<p class="text-subtle">A Jira-flavoured design system with runtime theme axes — original CSS
built on the published Atlassian palette anchors, with Bootstrap-style class ergonomics.
Components are plain HTML + CSS with zero runtime JavaScript; behavior comes from the
platform (native <code>&lt;dialog&gt;</code>, <code>popover</code>, <code>&lt;details&gt;</code>, radios + <code>:has()</code>).
Every component publishes an agent-readable markup contract in <code>specs/</code>, and these
pages are generated from those contracts.</p>

<section>
<h2>The four theme axes</h2>
<p class="text-subtle">Everything routes through four numeric custom properties plus
<code>data-theme</code> — no rebuild, animatable, drivable from a slider or your own logic.
This page loads the theme panel (bottom right): every example below re-resolves live as
you drag the dials.</p>

<h3>Scheme</h3>
<p>Light on <code>:root</code>, dark under <code>[data-theme="dark"]</code> (with a
<code>prefers-color-scheme</code> fallback). The attribute also works on a subtree:</p>
${axisCard("data-theme", schemeExample, `document.documentElement.dataset.theme = "dark";`)}

<h3>Contrast</h3>
<p><code>--lz-contrast</code> is a continuous dial from −1 to +1, resolved through OKLCH
relative color at runtime. OS <code>prefers-contrast</code> maps onto it — including
<em>reduced</em> contrast for photophobic users — and every declared text/surface pair is
CI-verified against WCAG 2.2 ratios at every dial position. Drag the contrast slider in
the theme panel and watch this sample:</p>
${axisCard("--lz-contrast", axisSamples, `document.documentElement.style.setProperty("--lz-contrast", 0.5);`)}

<h3>Accent</h3>
<p><code>--lz-accent-hue</code> / <code>--lz-accent-chroma</code> rotate the entire accent
ramp live; Jira blue is just the dial's resting position. Buttons, links, selection,
focus rings and info status all follow:</p>
${axisCard("--lz-accent-hue / --lz-accent-chroma", axisSamples, `document.documentElement.style.setProperty("--lz-accent-hue", 152); // green`)}

<h3>Glass</h3>
<p><code>--lz-glass</code> fades overlay materials between frosted glass (1) and solid (0).
Glass also fades to solid as contrast rises, and is disabled under
<code>prefers-reduced-transparency</code> and forced-colors — solid is the canonical state:</p>
${axisCard("--lz-glass", glassExample, `document.documentElement.style.setProperty("--lz-glass", 0); // solid materials`)}
</section>

<section>
<h2>Token tiers</h2>
<p>Three tiers, generated from <code>tokens/ramps.json</code> + <code>tokens/sys.json</code>
by <code>scripts/build-tokens.mjs</code>:</p>
<ul>
  <li><strong>Reference</strong> — <code>--lz-ref-&lt;ramp&gt;-&lt;step&gt;</code>: OKLCH ramps fitted to the
  Atlassian hex anchors, plus a parametric accent ramp whose hue/chroma come from the dials.</li>
  <li><strong>System</strong> — <code>--lz-sys-*</code>: semantic roles expressed as relative-color
  functions of the reference tier and the contrast dial. The same <code>sys.json</code> is evaluated
  numerically by the contrast checker, so the CSS and the CI proof cannot drift.</li>
  <li><strong>Component</strong> — Sass-level tokens consumed by the ~20 components, overridable
  Bootstrap-style at compile time.</li>
</ul>
</section>

<section>
<h2>System tokens</h2>
<p class="text-subtle">Every semantic token from <code>tokens/sys.json</code>. Swatches are
live — they follow the scheme, contrast and accent dials on this page. <em>k</em> is the
lightness shift per unit of contrast, <em>ck</em> the chroma multiplier, <em>α</em> a static
opacity.</p>
${sysTokenTables(sys)}
</section>`;

  return pageShell({ title: "Overview", activeSlug: "index", components, content });
}

// ------------------------------------------------- material cheat sheet

function materialMapPage(components) {
  const map = JSON.parse(
    readFileSync(join(root, "tokens", "material-map.json"), "utf8")
  );
  const sections = map.sections
    .map((sec) => {
      const rows = sec.rows
        .map((r) => {
          const docsLink = r.docs
            ? `<a href="${esc(r.docs)}">${esc(r.docs.replace(".html", ""))}</a>`
            : '<span class="text-subtlest">—</span>';
          const note = r.note
            ? `<div class="text-subtlest" style="font-size:12px">${esc(r.note)}</div>`
            : "";
          return `<tr>
  <td>${esc(r.material)}</td>
  <td class="text-subtle">${esc(r.flutter)}</td>
  <td><code>${esc(r.lozenge)}</code>${note}</td>
  <td>${docsLink}</td>
</tr>`;
        })
        .join("\n");
      return `<section>
<h2>${esc(sec.title)}</h2>
<div class="doc-table-wrap"><table class="table">
<thead><tr><th>Material</th><th>Flutter widget</th><th>Lozenge</th><th>Docs</th></tr></thead>
<tbody>
${rows}
</tbody>
</table></div>
</section>`;
    })
    .join("\n\n");

  const content = `<h1>Material → Lozenge cheat sheet</h1>
<p class="text-subtle">Every component in Google's Material / Flutter widget catalog,
mapped to its Lozenge equivalent. Also available to agents as a section of
<a href="/llms.txt">llms.txt</a>; source of truth is
<code>tokens/material-map.json</code>.</p>

${sections}`;

  return pageShell({
    title: "Material → Lozenge",
    activeSlug: "material",
    components,
    content,
  });
}

// ------------------------------------------------------------------ main

const specFiles = readdirSync(specsDir).filter((f) => f.endsWith(".json")).sort();
const specs = specFiles.map((f) =>
  JSON.parse(readFileSync(join(specsDir, f), "utf8"))
);
const components = specs.map((s) => s.component);
const sys = JSON.parse(readFileSync(join(root, "tokens", "sys.json"), "utf8"));

mkdirSync(outDir, { recursive: true });

writeFileSync(join(outDir, "index.html"), overviewPage(components, sys));
writeFileSync(join(outDir, "material.html"), materialMapPage(components));
for (const spec of specs) {
  writeFileSync(join(outDir, `${spec.component}.html`), componentPage(spec, components));
}

console.log(`build-docs: wrote ${specs.length + 2} pages to docs/`);
