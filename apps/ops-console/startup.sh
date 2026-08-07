#!/bin/sh

set -eu

: "${API_BASE:=http://localhost:8080}"
escaped_api_base=$(printf '%s' "$API_BASE" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '%s\n' "window.SKYBRIDGE_CONFIG = {\"apiBase\":\"${escaped_api_base}\"};" > /tmp/config.js
exec nginx -g 'daemon off;'