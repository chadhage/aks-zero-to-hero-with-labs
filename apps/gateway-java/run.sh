#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
[[ -f build/gateway-java.jar ]] || ./test.sh
exec java -jar build/gateway-java.jar