#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

is_allowed_target() {
  case "$1" in
    https://learn.microsoft.com/* | \
    https://azure.microsoft.com/* | \
    https://github.com/chadhage/aks-zero-to-hero-with-labs | \
    https://github.com/chadhage/aks-zero-to-hero-with-labs/* | \
    https://chadhage.github.io/aks-zero-to-hero-with-labs | \
    https://chadhage.github.io/aks-zero-to-hero-with-labs/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

extract_targets() {
  local file=$1
  {
    grep -Eio "href[[:space:]]*=[[:space:]]*[\"']https?://[^\"']+" "$file" 2>/dev/null \
      | sed -E "s/^href[[:space:]]*=[[:space:]]*[\"']//I" || true
    grep -Eio '[[][^]]+[]][(]https?://[^)[:space:]]+[)]' "$file" 2>/dev/null \
      | grep -Eio 'https?://[^)[:space:]]+' || true
  } | sort -u
}

violations=0
while IFS= read -r -d '' file; do
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    if ! is_allowed_target "$target"; then
      printf '[FAIL] Disallowed external hyperlink in %s: %s\n' "${file#"$REPO_ROOT"/}" "$target" >&2
      violations=$((violations + 1))
    fi
  done < <(extract_targets "$file")
done < <(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f -print0)

(( violations == 0 )) || fail "$violations disallowed external hyperlink(s) found"
pass 'All hyperlinks target official Microsoft content or this repository'