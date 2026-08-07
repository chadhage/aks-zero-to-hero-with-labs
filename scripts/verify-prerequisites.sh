#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
failures=0

check_command() {
  local label=$1 command_name=$2
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '[PASS] %s\n' "$label"
  else
    printf '[FAIL] %s (missing command: %s)\n' "$label" "$command_name"
    failures=$((failures + 1))
  fi
}

version_at_least() {
  awk -v actual="$1" -v minimum="$2" 'BEGIN {
    split(actual, a, "."); split(minimum, m, ".");
    for (i=1; i<=3; i++) { a[i]+=0; m[i]+=0; if (a[i]>m[i]) exit 0; if (a[i]<m[i]) exit 1 }
    exit 0
  }'
}

check_version() {
  local label=$1 command_name=$2 minimum=$3
  shift 3
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '[FAIL] %s (missing command: %s)\n' "$label" "$command_name"
    failures=$((failures + 1))
    return
  fi
  local output version
  output=$("$@" 2>&1 || true)
  version=$(grep -Eo '[0-9]+\.[0-9]+([.][0-9]+)?' <<< "$output" | head -1)
  if [[ -n "$version" ]] && version_at_least "$version" "$minimum"; then
    printf '[PASS] %s %s (minimum %s)\n' "$label" "$version" "$minimum"
  else
    printf '[FAIL] %s version %s (minimum %s)\n' "$label" "${version:-unknown}" "$minimum"
    failures=$((failures + 1))
  fi
}

check_probe() {
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then
    printf '[PASS] %s\n' "$label"
  else
    printf '[FAIL] %s\n' "$label"
    failures=$((failures + 1))
  fi
}

check_path() {
  local kind=$1 path=$2
  if [[ "$kind" == file && -f "$REPO_ROOT/$path" ]] || [[ "$kind" == dir && -d "$REPO_ROOT/$path" ]]; then
    printf '[PASS] %s\n' "$path"
  else
    printf '[FAIL] Missing starter %s: %s\n' "$kind" "$path"
    failures=$((failures + 1))
  fi
}

printf 'Skybridge workshop prerequisite check\n\nToolchain\n'
check_command 'Bash' bash
check_command 'curl' curl
check_version 'Git' git 2.40 git --version
check_version 'Docker CLI' docker 24.0 docker version --format '{{.Client.Version}}'
if command -v docker >/dev/null 2>&1; then
  check_probe 'Docker Engine is reachable' docker info
  check_version 'Docker Compose plugin' docker 2.20 docker compose version --short
  check_version 'Docker Scout plugin' docker 1.0 docker scout version
fi
check_version 'Azure CLI' az 2.60 az version
check_version 'kubectl' kubectl 1.30 kubectl version --client
check_version 'kind' kind 0.23 kind version

printf '\nStarter repository assets\n'
for path in apps/gateway-java apps/parser-cpp apps/ops-console environments k8s .github/workflows; do
  check_path dir "$path"
done
for path in environments/dev.env environments/test.env environments/uat.env; do
  check_path file "$path"
done

printf '\nWorkshop scripts\n'
for name in compare-runs inject-aks-failure inject-k8s-failure inspect-runtime inventory-config load reset-aks-failure reset-k8s-failure run-release set-aks-images show-release-manifest smoke test-release validate-ci-workflow validate-contract validate-k8s-manifests verify-prerequisites; do
  check_path file "scripts/$name.sh"
done

printf '\nResult: %d failure(s)\n' "$failures"
if (( failures > 0 )); then
  printf 'Obtain or restore the missing starter assets before Phase 0. Tool-only success is not sufficient.\n' >&2
  exit 1
fi

printf 'All prerequisites are present.\n'