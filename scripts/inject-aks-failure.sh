#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/failure.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 assigned|bad-readiness|missing-configuration|memory-pressure"
require_context aks-z2h
mode=$1
if [[ "$mode" == assigned ]]; then
  mode=${AKS_FAILURE_MODE:-}
  [[ "$mode" =~ ^(bad-readiness|missing-configuration|memory-pressure)$ ]] || \
    fail 'For assigned mode, the instructor must set AKS_FAILURE_MODE=bad-readiness, missing-configuration, or memory-pressure'
fi
inject_failure aks gateway gateway "$mode" "$STATE_DIR/aks-failure.json"