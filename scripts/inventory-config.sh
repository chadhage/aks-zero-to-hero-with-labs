#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_dir "$REPO_ROOT/apps"
require_dir "$REPO_ROOT/environments"

printf '| Setting | Sources | Secret-like |\n| --- | --- | --- |\n'
names=$(
  {
    grep -RhoE '\b[A-Z][A-Z0-9_]{2,}\b' "$REPO_ROOT/apps" --exclude-dir=build --exclude-dir=target --exclude-dir=node_modules 2>/dev/null || true
    sed -nE 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/\2/p' "$REPO_ROOT"/environments/*.env 2>/dev/null || true
  } | sort -u
)
[[ -n "$names" ]] || fail 'No configuration variables found in apps/ or environments/*.env'
while IFS= read -r name; do
  sources=$(grep -Rl "$name" "$REPO_ROOT/apps" "$REPO_ROOT/environments" --exclude-dir=build --exclude-dir=target --exclude-dir=node_modules 2>/dev/null | sed "s|$REPO_ROOT/||" | paste -sd ',' -)
  secret=no
  [[ "$name" =~ (PASSWORD|SECRET|TOKEN|KEY|CONNECTION_STRING) ]] && secret=yes
  printf '| `%s` | %s | %s |\n' "$name" "$sources" "$secret"
done <<< "$names"