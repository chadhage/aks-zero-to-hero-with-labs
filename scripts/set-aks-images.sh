#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 3 ]] || fail "Usage: $0 ACR_NAME SHORT_SHA OUTPUT_DIR"
acr_name=$1 short_sha=$2 output_dir=$3
[[ "$acr_name" =~ ^[A-Za-z0-9]+$ ]] || fail 'ACR name may contain only letters and numbers'
[[ "$short_sha" =~ ^[0-9a-fA-F]{7,40}$ ]] || fail 'SHA must be a 7-40 character hexadecimal Git commit ID'
[[ "$output_dir" = /* ]] || output_dir="$REPO_ROOT/$output_dir"
source_dir="$REPO_ROOT/k8s"
require_dir "$source_dir"
require_command az
require_command kubectl

login_server=$(retry 3 az acr show --name "$acr_name" --query loginServer -o tsv)
[[ -n "$login_server" ]] || fail "Could not resolve login server for ACR: $acr_name"
declare -A images
for component in gateway-java parser-cpp ops-console; do
  digest=$(retry 3 az acr manifest list-metadata --registry "$acr_name" --name "$component" \
    --query "[?contains(tags, 'sha-$short_sha')].digest | [0]" -o tsv)
  [[ "$digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]] || fail "ACR has no digest for $component:sha-$short_sha. Push the tested local image first; this script never rebuilds."
  images[$component]="$login_server/$component@$digest"
  pass "$component -> ${images[$component]}"
done

mkdir -p "$output_dir"
output="$output_dir/workloads.yaml"
kustomization="$output_dir/kustomization.yaml"
temp=$(mktemp)
trap 'rm -f "$temp"' EXIT
mapfile -t resources < <(find "$source_dir" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) ! -name 'kustomization.yaml' | sort)
(( ${#resources[@]} > 0 )) || fail 'No base Kubernetes manifests were found directly under k8s/'
{
  printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n'
  for resource in "${resources[@]}"; do printf '  - ../%s\n' "$(basename "$resource")"; done
  printf 'images:\n'
  for component in gateway-java parser-cpp ops-console; do
    printf '  - name: %s\n    newName: %s/%s\n    digest: %s\n' "$component" "$login_server" "$component" "${images[$component]##*@}"
  done
} > "$kustomization"
kubectl kustomize "$output_dir" > "$temp"
grep -q '@sha256:' "$temp" || fail 'Rendered manifests contain no digest-pinned images'
count=$(grep -c '@sha256:' "$temp" || true)
(( count >= 3 )) || fail "Expected at least three digest-pinned image references, found $count"
mv "$temp" "$output"
trap - EXIT
pass "Rendered digest-pinned AKS manifests to ${output#"$REPO_ROOT"/} without applying or rebuilding images"