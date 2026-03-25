#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  kubectl-backup.sh <namespace> <all|resource-type1,resource-type2>

Examples:
  kubectl-backup.sh default all
  kubectl-backup.sh my-app deployment,service,configmap
EOF
}

log() {
  printf '%s\n' "$*"
}

error() {
  printf 'Error: %s\n' "$*" >&2
}

sanitize_for_filename() {
  printf '%s' "$1" | sed -E 's#[^A-Za-z0-9._-]+#-#g'
}

build_output_file() {
  local output_dir="$1"
  local raw_type="$2"
  local resource_name="$3"
  local short_type="${raw_type%%.*}"
  local safe_name safe_short_type safe_raw_type base_path fallback_path

  safe_name="$(sanitize_for_filename "$resource_name")"
  safe_short_type="$(sanitize_for_filename "$short_type")"
  safe_raw_type="$(sanitize_for_filename "$raw_type")"

  base_path="${output_dir}/${safe_short_type}-${safe_name}.yaml"
  fallback_path="${output_dir}/${safe_raw_type}-${safe_name}.yaml"

  if [[ -e "$base_path" && "$base_path" != "$fallback_path" ]]; then
    printf '%s\n' "$fallback_path"
    return
  fi

  printf '%s\n' "$base_path"
}

backup_resource_type() {
  local namespace="$1"
  local resource_type="$2"
  local output_dir="$3"
  local resource_names resource count

  if ! resource_names="$(kubectl get "$resource_type" -n "$namespace" -o name --ignore-not-found 2>/dev/null)"; then
    log "Skipping ${resource_type}: unable to list resource type."
    return
  fi

  if [[ -z "$resource_names" ]]; then
    return
  fi

  count=0
  while IFS= read -r resource; do
    local raw_type resource_name output_file

    [[ -z "$resource" ]] && continue

    raw_type="${resource%%/*}"
    resource_name="${resource#*/}"
    output_file="$(build_output_file "$output_dir" "$raw_type" "$resource_name")"

    if kubectl get "$resource" -n "$namespace" -o yaml --show-managed-fields=false >"$output_file"; then
      log "Backed up ${resource} -> ${output_file}"
      count=$((count + 1))
    else
      error "Failed to back up ${resource}"
      rm -f "$output_file"
    fi
  done <<<"$resource_names"

  if (( count > 0 )); then
    log "Completed ${resource_type}: ${count} resource(s)."
  fi
}

main() {
  local namespace selector output_dir
  local -a resource_types

  if [[ $# -ne 2 ]]; then
    usage
    exit 1
  fi

  namespace="$1"
  selector="$2"
  output_dir="$namespace"

  if ! command -v kubectl >/dev/null 2>&1; then
    error "kubectl is not installed or not in PATH."
    exit 1
  fi

  if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
    error "Namespace '${namespace}' does not exist or is not accessible."
    exit 1
  fi

  mkdir -p "$output_dir"

  if [[ "$selector" == "all" ]]; then
    mapfile -t resource_types < <(kubectl api-resources --verbs=list --namespaced -o name | sort -u)
  else
    IFS=',' read -r -a resource_types <<<"$selector"
  fi

  if [[ ${#resource_types[@]} -eq 0 ]]; then
    error "No resource types were provided."
    exit 1
  fi

  for resource_type in "${resource_types[@]}"; do
    if [[ -z "$resource_type" ]]; then
      continue
    fi

    backup_resource_type "$namespace" "$resource_type" "$output_dir"
  done

  log "Backup completed in '${output_dir}'."
}

main "$@"
