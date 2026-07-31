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
      input: {
        main: resolve(import.meta.dirname, "index.html"),
        demo: resolve(import.meta.dirname, "demo/index.html"),
        tags: resolve(import.meta.dirname, "demo/tags.html"),
      },
    },
  },
});
