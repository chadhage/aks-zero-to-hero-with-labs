#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO_ROOT=${WORKSHOP_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}
REPO_ROOT=$(cd "$REPO_ROOT" && pwd)
STATE_DIR="$REPO_ROOT/.workshop-state"

info() { printf '[INFO] %s\n' "$*"; }
pass() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_file() {
  [[ -f "$1" ]] || fail "Required file not found: ${1#"$REPO_ROOT"/}"
}

require_dir() {
  [[ -d "$1" ]] || fail "Required directory not found: ${1#"$REPO_ROOT"/}"
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

utc_stamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

current_context() {
  kubectl config current-context 2>/dev/null || true
}

require_context() {
  local expected=$1 actual
  actual=$(current_context)
  [[ -n "$actual" ]] || fail 'kubectl has no current context'
  [[ "$actual" == *"$expected"* ]] || fail "Refusing to continue: context '$actual' does not contain '$expected'"
}

require_clean_backup_slot() {
  local backup=$1
  [[ ! -e "$backup" ]] || fail "A prior failure injection is still active: ${backup#"$REPO_ROOT"/}. Run the matching reset script first."
}

retry() {
  local attempts=$1
  shift
  local count=1 delay=2
  until "$@"; do
    (( count >= attempts )) && return 1
    warn "Command failed (attempt $count/$attempts); retrying in ${delay}s"
    sleep "$delay"
    count=$((count + 1))
    delay=$((delay * 2))
  done
}