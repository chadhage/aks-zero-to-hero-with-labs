#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 2 ]] || fail "Usage: $0 BASELINE_PROFILE OPTIMIZED_PROFILE"
require_command awk
resolve_report() {
  local value=$1
  [[ "$value" == *.json ]] || value="$REPO_ROOT/workshop-notes/load-runs/$value.json"
  [[ "$value" = /* ]] || value="$REPO_ROOT/$value"
  require_file "$value"
  printf '%s' "$value"
}
before=$(resolve_report "$1")
after=$(resolve_report "$2")

json_number() {
    local file=$1 key=$2
    grep -m1 -E "\"$key\"[[:space:]]*:" "$file" | sed -E "s/.*\"$key\"[[:space:]]*:[[:space:]]*([-+]?[0-9]+([.][0-9]+)?).*/\1/"
}
delta() { awk -v old="$1" -v new="$2" 'BEGIN { if (old == 0) print "n/a"; else printf "%+.1f%%", (new-old)/old*100 }'; }
verdict() {
    local old=$1 new=$2 direction=$3
    if [[ "$direction" == higher ]]; then awk -v old="$old" -v new="$new" 'BEGIN { print new >= old ? "improved/held" : "regressed" }'
    else awk -v old="$old" -v new="$new" 'BEGIN { print new <= old ? "improved/held" : "regressed" }'; fi
}

printf '| Metric | Baseline | Optimized | Delta | Verdict |\n'
printf '| --- | ---: | ---: | ---: | --- |\n'
regression=0
for spec in 'Throughput / second|throughput_per_second|higher' 'Latency p50 (ms)|p50|lower' 'Latency p95 (ms)|p95|lower' 'Latency p99 (ms)|p99|lower' 'Errors|errors|lower'; do
    IFS='|' read -r label key direction <<< "$spec"
    old=$(json_number "$before" "$key"); new=$(json_number "$after" "$key")
    [[ -n "$old" && -n "$new" ]] || fail "Missing numeric metric '$key' in load evidence"
    result=$(verdict "$old" "$new" "$direction")
    [[ "$result" == regressed ]] && regression=1
    printf '| %s | %s | %s | %s | %s |\n' "$label" "$old" "$new" "$(delta "$old" "$new")" "$result"
done
if (( regression )); then printf '\nVerdict: review regressions before accepting the change\n'; exit 1; fi
printf '\nVerdict: no measured metric regressed\n'