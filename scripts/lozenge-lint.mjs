#!/usr/bin/env node
// lozenge-lint — validates HTML markup against the Lozenge component
// contracts in specs/*.json.
//
// Usage:
//   node scripts/lozenge-lint.mjs <html-files-or-globs...> [--specs specs] [--json]
//
// For every element whose class list contains a spec's root required
// class(es), checks:
//   - root element tag is one of root.element
//   - exclusive variant axes: no two classes from the same exclusive axis
//   - required variant axes: at least one class from the axis is present
//   - required structure selectors exist within the subtree
//   - required aria attributes are present (rules with a "when" condition
//     are documentation-only and skipped)
//   - nesting.disallowed: simple-selector entries (no whitespace, or a
//     plain child/descendant chain) must match neither a descendant nor
//     an ancestor of the root; prose entries are skipped
// Exits 1 if any errors were found. --json emits structured findings.

import fs from "node:fs";
import path from "node:path";
import { parse } from "parse5";

// ---------------------------------------------------------------- CLI args

const argv = process.argv.slice(2);
const patterns = [];
let specsDir = "specs";
let asJson = false;

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === "--specs") specsDir = argv[++i];
  else if (a === "--json") asJson = true;
  else if (a === "--help" || a === "-h") {
    console.log("Usage: node scripts/lozenge-lint.mjs <html-files-or-globs...> [--specs specs] [--json]");
    process.exit(0);
  } else patterns.push(a);
}

if (patterns.length === 0) {
  console.error("lozenge-lint: no input files. Usage: node scripts/lozenge-lint.mjs <html-files-or-globs...> [--specs specs] [--json]");
  process.exit(2);
}

const files = [...new Set(patterns.flatMap((p) =>
  /[*?[\]{]/.test(p) ? fs.globSync(p) : [p]
))].sort();

if (files.length === 0) {
  console.error(`lozenge-lint: no files matched: ${patterns.join(" ")}`);
  process.exit(2);
}

// ---------------------------------------------------------------- specs

/** Flatten spec files (each may carry subcomponents) into component blocks. */
function loadSpecs(dir) {
  let entries;
  try {
    entries = fs.readdirSync(dir).filter((f) => f.endsWith(".json")).sort();
  } catch {
    console.error(`lozenge-lint: cannot read specs directory: ${dir}`);
    process.exit(2);
  }
  const blocks = [];
  for (const f of entries) {
    const spec = JSON.parse(fs.readFileSync(path.join(dir, f), "utf8"));
    blocks.push(spec);
    for (const sub of spec.subcomponents ?? []) blocks.push(sub);
  }
  return blocks.filter((b) => b.root?.requiredClasses?.length);
}

const specs = loadSpecs(specsDir);

// ------------------------------------------------------- simple selectors

// Grammar: chain of compounds joined by ">" (child) or whitespace
// (descendant). Compound: [tag][.class...][[attr]|[attr=value]...]
const COMPOUND_RE = /^([a-zA-Z][a-zA-Z0-9-]*)?((?:\.[a-zA-Z0-9_-]+)*)((?:\[[a-zA-Z-]+(?:="?[^\]"]*"?)?\])*)$/;

function parseCompound(src) {
  const m = COMPOUND_RE.exec(src);
  if (!m || (!m[1] && !m[2] && !m[3])) return null;
  const classes = m[2] ? m[2].split(".").filter(Boolean) : [];
  const attrs = [];
  if (m[3]) {
    for (const am of m[3].matchAll(/\[([a-zA-Z-]+)(?:="?([^\]"]*)"?)?\]/g)) {
      attrs.push({ name: am[1].toLowerCase(), value: am[2] });
    }
  }
  return { tag: m[1]?.toLowerCase() ?? null, classes, attrs };
}

/** Parse "a > b c" into [{compound, combinator-to-previous}]. Null if unsupported. */
function parseSelector(src) {
  const parts = [];
  const flat = src.trim().replace(/\s*>\s*/g, " > ").split(/\s+/);
  let combinator = null;
  for (const tok of flat) {
    if (tok === ">") { combinator = "child"; continue; }
    const compound = parseCompound(tok);
    if (!compound) return null;
    parts.push({ compound, combinator: parts.length === 0 ? null : (combinator ?? "descendant") });
    combinator = null;
  }
  return parts.length ? parts : null;
}

// ------------------------------------------------------------- DOM helpers

function isElement(node) {
  return node.tagName !== undefined && node.attrs !== undefined;
}

function getAttr(el, name) {
  const a = el.attrs.find((x) => x.name === name);
  return a ? a.value : undefined;
}

function classList(el) {
  const c = getAttr(el, "class");
  return c ? c.split(/\s+/).filter(Boolean) : [];
}

function matchCompound(el, c) {
  if (!isElement(el)) return false;
  if (c.tag && el.tagName !== c.tag) return false;
  if (c.classes.length) {
    const cls = classList(el);
    for (const k of c.classes) if (!cls.includes(k)) return false;
  }
  for (const a of c.attrs) {
    const v = getAttr(el, a.name);
    if (v === undefined) return false;
    if (a.value !== undefined && v !== a.value) return false;
  }
  return true;
}

/** Does `el` match the full chain, with ancestor checks bounded at `boundary` (inclusive)? */
function matchChain(el, parts, boundary) {
  if (!matchCompound(el, parts[parts.length - 1].compound)) return false;
  let node = el;
  for (let i = parts.length - 2; i >= 0; i--) {
    const need = parts[i].compound;
    const rel = parts[i + 1].combinator; // relation between parts[i] and parts[i+1]
    if (rel === "child") {
      node = node.parentNode;
      if (!node || !isElement(node) || !matchCompound(node, need)) return false;
      if (boundary && node !== boundary && !isAncestorOrSelf(boundary, node)) return false;
    } else {
      let cur = node.parentNode;
      let found = null;
      while (cur && isElement(cur)) {
        if (matchCompound(cur, need)) { found = cur; break; }
        if (cur === boundary) break;
        cur = cur.parentNode;
      }
      if (!found) return false;
      if (boundary && found !== boundary && !isAncestorOrSelf(boundary, found)) return false;
      node = found;
    }
  }
  return true;
}

function isAncestorOrSelf(anc, node) {
  let cur = node;
  while (cur) {
    if (cur === anc) return true;
    cur = cur.parentNode;
  }
  return false;
}

function* walk(node) {
  if (isElement(node)) yield node;
  for (const child of node.childNodes ?? []) yield* walk(child);
}

function* descendants(el) {
  for (const child of el.childNodes ?? []) yield* walk(child);
}

/** Find elements within root's subtree (root excluded unless includeSelf) matching selector. */
function queryAll(root, parts, { includeSelf = false } = {}) {
  const out = [];
  if (includeSelf && matchChain(root, parts, null)) out.push(root);
  for (const el of descendants(root)) {
    if (matchChain(el, parts, root)) out.push(el);
  }
  return out;
}

// A nesting.disallowed entry is machine-checkable when it parses as a
// selector chain in which every compound has at least one class or attr
// (a bare-word "tag" would swallow prose like "another .lozenge").
function nestingSelector(entry) {
  const parts = parseSelector(entry);
  if (!parts) return null;
  // Reject chains containing a compound that is a bare tag with no
  // class/attr — that pattern is how prose ("another .lozenge") parses.
  for (const p of parts) {
    if (p.compound.tag && p.compound.classes.length === 0 && p.compound.attrs.length === 0) return null;
  }
  return parts;
}

// ---------------------------------------------------------------- linting

const findings = [];

function report(file, node, component, rule, message) {
  const line = node?.sourceCodeLocation?.startLine ?? 0;
  findings.push({ file, line, component, rule, message });
}

function lintElement(file, el, spec) {
  const name = spec.component;
  const cls = classList(el);
  const root = spec.root;

  // Root element tag.
  if (Array.isArray(root.element) && root.element.length && !root.element.includes(el.tagName)) {
    report(file, el, name, "root-element",
      `<${el.tagName}> is not an allowed element for ${root.selector} (allowed: ${root.element.join(", ")})`);
  }

  // Variant axes.
  for (const [axis, def] of Object.entries(spec.variants ?? {})) {
    const present = def.classes.filter((c) => cls.includes(c));
    if (def.exclusive && present.length > 1) {
      report(file, el, name, "variant-exclusive",
        `classes ${present.join(" + ")} are mutually exclusive on the "${axis}" axis`);
    }
    if (def.required && present.length === 0) {
      report(file, el, name, "variant-required",
        `missing required "${axis}" variant (one of: ${def.classes.join(", ")})`);
    }
  }

  // Required structure.
  for (const entry of spec.structure ?? []) {
    if (!entry.required) continue;
    const parts = parseSelector(entry.selector);
    if (!parts) continue; // unsupported selector — documentation only
    if (queryAll(el, parts).length === 0) {
      report(file, el, name, "structure-missing",
        `required descendant "${entry.selector}" not found`);
    }
  }

  // Required aria attributes (unconditional rules only).
  for (const rule of spec.aria ?? []) {
    if (!rule.required || rule.when) continue;
    const parts = parseSelector(rule.on);
    if (!parts) continue;
    for (const target of queryAll(el, parts, { includeSelf: true })) {
      if (getAttr(target, rule.attr) === undefined) {
        report(file, target, name, "aria-missing",
          `element matching "${rule.on}" is missing required attribute ${rule.attr}`);
      }
    }
  }

  // Disallowed nesting (both directions: descendant and ancestor).
  for (const entry of spec.nesting?.disallowed ?? []) {
    const parts = nestingSelector(entry);
    if (!parts) continue; // prose entry — documentation only
    const hit = queryAll(el, parts)[0];
    if (hit) {
      report(file, hit, name, "nesting-disallowed",
        `"${entry}" must not appear inside ${root.selector}`);
    }
    if (parts.length === 1) {
      let cur = el.parentNode;
      while (cur && isElement(cur)) {
        if (matchCompound(cur, parts[0].compound)) {
          report(file, el, name, "nesting-disallowed",
            `${root.selector} must not appear inside "${entry}"`);
          break;
        }
        cur = cur.parentNode;
      }
    }
  }
}

for (const file of files) {
  let html;
  try {
    html = fs.readFileSync(file, "utf8");
  } catch {
    findings.push({ file, line: 0, component: "-", rule: "io-error", message: "cannot read file" });
    continue;
  }
  const doc = parse(html, { sourceCodeLocationInfo: true });
  for (const el of walk(doc)) {
    const cls = classList(el);
    if (cls.length === 0) continue;
    for (const spec of specs) {
      if (spec.root.requiredClasses.every((c) => cls.includes(c))) {
        lintElement(file, el, spec);
      }
    }
  }
}

// ---------------------------------------------------------------- output

findings.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);

if (asJson) {
  console.log(JSON.stringify({ errors: findings.length, findings }, null, 2));
} else {
  for (const f of findings) {
    console.log(`${f.file}:${f.line} ${f.component} ${f.rule} ${f.message}`);
  }
  if (findings.length) {
    console.error(`\n${findings.length} problem${findings.length === 1 ? "" : "s"} found.`);
  } else {
    console.log(`OK — ${files.length} file${files.length === 1 ? "" : "s"}, ${specs.length} component contracts, no problems.`);
  }
}

process.exit(findings.length ? 1 : 0);
