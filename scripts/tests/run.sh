#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
tmp=$(mktemp -d)
server_pid=
cleanup() {
  [[ -z "$server_pid" ]] || kill "$server_pid" 2>/dev/null || true
  if [[ -f "$tmp/repo/.workshop-state/local-release.pids" ]]; then
    while IFS= read -r pid; do kill "$pid" 2>/dev/null || true; done < "$tmp/repo/.workshop-state/local-release.pids"
  fi
  rm -rf "$tmp" "$REPO_ROOT/workshop-notes/load-runs"
}
trap cleanup EXIT

pass_count=0
pass() { printf '[PASS] %s\n' "$1"; pass_count=$((pass_count + 1)); }
expect_success() {
  local label=$1 output
  shift
  if ! output=$("$@" 2>&1); then
    printf '[FAIL] %s\n%s\n' "$label" "$output" >&2
    return 1
  fi
  pass "$label"
}
expect_failure() {
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then printf '[FAIL] %s unexpectedly succeeded\n' "$label" >&2; return 1; fi
  pass "$label"
}

mapfile -t scripts < <(find "$SCRIPT_DIR" -type f -name '*.sh' | sort)
expect_success 'all shell scripts parse' bash -n "${scripts[@]}"

cat > "$tmp/contract.md" <<'EOF'
# Container contract
Runtime and artifact; port and configuration; secret handling; health with readiness and liveness;
resource limits; security and non-root execution; shutdown behavior; immutable promotion.
EOF
expect_success 'valid container contract passes' "$SCRIPT_DIR/validate-contract.sh" "$tmp/contract.md"
printf '# Container contract\nRuntime only\n' > "$tmp/bad-contract.md"
expect_failure 'incomplete container contract fails' "$SCRIPT_DIR/validate-contract.sh" "$tmp/bad-contract.md"

cat > "$tmp/build.yml" <<'EOF'
on: [push]
jobs:
  build:
    steps:
      - run: ./scripts/test-release.sh
      - run: docker build -t app:sha-$GITHUB_SHA .
      - run: docker scout cves app:sha-$GITHUB_SHA
      - run: docker push app:sha-$GITHUB_SHA
EOF
expect_success 'complete CI workflow passes' "$SCRIPT_DIR/validate-ci-workflow.sh" "$tmp/build.yml"
printf 'on: [push]\n' > "$tmp/bad-build.yml"
expect_failure 'incomplete CI workflow fails' "$SCRIPT_DIR/validate-ci-workflow.sh" "$tmp/bad-build.yml"

command -v node >/dev/null 2>&1 || { printf '[FAIL] Node.js is required only for the mock server in contract tests\n' >&2; exit 1; }
port=$((20000 + RANDOM % 20000))
node "$SCRIPT_DIR/tests/mock-skybridge.js" "$port" > "$tmp/server.log" 2>&1 &
server_pid=$!
for _ in 1 2 3 4 5; do grep -q . "$tmp/server.log" 2>/dev/null && break; sleep 1; done
kill -0 "$server_pid" 2>/dev/null || { cat "$tmp/server.log" >&2; exit 1; }
expect_success 'smoke test completes a real TCP round-trip' "$SCRIPT_DIR/smoke.sh" 127.0.0.1 "$port"
expect_failure 'smoke test rejects an invalid port' "$SCRIPT_DIR/smoke.sh" 127.0.0.1 invalid
expect_success 'baseline load run records evidence' "$SCRIPT_DIR/load.sh" --target "127.0.0.1:$port" --profile baseline --duration 1s --sessions 2
cp "$REPO_ROOT/workshop-notes/load-runs/baseline.json" "$REPO_ROOT/workshop-notes/load-runs/optimized.json"
expect_success 'comparable evidence reports no regression' "$SCRIPT_DIR/compare-runs.sh" baseline optimized

fixture="$tmp/repo"
mkdir -p "$fixture/apps/gateway-java" "$fixture/apps/parser-cpp" "$fixture/apps/ops-console" "$fixture/environments" "$fixture/k8s"
for component in gateway-java parser-cpp ops-console; do
  cat > "$fixture/apps/$component/test.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat > "$fixture/apps/$component/run.sh" <<'EOF'
#!/usr/bin/env bash
while :; do sleep 30; done
EOF
  chmod +x "$fixture/apps/$component/test.sh" "$fixture/apps/$component/run.sh"
done
printf 'GATEWAY_PORT=4561\nPARSER_URL=http://parser:8080\n' > "$fixture/environments/dev.env"
cp "$fixture/environments/dev.env" "$fixture/environments/test.env"
cp "$fixture/environments/dev.env" "$fixture/environments/uat.env"
cat > "$fixture/apps/gateway-java/config.txt" <<'EOF'
GATEWAY_PORT PARSER_URL DATABASE_PASSWORD
EOF
cat > "$fixture/k8s/workloads.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
      containers:
        - name: gateway
          image: gateway-java:sha-test
          readinessProbe: { httpGet: { path: /ready, port: 8080 } }
          livenessProbe: { httpGet: { path: /health, port: 8080 } }
          resources: { requests: { memory: 32Mi }, limits: { memory: 64Mi } }
EOF
mock_path="$SCRIPT_DIR/tests/mock-bin:$PATH"
expect_success 'release tests run supplied component entry points' env WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/test-release.sh"
expect_success 'release manifest inventories supplied source' env WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/show-release-manifest.sh"
expect_success 'runtime inspection analyzes supplied component' env WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/inspect-runtime.sh" gateway-java
expect_success 'config inventory reports supplied settings' env WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/inventory-config.sh"
expect_success 'release runner starts supplied component entry points' env WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/run-release.sh" --env environments/dev.env
expect_success 'manifest validator checks supplied Kubernetes YAML' env PATH="$mock_path" WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/validate-k8s-manifests.sh" k8s/
expect_success 'local failure injection executes in kind context' env PATH="$mock_path" MOCK_KUBE_CONTEXT=kind-z2h WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/inject-k8s-failure.sh" bad-readiness
expect_success 'local failure reset executes in kind context' env PATH="$mock_path" MOCK_KUBE_CONTEXT=kind-z2h WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/reset-k8s-failure.sh"
expect_success 'AKS assigned failure executes explicit instructor mode' env PATH="$mock_path" MOCK_KUBE_CONTEXT=aks-z2h AKS_FAILURE_MODE=memory-pressure WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/inject-aks-failure.sh" assigned
expect_success 'AKS failure reset executes in AKS context' env PATH="$mock_path" MOCK_KUBE_CONTEXT=aks-z2h WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/reset-aks-failure.sh"
expect_success 'ACR renderer produces digest-pinned overlay without apply' env PATH="$mock_path" WORKSHOP_REPO_ROOT="$fixture" "$SCRIPT_DIR/set-aks-images.sh" mockregistry deadbee k8s/aks/
grep -q 'mock.azurecr.io/gateway-java@sha256:' "$fixture/k8s/aks/workloads.yaml" || { printf '[FAIL] rendered digest was not found\n' >&2; exit 1; }
pass 'rendered workload contains the resolved ACR digest'

expect_failure 'prerequisite gate detects missing starter assets' "$SCRIPT_DIR/verify-prerequisites.sh"
expect_failure 'release tests reject missing application source' "$SCRIPT_DIR/test-release.sh"
expect_failure 'release manifest rejects missing application source' "$SCRIPT_DIR/show-release-manifest.sh"
expect_failure 'runtime inspection rejects missing component source' "$SCRIPT_DIR/inspect-runtime.sh" gateway-java
expect_failure 'config inventory rejects missing application source' "$SCRIPT_DIR/inventory-config.sh"
expect_failure 'release runner rejects missing environment profile' "$SCRIPT_DIR/run-release.sh" --env environments/dev.env
expect_failure 'manifest validation rejects missing k8s directory' "$SCRIPT_DIR/validate-k8s-manifests.sh" k8s/
expect_failure 'local failure injection rejects wrong kubectl context' "$SCRIPT_DIR/inject-k8s-failure.sh" bad-readiness
expect_failure 'local failure reset rejects wrong kubectl context' "$SCRIPT_DIR/reset-k8s-failure.sh"
expect_failure 'AKS failure injection rejects wrong kubectl context' "$SCRIPT_DIR/inject-aks-failure.sh" assigned
expect_failure 'AKS failure reset rejects wrong kubectl context' "$SCRIPT_DIR/reset-aks-failure.sh"
expect_failure 'ACR renderer rejects invalid registry name' "$SCRIPT_DIR/set-aks-images.sh" 'bad-name!' deadbee k8s/aks/

printf '\n%d contract tests passed.\n' "$pass_count"