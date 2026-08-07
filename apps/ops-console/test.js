const assert = require("node:assert/strict");
const test = require("node:test");
const { configScript, createServer } = require("./server");

test("runtime config contains the injected API base", () => {
  assert.match(configScript("http://parser:8080"), /http:\/\/parser:8080/);
});

test("server exposes runtime config and health", async (context) => {
  const server = createServer({ apiBase: "http://gateway:4561" });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  context.after(() => server.close());
  const { port } = server.address();
  const config = await fetch(`http://127.0.0.1:${port}/config.js`);
  const health = await fetch(`http://127.0.0.1:${port}/healthz`);
  assert.equal(config.status, 200);
  assert.match(await config.text(), /http:\/\/gateway:4561/);
  assert.deepEqual(await health.json(), { status: "ok" });
});