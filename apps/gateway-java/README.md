# Gateway Java stub

A dependency-free Java 21 TCP gateway for the Skybridge workshop. It listens on
`GATEWAY_PORT`, accepts `MSG <payload>`, forwards the payload to
`POST $PARSER_URL/parse`, and returns `ACK` when the parser succeeds.

Configuration: `GATEWAY_PORT`, `PARSER_URL`, `GATEWAY_PARSER_TIMEOUT_MS`, and
`IMAGE_REVISION`.
