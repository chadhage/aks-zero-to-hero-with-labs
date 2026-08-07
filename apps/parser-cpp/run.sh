#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
[[ -x build/skybridge-parser ]] || ./test.sh
exec ./build/skybridge-parser