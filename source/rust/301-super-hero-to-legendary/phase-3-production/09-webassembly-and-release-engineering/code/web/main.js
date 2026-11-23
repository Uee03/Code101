import init, { slugify, version } from "./pkg/slug_wasm.js";

await init();

const input = document.getElementById("title");
const output = document.getElementById("slug");
document.getElementById("version").textContent = version();

function update() {
  output.textContent = slugify(input.value);
}

input.addEventListener("input", update);
update();
