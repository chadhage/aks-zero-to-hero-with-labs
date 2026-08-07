# Parser C++ stub

A small C++17 HTTP parser for the Skybridge workshop. It exposes `GET /healthz`,
`GET /ready`, and `POST /parse` on `PARSER_PORT` (default `8080`). The parse
endpoint validates the workshop's slash-delimited `QU/...` payload and returns a
short summary for the gateway acknowledgment.
