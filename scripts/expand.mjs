// Lozenge compile-time component expander.
// Expands <lz-*> custom tags into canonical Lozenge HTML using the template
// files in templates/. The shipped artifact is inert HTML+CSS — no runtime.
//
// Template language (deliberately tiny):
//   {attr}              → substituted from the tag's attribute (or default)
//   {attr?class-token}  → class-token emitted only when attr is present/truthy
//   data-lz-defaults='{"a":"b"}' on the template root → attribute defaults
//   data-lz-if="attr" on any template element → element dropped if attr absent
//   <slot></slot> / <slot name="x"></slot> → children distribution
//   class tokens that resolve to "" or a trailing "-" are stripped
// Unknown attributes on the custom tag pass through to the template root
// (class merges). The root is stamped with data-lz + data-lz-version.

import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, basename } from "node:path";
import { parse, parseFragment, serialize } from "parse5";

const here = dirname(fileURLToPath(import.meta.url));
const DEFAULT_TEMPLATES = join(here, "..", "templates");
const VERSION = JSON.parse(
  readFileSync(join(here, "..", "package.json"), "utf8")
).version;

export function loadTemplates(dir = DEFAULT_TEMPLATES) {
  const templates = {};
  for (const f of readdirSync(dir)) {
    if (f.endsWith(".html"))
      templates[basename(f, ".html")] = readFileSync(join(dir, f), "utf8");
  }
  return templates;
}

const isElement = (n) => !!n.tagName;
const attrMap = (el) =>
  Object.fromEntries((el.attrs ?? []).map((a) => [a.name, a.value]));

function walkReplace(node, fn) {
  if (!node.childNodes) return;
  for (const child of node.childNodes) walkReplace(child, fn);
  const next = [];
  for (const child of node.childNodes) {
    const replacement = fn(child);
    if (replacement === null) continue;
    if (Array.isArray(replacement)) {
      for (const r of replacement) {
        r.parentNode = node;
        next.push(r);
      }
    } else {
      next.push(child);
    }
  }
  node.childNodes = next;
}

function substituteText(text, attrs, defaults, used) {
  return text
    .replace(/\{(\w[\w-]*)\?([^}]*)\}/g, (_, name, token) => {
      used.add(name);
      const v = attrs[name] ?? defaults[name];
      // bare boolean attributes parse as "" — presence counts, "false" doesn't
      return v !== undefined && v !== "false" ? token : "";
    })
    .replace(/\{(\w[\w-]*)\}/g, (_, name) => {
      used.add(name);
      return attrs[name] ?? defaults[name] ?? "";
    });
}

const cleanClass = (v) =>
  v
    .split(/\s+/)
    .filter((t) => t && !t.endsWith("-"))
    .join(" ");

function substituteTree(node, attrs, defaults, used) {
  if (node.attrs) {
    for (const a of node.attrs) {
      a.value = substituteText(a.value, attrs, defaults, used);
      if (a.name === "class") a.value = cleanClass(a.value);
    }
    node.attrs = node.attrs.filter(
      (a) => !(a.value === "" && (a.name === "class" || a.name === "id"))
    );
  }
  if (node.nodeName === "#text")
    node.value = substituteText(node.value, attrs, defaults, used);
  for (const c of node.childNodes ?? []) substituteTree(c, attrs, defaults, used);
}

function applyConditionals(node, attrs) {
  if (!node.childNodes) return;
  node.childNodes = node.childNodes.filter((c) => {
    if (!isElement(c)) return true;
    const cond = (c.attrs ?? []).find((a) => a.name === "data-lz-if");
    if (!cond) return true;
    c.attrs = c.attrs.filter((a) => a.name !== "data-lz-if");
    const v = attrs[cond.value];
    return v !== undefined && v !== "false";
  });
  for (const c of node.childNodes) applyConditionals(c, attrs);
}

function distributeSlots(fragRoot, hostChildren) {
  const named = {};
  const defaultKids = [];
  for (const child of hostChildren) {
    const slotName = isElement(child)
      ? (child.attrs ?? []).find((a) => a.name === "slot")?.value
      : undefined;
    if (slotName) {
      child.attrs = child.attrs.filter((a) => a.name !== "slot");
      (named[slotName] ??= []).push(child);
    } else {
      defaultKids.push(child);
    }
  }
  walkReplace(fragRoot, (n) => {
    if (isElement(n) && n.tagName === "slot") {
      const name = attrMap(n).name;
      const content = name ? (named[name] ?? []) : defaultKids;
      // fall back to slot's own children when host provided nothing
      return content.length ? content : (n.childNodes ?? []);
    }
    return undefined;
  });
}

function expandCustom(el, templates) {
  const name = el.tagName.slice(3);
  const tplSource = templates[name];
  if (!tplSource) return undefined; // unknown tag: leave untouched
  const frag = parseFragment(tplSource.trim());
  const root = frag.childNodes.find(isElement);
  if (!root) return undefined;

  const defaults = (() => {
    const d = (root.attrs ?? []).find((a) => a.name === "data-lz-defaults");
    if (!d) return {};
    root.attrs = root.attrs.filter((a) => a.name !== "data-lz-defaults");
    return JSON.parse(d.value);
  })();

  const attrs = attrMap(el);
  const used = new Set();
  substituteTree(frag, attrs, defaults, used);
  applyConditionals(frag, attrs);
  distributeSlots(frag, el.childNodes ?? []);

  // pass through unconsumed attributes to the root; `slot` must survive so
  // an enclosing lz-* parent (expanded later, bottom-up) can still route it
  for (const a of el.attrs ?? []) {
    if (used.has(a.name)) continue;
    if (a.name === "class") {
      const existing = root.attrs.find((x) => x.name === "class");
      if (existing) existing.value = cleanClass(`${existing.value} ${a.value}`);
      else root.attrs.push({ name: "class", value: a.value });
    } else if (!root.attrs.some((x) => x.name === a.name)) {
      root.attrs.push({ name: a.name, value: a.value });
    }
  }
  root.attrs.push({ name: "data-lz", value: name });
  root.attrs.push({ name: "data-lz-version", value: VERSION });
  return frag.childNodes.filter((n) => isElement(n) || n.nodeName === "#text");
}

export function expandLozenge(html, opts = {}) {
  const templates = opts.templates ?? loadTemplates(opts.templatesDir);
  const isDocument = /<!doctype|<html[\s>]/i.test(html);
  const tree = isDocument ? parse(html) : parseFragment(html);
  walkReplace(tree, (child) =>
    isElement(child) && child.tagName.startsWith("lz-")
      ? (expandCustom(child, templates) ?? undefined)
      : undefined
  );
  return serialize(isDocument ? tree : tree);
}

export { VERSION };
