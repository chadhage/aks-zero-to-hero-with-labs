# Operations console stub

A dependency-free static console for the Skybridge workshop. `run.sh` starts a
local Node server on `CONSOLE_PORT` (default `3000`). The container serves on
port `8080`. Both modes expose `/healthz` and generate `/config.js` from the
runtime `API_BASE` value.
