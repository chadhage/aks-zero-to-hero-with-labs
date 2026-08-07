const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");

const types = { ".css": "text/css", ".html": "text/html", ".js": "text/javascript" };

function configScript(apiBase) {
  return `window.SKYBRIDGE_CONFIG = ${JSON.stringify({ apiBase })};\n`;
}

function createServer({ root = path.join(__dirname, "src"), apiBase = "http://localhost:8080" } = {}) {
  return http.createServer((request, response) => {
    if (request.url === "/healthz") {
      response.writeHead(200, { "Content-Type": "application/json" });
      response.end('{"status":"ok"}\n');
      return;
    }
    if (request.url === "/config.js") {
      response.writeHead(200, { "Content-Type": "text/javascript", "Cache-Control": "no-store" });
      response.end(configScript(apiBase));
      return;
    }
    const requested = request.url === "/" ? "index.html" : request.url.slice(1);
    const file = path.resolve(root, requested);
    if (!file.startsWith(path.resolve(root) + path.sep)) {
      response.writeHead(400).end();
      return;
    }
    fs.readFile(file, (error, data) => {
      if (error) {
        response.writeHead(404).end("Not found\n");
        return;
      }
      response.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
      response.end(data);
    });
  });
}

if (require.main === module) {
  const port = Number(process.env.CONSOLE_PORT || 3000);
  const server = createServer({ apiBase: process.env.API_BASE || "http://localhost:8080" });
  server.listen(port, "0.0.0.0", () => console.log(`component=ops-console event=started port=${port}`));
}

module.exports = { configScript, createServer };