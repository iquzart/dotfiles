#!/usr/bin/env bash
# Scaffold a generic Chi service from the skill's maintained boilerplate.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: new-chi-service.sh --module MODULE --name NAME --destination PATH [--port PORT]

Creates a service from assets/chi-boilerplate, replacing its explicit
module, service-name, and port placeholders.
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

main() {
  local module=""
  local name=""
  local destination=""
  local port="8080"
  local script_dir template file

  while (($#)); do
    case "$1" in
      --module)
        module=${2:-}
        shift 2
        ;;
      --name)
        name=${2:-}
        shift 2
        ;;
      --destination)
        destination=${2:-}
        shift 2
        ;;
      --port)
        port=${2:-}
        shift 2
        ;;
      --help|-h)
        usage
        return 0
        ;;
      *)
        fail "unknown argument: $1"
        ;;
    esac
  done

  [[ -n "$module" ]] || fail "--module is required"
  [[ -n "$name" ]] || fail "--name is required"
  [[ -n "$destination" ]] || fail "--destination is required"
  [[ "$module" =~ ^[A-Za-z0-9._/-]+$ ]] || fail "module contains unsupported characters"
  [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]] || fail "name must use lowercase letters, digits, and hyphens"
  [[ "$port" =~ ^[0-9]{1,5}$ ]] || fail "port must be a number"
  ((port >= 1 && port <= 65535)) || fail "port must be between 1 and 65535"
  [[ ! -e "$destination" ]] || fail "destination already exists: $destination"

  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  template="$script_dir/../assets/chi-boilerplate"
  [[ -d "$template" ]] || fail "template not found: $template"

  cp -R "$template" "$destination"
  export MODULE_PATH="$module" SERVICE_NAME="$name" SERVICE_PORT="$port"
  while IFS= read -r file; do
    perl -pi -e 's/\{\{MODULE_PATH\}\}/$ENV{MODULE_PATH}/g; s/\{\{SERVICE_NAME\}\}/$ENV{SERVICE_NAME}/g; s/\{\{SERVICE_PORT\}\}/$ENV{SERVICE_PORT}/g' "$file"
  done < <(grep -rl '{{' "$destination" || true)

  while IFS= read -r -d '' file; do
    gofmt -w "$file"
  done < <(find "$destination" -type f -name '*.go' -print0)
  (
    cd "$destination"
    go mod tidy
  )

  printf 'created %s\n' "$destination"
  printf 'verify with: cd %q && go test ./... && go vet ./...\n' "$destination"
  printf 'endpoints: GET /api/v1/ping, /system/version, /system/health/live, /system/health/ready, /system/metrics\n'
}

main "$@"
