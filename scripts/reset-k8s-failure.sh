#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/failure.sh"

[[ $# -eq 0 ]] || fail "Usage: $0"
require_context kind-z2h
reset_failure parser "$STATE_DIR/k8s-failure.json"