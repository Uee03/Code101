const fs = require("node:fs");
const pkg = require("./package.json");

fs.mkdirSync("dist", { recursive: true });
const source = fs.readFileSync("src/server.js", "utf8");
fs.writeFileSync("dist/server.js", source.replace("__VERSION__", pkg.version));
console.log("built dist/server.js for version " + pkg.version);
