#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 k8s/"
manifest_dir=$1
[[ "$manifest_dir" = /* ]] || manifest_dir="$REPO_ROOT/$manifest_dir"
require_dir "$manifest_dir"
require_command kubectl

mapfile -t manifests < <(find "$manifest_dir" -type f \( -name '*.yaml' -o -name '*.yml' \) ! -path '*/aks/*' | sort)
(( ${#manifests[@]} > 0 )) || fail "No Kubernetes YAML files found in ${manifest_dir#"$REPO_ROOT"/}"
kubectl apply --dry-run=client --validate=false -f "$manifest_dir" >/dev/null

combined=$(cat "${manifests[@]}")
for concept in readinessProbe livenessProbe resources securityContext; do
  grep -q "$concept" <<< "$combined" || fail "Kubernetes manifests do not define $concept"
done
grep -Eq 'runAsNonRoot:[[:space:]]*true' <<< "$combined" || fail 'Kubernetes manifests do not enforce runAsNonRoot: true'
pass "Kubernetes manifests parse and include probes, resources, and non-root security"