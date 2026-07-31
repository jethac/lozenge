import { globSync } from "node:fs";
import { resolve } from "node:path";
import { defineConfig } from "vite";
import { expandLozenge } from "./scripts/expand.mjs";

export default defineConfig({
  plugins: [
    {
      name: "lozenge-expand",
      transformIndexHtml: {
        order: "pre",
        handler: (html) => expandLozenge(html),
      },
    },
  ],
  server: {
    port: 5173,
    open: "/demo/",
  },
  build: {
    outDir: "site",
    rollupOptions: {
      input: [
        "index.html",
        "demo/index.html",
        "demo/tags.html",
        ...globSync("docs/*.html", { cwd: import.meta.dirname }).sort(),
      ].map((p) => resolve(import.meta.dirname, p)),
    },
  },
});
