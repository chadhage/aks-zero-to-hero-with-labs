#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

inject_failure() {
  local scope=$1 deployment=$2 container=$3 mode=$4 backup=$5
  require_command kubectl
  ensure_state_dir
  require_clean_backup_slot "$backup"
  kubectl get deployment "$deployment" -o json > "$backup"
  printf '%s\t%s\t%s\t%s\t%s\n' "$(utc_stamp)" "$scope" "$deployment" "$container" "$mode" >> "$STATE_DIR/mutations.log"
  local mutation_status=0
  case "$mode" in
    bad-readiness)
      kubectl patch deployment "$deployment" --type=strategic -p \
        "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$container\",\"readinessProbe\":{\"httpGet\":{\"path\":\"/intentional-readiness-failure\"}}}]}}}}" || mutation_status=$?
      ;;
    missing-configuration)
      kubectl set env "deployment/$deployment" PARSER_URL- API_BASE- DATABASE_URL- || mutation_status=$?
      ;;
    memory-pressure)
      kubectl set resources "deployment/$deployment" -c "$container" --requests=memory=8Mi --limits=memory=8Mi || mutation_status=$?
      ;;
    *) rm -f "$backup"; fail "Unsupported failure mode: $mode" ;;
  esac
  if (( mutation_status != 0 )); then
    rm -f "$backup"
    fail "kubectl could not inject $mode into deployment/$deployment"
  fi
  kubectl rollout status "deployment/$deployment" --timeout=45s && warn 'The rollout became healthy; inspect whether the selected failure is observable in this application build' || true
  pass "Injected $mode into deployment/$deployment. Diagnose it before running the reset script."
}

reset_failure() {
  local deployment=$1 backup=$2
  require_command kubectl
  require_file "$backup"
  kubectl rollout undo "deployment/$deployment"
  kubectl rollout status "deployment/$deployment" --timeout=180s
  rm -f "$backup"
  pass "Restored deployment/$deployment and verified a healthy rollout"
}