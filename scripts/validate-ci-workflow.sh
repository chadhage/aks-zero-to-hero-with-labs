#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

[[ $# -eq 1 ]] || fail "Usage: $0 .github/workflows/build.yml"
workflow=$1
[[ "$workflow" = /* ]] || workflow="$REPO_ROOT/$workflow"
require_file "$workflow"

grep -Eq '^on:|^[[:space:]]+[a-zA-Z_]+:' "$workflow" || fail 'Workflow does not look like YAML'
grep -Eiq 'docker/(build-push-action|login-action)|docker[[:space:]]+(build|buildx)' "$workflow" || fail 'Workflow has no container build step'
grep -Eiq '(mvn|gradle|ctest|npm)[^#]*(test|verify)|test-release\.sh' "$workflow" || fail 'Workflow has no test gate'
grep -Eiq 'docker scout|trivy|grype|defender' "$workflow" || fail 'Workflow has no vulnerability scan gate'
grep -Eiq 'push:[[:space:]]*true|docker[[:space:]]+push' "$workflow" || fail 'Workflow has no image push step'
grep -Eq 'sha-|github\.sha|GITHUB_SHA' "$workflow" || fail 'Workflow does not tag images from the commit SHA'
pass 'CI workflow includes build, test, scan, SHA tagging, and push gates'