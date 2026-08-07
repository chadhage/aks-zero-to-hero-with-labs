#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/failure.sh"

[[ $# -eq 0 ]] || fail "Usage: $0"
require_context aks-z2h
reset_failure gateway "$STATE_DIR/aks-failure.json"