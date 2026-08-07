#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
command -v javac >/dev/null 2>&1 || { printf 'javac is required\n' >&2; exit 1; }
rm -rf build
mkdir -p build/classes
javac --release 21 -d build/classes src/SkybridgeGateway.java
jar --create --file build/gateway-java.jar --main-class SkybridgeGateway -C build/classes .
jar --list --file build/gateway-java.jar | grep -q 'SkybridgeGateway.class'
printf '[PASS] gateway-java compiled and packaged\n'