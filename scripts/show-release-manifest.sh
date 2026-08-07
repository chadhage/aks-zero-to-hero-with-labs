#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_command git
require_dir "$REPO_ROOT/apps"

printf 'release_revision=%s\n' "$(git -C "$REPO_ROOT" rev-parse HEAD)"
printf 'generated_at=%s\n' "$(utc_stamp)"
for component in gateway-java parser-cpp ops-console; do
  dir="$REPO_ROOT/apps/$component"
  require_dir "$dir"
  printf '\n[%s]\n' "$component"
  printf 'source=%s\n' "apps/$component"
  find "$dir" -maxdepth 3 -type f \( -name '*.jar' -o -name '*.war' -o -name '*.so' -o -name '*.html' -o -name 'Dockerfile' -o -perm -u+x \) \
    -print | sed "s|$REPO_ROOT/|artifact=|" | sort
done

printf '\n[environments]\n'
require_dir "$REPO_ROOT/environments"
find "$REPO_ROOT/environments" -maxdepth 1 -type f -name '*.env' -print | sed "s|$REPO_ROOT/|profile=|" | sort