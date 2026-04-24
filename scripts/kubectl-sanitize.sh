#!/usr/bin/env bash

set -e

NAMESPACE="$1"

delete_pods() {
  local NS="$1"

  echo "Current namespace: $NS"
  echo
  echo "Pods to be deleted:"
  echo "-------------------"

  PODS=$(kubectl get pods -n "$NS" -o json |
    jq -r '
      .items[]
      | select(
          .status.phase == "Unknown"
          or (
            (.status.containerStatuses // [])
            | any(
                .state.waiting.reason == "ContainerStatusUnknown"
                or .state.terminated.reason == "Error"
                or .ready == false
              )
          )
        )
      | .metadata.name
    ')

  if [[ -z "$PODS" ]]; then
    echo "No pods found with status Error or ContainerStatusUnknown."
    exit 0
  fi

  echo "$PODS"
  echo
  read -p "Do you want to delete these pods? (y/N): " CONFIRM

  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "$PODS" | xargs kubectl delete pod -n "$NS"
    echo "Deletion completed."
    return 0
  else
    echo "Aborted."
    return 1
  fi

}

if [[ -n "$NAMESPACE" ]]; then
  delete_pods "$NAMESPACE"
else
  CURRENT_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
  echo "No namespace provided."
  delete_pods "$CURRENT_NS"
fi
