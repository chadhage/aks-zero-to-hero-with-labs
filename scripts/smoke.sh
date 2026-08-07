#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 2 ]] || fail "Usage: $0 HOST PORT"
host=$1 port=$2
[[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]] || fail "Invalid port: $port"
require_command timeout

payload="QU/DEST0001/ORIG0001/HDR001/PAYLOAD/smoke-$(date +%s)"
response=$(
  timeout 15 bash -c '
    exec 3<>/dev/tcp/"$1"/"$2"
    IFS= read -r greeting <&3 || true
    printf "MSG %s\n" "$3" >&3
    IFS= read -r reply <&3
    printf "%s\n" "$reply"
  ' _ "$host" "$port" "$payload"
) || fail "No valid response from $host:$port within 15 seconds"

[[ "$response" == ACK\ * ]] || fail "Expected an ACK response from $host:$port, received: ${response:-<empty>}"
pass "Skybridge message round-trip succeeded at $host:$port"
printf '%s\n' "$response"