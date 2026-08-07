#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/failure.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 bad-readiness|missing-configuration|memory-pressure"
require_context kind-z2h
inject_failure local parser parser "$1" "$STATE_DIR/k8s-failure.json"