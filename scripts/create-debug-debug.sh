$()$(
  bash
  #!/usr/bin/env bash

  set -Eeuo pipefail

  # Usage:
  # ./create-debug-debug.sh <pod-name> [namespace] [target-container] [debug-image]
  #
  # Example:
  # ./create-debug-debug.sh litellm-55854fb64f-q5tgn ai-gateway-uat litellm curlimages/curl:latest

  POD="${1:?Usage: $0 <pod-name> [namespace] [target-container] [debug-image]}"
  NAMESPACE="${2:-default}"
  TARGET="${3:-}"
  IMAGE="${4:-curlimages/curl:latest}"

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROFILE="${SCRIPT_DIR}/debug-profile.yaml"

  # Create security-compliant debug profile
  cat >"$PROFILE" <<'EOF'
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

  echo "======================================"
  echo " Creating ephemeral debug container"
  echo "======================================"
  echo "Pod       : $POD"
  echo "Namespace : $NAMESPACE"
  echo "Target    : ${TARGET:-not specified}"
  echo "Image     : $IMAGE"
  echo "Profile   : $PROFILE"
  echo "======================================"

  ARGS=(
    debug
    -it
    "$POD"
    -n "$NAMESPACE"
    "--image=$IMAGE"
    "--custom=$PROFILE"
  )

  if [[ -n "$TARGET" ]]; then
    ARGS+=("--target=$TARGET")
  fi

  ARGS+=(-- sh)

  kubectl "${ARGS[@]}"
)$()
