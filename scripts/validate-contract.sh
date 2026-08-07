#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 CONTAINER-CONTRACT.md"
contract=$1
[[ "$contract" = /* ]] || contract="$REPO_ROOT/$contract"
require_file "$contract"

missing=0
for concept in runtime artifact port configuration secret health readiness liveness resource security non-root shutdown promotion; do
  if grep -Eiq "(^|[^[:alpha:]])$concept([^[:alpha:]]|$)" "$contract"; then
    pass "$concept"
  else
    printf '[FAIL] Contract does not address: %s\n' "$concept" >&2
    missing=$((missing + 1))
  fi
done

(( missing == 0 )) || fail "$missing required contract concept(s) are missing"
pass "Container contract covers all required runtime concerns"