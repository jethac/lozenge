// Floating theme-axis control panel. Everything routes through four numeric
// custom properties + data-theme — no rebuild, no framework, animatable.
const root = document.documentElement;
const KEY = "lz-theme";

const state = Object.assign(
  { scheme: "auto", contrast: 0, hue: 260.48, chroma: 1, glass: 1 },
  JSON.parse(localStorage.getItem(KEY) ?? "{}")
);

function apply() {
  if (state.scheme === "auto") root.removeAttribute("data-theme");
  else root.setAttribute("data-theme", state.scheme);
  root.style.setProperty("--lz-contrast", state.contrast);
  root.style.setProperty("--lz-accent-hue", state.hue);
  root.style.setProperty("--lz-accent-chroma", state.chroma);
  root.style.setProperty("--lz-glass", state.glass);
  localStorage.setItem(KEY, JSON.stringify(state));
}

const panel = document.createElement("div");
panel.className = "card shadow-overlay";
panel.style.cssText =
  "position:fixed;bottom:16px;right:16px;z-index:900;width:260px;";
panel.innerHTML = `
  <div class="card-header d-flex justify-content-between align-items-center">
    <span>Theme axes</span>
    <button class="btn btn-subtle btn-compact" data-act="collapse" aria-label="Collapse">–</button>
  </div>
  <div class="card-body" data-body>
    <div class="form-group">
      <label class="form-label" for="lzp-scheme">Scheme</label>
      <select class="form-select form-control-compact" id="lzp-scheme">
        <option value="auto">Auto (system)</option>
        <option value="light">Light</option>
        <option value="dark">Dark</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label" for="lzp-contrast">Contrast <span data-val="contrast" class="text-subtlest"></span></label>
      <input type="range" id="lzp-contrast" min="-1" max="1" step="0.05" style="width:100%">
    </div>
    <div class="form-group">
      <label class="form-label" for="lzp-hue">Accent hue <span data-val="hue" class="text-subtlest"></span></label>
      <input type="range" id="lzp-hue" min="0" max="360" step="1" style="width:100%">
    </div>
    <div class="form-group">
      <label class="form-label" for="lzp-chroma">Accent chroma <span data-val="chroma" class="text-subtlest"></span></label>
      <input type="range" id="lzp-chroma" min="0" max="1.4" step="0.05" style="width:100%">
    </div>
    <div class="form-group d-flex align-items-center gap-2">
      <label class="toggle"><input type="checkbox" id="lzp-glass"><span class="toggle-slider"></span></label>
      <label for="lzp-glass">Glass materials</label>
    </div>
    <div class="form-group d-flex justify-content-end">
      <button class="btn btn-compact" data-act="reset">Reset</button>
    </div>
  </div>`;
document.body.appendChild(panel);

const $ = (sel) => panel.querySelector(sel);
function sync() {
  $("#lzp-scheme").value = state.scheme;
  $("#lzp-contrast").value = state.contrast;
  $("#lzp-hue").value = state.hue;
  $("#lzp-chroma").value = state.chroma;
  $("#lzp-glass").checked = state.glass > 0;
  $('[data-val="contrast"]').textContent = Number(state.contrast).toFixed(2);
  $('[data-val="hue"]').textContent = `${Math.round(state.hue)}°`;
  $('[data-val="chroma"]').textContent = `×${Number(state.chroma).toFixed(2)}`;
}

$("#lzp-scheme").addEventListener("input", (e) => {
  state.scheme = e.target.value;
  apply();
});
for (const [id, key] of [
  ["#lzp-contrast", "contrast"],
  ["#lzp-hue", "hue"],
  ["#lzp-chroma", "chroma"],
]) {
  $(id).addEventListener("input", (e) => {
    state[key] = Number(e.target.value);
    sync();
    apply();
  });
}
$("#lzp-glass").addEventListener("input", (e) => {
  state.glass = e.target.checked ? 1 : 0;
  apply();
});
$('[data-act="reset"]').addEventListener("click", () => {
  Object.assign(state, {
    scheme: "auto",
    contrast: 0,
    hue: 260.48,
    chroma: 1,
    glass: 1,
  });
  sync();
  apply();
});
$('[data-act="collapse"]').addEventListener("click", (e) => {
  const body = $("[data-body]");
  const hidden = body.style.display === "none";
  body.style.display = hidden ? "" : "none";
  e.target.textContent = hidden ? "–" : "+";
});

sync();
apply();
