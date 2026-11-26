#!/usr/bin/env bash
# Start an interactive, non-root ephemeral container in a Kubernetes pod.

set -euo pipefail

usage() {
  cat <<EOF
Usage: ${0##*/} [--dry-run] <pod-name> [namespace] [target-container] [debug-image]

  The namespace defaults to the current kubectl context's namespace, or
  "default" if the context has no namespace. The debug image defaults to busybox.
  Use "" to skip a positional argument and set a later one.
  Use --dry-run to preview the target without creating a container.
EOF
}

log() {
  local level=$1 message=$2 color='' reset=''
  if [[ -t 2 && ${TERM:-dumb} != dumb && -z ${NO_COLOR:-} ]]; then
    case "$level" in
      ERROR) color=$'\033[31m' ;;
      *) color=$'\033[36m' ;;
    esac
    reset=$'\033[0m'
  fi
  printf '%s %s[%s]%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$color" "$level" "$reset" "$message" >&2
}

run_debug() (
  local pod=$1 namespace=$2 target=$3 image=$4
  local profile_dir profile
  profile_dir=$(mktemp -d "${TMPDIR:-/tmp}/kubectl-debug.XXXXXX")
  profile="$profile_dir/profile.yaml"
  trap 'rm -f -- "$profile"; rmdir -- "$profile_dir"' EXIT

  # BusyBox normally runs as root, so set a numeric non-root UID explicitly.
  cat >"$profile" <<'EOF'
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  runAsNonRoot: true
  runAsUser: 1000
  seccompProfile:
    type: RuntimeDefault
EOF

  local args=(
    debug "pod/$pod" -it
    "--namespace=$namespace"
    "--image=$image"
    --profile=restricted
    "--custom=$profile"
  )
  if [[ -n "$target" ]]; then
    args+=("--target=$target")
  fi
  kubectl "${args[@]}" -- sh
)

main() {
  local dry_run=false
  case "${1:-}" in
    -h|--help)
      usage
      return
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
  esac

  local pod=${1:-} namespace=${2:-} target=${3:-} image=${4:-busybox}
  case "$pod" in
    pod/*|pods/*|po/*) pod=${pod#*/} ;;
  esac
  if [[ -z "$pod" || "$pod" == -* || "$pod" == */* || $# -gt 4 ]]; then
    usage >&2
    return 2
  fi
  if ! command -v kubectl >/dev/null 2>&1; then
    log ERROR 'kubectl is required but was not found in PATH.'
    return 1
  fi

  if [[ -z "$namespace" ]]; then
    if ! namespace=$(kubectl config view --minify -o 'jsonpath={.contexts[0].context.namespace}'); then
      log ERROR 'Could not read the namespace from the current kubectl context.'
      return 1
    fi
    namespace=${namespace:-default}
  fi

  local details="pod=$pod namespace=$namespace image=$image target=${target:-none}"
  if [[ "$dry_run" == true ]]; then
    log INFO "Would start an ephemeral debug container: $details"
    return
  fi
  log INFO "Starting an ephemeral debug container: $details"
  run_debug "$pod" "$namespace" "$target" "$image"
}

main "$@"
