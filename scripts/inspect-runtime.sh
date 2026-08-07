#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 gateway-java|parser-cpp"
component=$1
dir="$REPO_ROOT/apps/$component"
require_dir "$dir"

case "$component" in
  gateway-java)
    printf 'component=gateway-java\n'
    if command -v java >/dev/null 2>&1; then java -version 2>&1 | sed 's/^/java=/' ; else warn 'Java is not installed on this host'; fi
    find "$dir" -type f \( -name '*.jar' -o -name '*.war' \) -print | sed "s|$REPO_ROOT/|artifact=|" | sort
    grep -RhoE 'GATEWAY_[A-Z0-9_]+|PARSER_URL|JAVA_[A-Z0-9_]+' "$dir" --exclude-dir=build --exclude-dir=target 2>/dev/null | sort -u | sed 's/^/config=/' || true
    ;;
  parser-cpp)
    printf 'component=parser-cpp\n'
    binaries=$(find "$dir" -type f -perm -u+x ! -name '*.sh' ! -path '*/.git/*' 2>/dev/null || true)
    [[ -n "$binaries" ]] || warn 'No built parser executable found; build the parser before inspecting linked libraries'
    while IFS= read -r binary; do
      [[ -n "$binary" ]] || continue
      printf 'artifact=%s\n' "${binary#"$REPO_ROOT"/}"
      if command -v file >/dev/null 2>&1; then file "$binary"; fi
      if command -v ldd >/dev/null 2>&1; then ldd "$binary" || true; fi
    done <<< "$binaries"
    grep -RhoE 'PARSER_[A-Z0-9_]+' "$dir" --exclude-dir=build 2>/dev/null | sort -u | sed 's/^/config=/' || true
    ;;
  *) fail "Unsupported component: $component" ;;
esac