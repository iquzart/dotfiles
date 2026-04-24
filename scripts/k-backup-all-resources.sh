#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="$1"
OUTDIR="$2"

if [[ -z "$NAMESPACE" || -z "$OUTDIR" ]]; then
  echo "Usage: $0 <namespace> <output-directory>"
  exit 1
fi

mkdir -p "$OUTDIR"

# Get all resource types that are namespaced
RESOURCE_TYPES=$(kubectl api-resources --namespaced=true -o name)

echo "Backing up namespace '$NAMESPACE' to '$OUTDIR'..."

for RT in $RESOURCE_TYPES; do
  echo "Processing resource type: $RT"

  # Get all resource names for this type
  ITEMS=$(kubectl get "$RT" -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' || true)

  if [[ -z "$ITEMS" ]]; then
    continue
  fi

  for ITEM in $ITEMS; do
    FILE="$OUTDIR/${RT}__${ITEM}.yaml"
    echo "  Saving $RT/$ITEM → $FILE"
    kubectl get "$RT" "$ITEM" -n "$NAMESPACE" -o yaml >"$FILE"
  done
done

echo "Backup completed."
