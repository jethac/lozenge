/* Lozenge sprinkle — the system's entire optional JavaScript (~1KB).
 * Adds roving arrow-key focus + typeahead to open popover menus
 * ([popover].dropdown-menu). Everything else in Lozenge is zero-JS; without
 * this file menus still work (Tab/Shift-Tab). Idempotent: safe to load
 * twice, late, or not at all. */
(() => {
  if (window.__lzSprinkle) return;
  window.__lzSprinkle = true;

  const ITEMS = ".dropdown-item:not(.disabled):not([disabled])";

  document.addEventListener("keydown", (e) => {
    const menu = e.target.closest?.("[popover].dropdown-menu:popover-open")
      ?? document.querySelector("[popover].dropdown-menu:popover-open");
    if (!menu) return;
    const items = [...menu.querySelectorAll(ITEMS)].filter(
      (i) => i.closest("[popover]") === menu
    );
    if (!items.length) return;
    const idx = items.indexOf(document.activeElement);

    const focus = (i) => {
      items[(i + items.length) % items.length].focus();
      e.preventDefault();
    };

    if (e.key === "ArrowDown") focus(idx + 1);
    else if (e.key === "ArrowUp") focus(idx < 0 ? -1 : idx - 1);
    else if (e.key === "Home") focus(0);
    else if (e.key === "End") focus(items.length - 1);
    else if (e.key.length === 1 && /\S/.test(e.key) && !e.metaKey && !e.ctrlKey) {
      const q = e.key.toLowerCase();
      const from = idx + 1;
      for (let n = 0; n < items.length; n++) {
        const item = items[(from + n) % items.length];
        if (item.textContent.trim().toLowerCase().startsWith(q)) {
          item.focus();
          break;
        }
      }
    }
  });
})();
