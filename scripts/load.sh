#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

target=127.0.0.1:4561
profile=baseline
duration=60s
sessions=${LOAD_SESSIONS:-5}
while (( $# )); do
  case "$1" in
    --target) [[ $# -ge 2 ]] || fail '--target requires HOST:PORT'; target=$2; shift 2 ;;
    --profile) [[ $# -ge 2 ]] || fail '--profile requires a name'; profile=$2; shift 2 ;;
    --duration) [[ $# -ge 2 ]] || fail '--duration requires values such as 60s or 5m'; duration=$2; shift 2 ;;
    --sessions) [[ $# -ge 2 ]] || fail '--sessions requires a positive integer'; sessions=$2; shift 2 ;;
    *) fail "Unknown option: $1" ;;
  esac
done
[[ "$target" == *:* ]] || fail '--target must be HOST:PORT'
host=${target%:*}; port=${target##*:}
[[ "$port" =~ ^[0-9]+$ ]] || fail "Invalid target port: $port"
[[ "$host" =~ ^[A-Za-z0-9.-]+$ ]] || fail "Invalid target host: $host"
[[ "$profile" =~ ^[A-Za-z0-9._-]+$ ]] || fail 'Profile may contain only letters, numbers, dot, underscore, and dash'
[[ "$sessions" =~ ^[1-9][0-9]*$ ]] || fail '--sessions must be a positive integer'
if [[ "$duration" =~ ^([1-9][0-9]*)([sm])$ ]]; then
  amount=${BASH_REMATCH[1]}; unit=${BASH_REMATCH[2]}
    if [[ "$unit" == m ]]; then seconds=$((amount * 60)); else seconds=$amount; fi
else
  fail '--duration must use positive seconds or minutes, for example 60s or 5m'
fi

require_command timeout
require_command awk
output_dir="$REPO_ROOT/workshop-notes/load-runs"
mkdir -p "$output_dir"
output="$output_dir/$profile.json"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
latencies="$temp_dir/latencies"
errors_file="$temp_dir/errors"
: > "$latencies"
: > "$errors_file"

worker() {
    local worker_id=$1 deadline=$2 sequence=0 started ended elapsed response payload
    while (( $(date +%s) < deadline )); do
        sequence=$((sequence + 1))
        payload="QU/DEST0001/ORIG0001/HDR001/PAYLOAD/$worker_id-$sequence"
        started=$(date +%s%N)
        if response=$(timeout 6 bash -c '
            exec 3<>/dev/tcp/"$1"/"$2"
            IFS= read -r greeting <&3 || true
            printf "MSG %s\n" "$3" >&3
            IFS= read -r reply <&3
            printf "%s" "$reply"
        ' _ "$host" "$port" "$payload") && [[ "$response" == ACK\ * ]]; then
            ended=$(date +%s%N)
            elapsed=$(( (ended - started) / 1000000 ))
            printf '%s\n' "$elapsed" >> "$latencies"
        else
            printf '1\n' >> "$errors_file"
        fi
    done
}

deadline=$(( $(date +%s) + seconds ))
for (( worker_id=1; worker_id<=sessions; worker_id++ )); do worker "$worker_id" "$deadline" & done
wait

acknowledged=$(wc -l < "$latencies" | tr -d ' ')
errors=$(wc -l < "$errors_file" | tr -d ' ')
sent=$((acknowledged + errors))
throughput=$(awk -v count="$acknowledged" -v elapsed="$seconds" 'BEGIN { printf "%.3f", elapsed ? count / elapsed : 0 }')
percentile() {
    local fraction=$1
  sort -n "$latencies" | awk -v p="$fraction" '{ values[NR]=$1 } END { if (!NR) { print 0; exit } rank=int(NR*p); if (rank < NR*p) rank++; if (rank < 1) rank=1; print values[rank] }'
}
p50=$(percentile 0.50); p95=$(percentile 0.95); p99=$(percentile 0.99)
cat > "$output" <<EOF
{
    "profile": "$profile",
    "target": "$host:$port",
    "duration_seconds": $seconds,
    "sessions": $sessions,
    "messages_sent": $sent,
    "messages_acknowledged": $acknowledged,
    "errors": $errors,
    "throughput_per_second": $throughput,
    "latency_ms": { "p50": $p50, "p95": $p95, "p99": $p99 },
    "generated_at_epoch": $(date +%s)
}
EOF
cat "$output"
printf 'Saved load evidence: %s\n' "${output#"$REPO_ROOT"/}"
(( acknowledged > 0 && errors == 0 )) || exit 1