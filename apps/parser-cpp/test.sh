#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
command -v cmake >/dev/null 2>&1 || { printf 'cmake is required\n' >&2; exit 1; }
cmake -S . -B build -DBUILD_TESTING=OFF
cmake --build build
test -x build/skybridge-parser
printf '[PASS] parser-cpp compiled\n'