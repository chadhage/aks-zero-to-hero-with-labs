#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

usage() { fail "Usage: $0 --env environments/dev.env"; }
[[ $# -eq 2 && "$1" == --env ]] || usage
env_file=$2
[[ "$env_file" = /* ]] || env_file="$REPO_ROOT/$env_file"
require_file "$env_file"
ensure_state_dir
pid_file="$STATE_DIR/local-release.pids"

if [[ -f "$pid_file" ]]; then
  info 'Stopping the previously started local release'
  while IFS= read -r pid; do
    [[ "$pid" =~ ^[0-9]+$ ]] && kill "$pid" 2>/dev/null || true
  done < "$pid_file"
  rm -f "$pid_file"
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

start_component() {
  local component=$1 variable=$2 command_value dir
  command_value=${!variable:-}
  dir="$REPO_ROOT/apps/$component"
  require_dir "$dir"
  if [[ -n "$command_value" ]]; then
    info "Starting $component with $variable"
    (cd "$dir" && exec bash -lc "$command_value") >"$STATE_DIR/$component.log" 2>&1 &
  elif [[ -x "$dir/run.sh" ]]; then
    info "Starting $component with apps/$component/run.sh"
    (cd "$dir" && exec ./run.sh) >"$STATE_DIR/$component.log" 2>&1 &
  else
    fail "No startup command for $component. Add executable apps/$component/run.sh or set $variable in ${env_file#"$REPO_ROOT"/}."
  fi
  printf '%s\n' "$!" >> "$pid_file"
}

: > "$pid_file"
start_component parser-cpp PARSER_COMMAND
start_component gateway-java GATEWAY_COMMAND
start_component ops-console CONSOLE_COMMAND
sleep 2

failed=0
while IFS= read -r pid; do
  if ! kill -0 "$pid" 2>/dev/null; then failed=1; fi
done < "$pid_file"
if (( failed )); then
  for log in "$STATE_DIR"/*.log; do [[ -f "$log" ]] && { printf '\n== %s ==\n' "$(basename "$log")"; tail -n 30 "$log"; }; done >&2
  while IFS= read -r pid; do kill "$pid" 2>/dev/null || true; done < "$pid_file"
  rm -f "$pid_file"
  fail 'One or more release components exited during startup'
fi

pass "Release started with ${env_file#"$REPO_ROOT"/}"
printf 'PID file: %s\nLogs: %s\n' "${pid_file#"$REPO_ROOT"/}" "${STATE_DIR#"$REPO_ROOT"/}/*.log"