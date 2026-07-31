#!/usr/bin/env node
// CLI for the Lozenge expander.
//   node scripts/lz-expand.mjs page.html            → expanded HTML to stdout
//   node scripts/lz-expand.mjs --write a.html b.html → expand in place
//   node scripts/lz-expand.mjs --react page.html     → JSX-friendly output
//   node scripts/lz-expand.mjs --check *.html        → exit 1 if any file
//     carries data-lz-version stamps older than the installed templates
import { readFileSync, writeFileSync } from "node:fs";
import { expandLozenge, VERSION } from "./expand.mjs";

const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith("--")));
const files = args.filter((a) => !a.startsWith("--"));

if (!files.length) {
  console.error("usage: lz-expand [--write|--check|--react] <files...>");
  process.exit(2);
}

let stale = 0;
for (const file of files) {
  const src = readFileSync(file, "utf8");
  if (flags.has("--check")) {
    for (const m of src.matchAll(/data-lz-version="([^"]+)"/g)) {
      if (m[1] !== VERSION) {
        console.error(`${file}: expanded with ${m[1]}, installed ${VERSION}`);
        stale++;
      }
    }
    continue;
  }
  let out = expandLozenge(src);
  if (flags.has("--react")) {
    out = out.replace(/\bclass=/g, "className=").replace(/\bfor=/g, "htmlFor=");
  }
  if (flags.has("--write")) writeFileSync(file, out);
  else process.stdout.write(out);
}
if (stale) process.exit(1);
