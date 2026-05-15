#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <primary-context> <dr-context> <namespace>" >&2
  exit 1
fi

PRIMARY_CTX="$1"
DR_CTX="$2"
NS="$3"

WORKDIR="./compare-ns-${NS}"
mkdir -p "$WORKDIR"
mkdir -p "$WORKDIR/diffs"

normalize_resources() {
  jq '
    del(
      .metadata,
      .items[].metadata.managedFields,
      .items[].metadata.resourceVersion,
      .items[].metadata.uid,
      .items[].metadata.creationTimestamp,
      .items[].metadata.generation,
      .items[].status,
      .items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
      .items[].metadata.annotations."deployment.kubernetes.io/revision"
    )
    | .items |= map(
        select(.type != "kubernetes.io/service-account-token")
        | select(
            if .kind == "Secret" then
              ((.metadata.name // "") | startswith("sh.helm.release") | not)
              and ((.metadata.name // "") | endswith("-tls") | not)
            elif .kind == "ConfigMap" then
              ((.metadata.name // "") != "kube-root-ca.crt")
              and ((.metadata.name // "") != "istio-ca-root-cert")
            else
              true
            end
          )
        | if (.kind == "ConfigMap" or .kind == "Secret") then
            {
              kind: .kind,
              metadata: {name: .metadata.name},
              data: (.data // {})
            }
          elif .kind == "Deployment" then
            (
              del(.. | .labels?, .. | .annotations?)
              | {
                  kind: .kind,
                  metadata: {name: .metadata.name},
                  spec: .spec
                }
            )
          else
            .
          end
      )
    | .items |= sort_by(.kind, .metadata.name)
  '
}

echo "Exporting from PRIMARY cluster..."
kubectl --context "$PRIMARY_CTX" get deploy,cm,secret -n "$NS" -o json |
  normalize_resources >"$WORKDIR/primary.json"

echo "Exporting from DR cluster..."
kubectl --context "$DR_CTX" get deploy,cm,secret -n "$NS" -o json |
  normalize_resources >"$WORKDIR/dr.json"

echo "Comparing..."

mapfile -t RESOURCES < <(
  jq -r '.items[] | "\(.kind)/\(.metadata.name)"' \
    "$WORKDIR/primary.json" "$WORKDIR/dr.json" | sort -u
)

DIFF_COUNT=0
DIFF_NAMES=()
>"$WORKDIR/diff.txt"

for resource in "${RESOURCES[@]}"; do
  kind="${resource%%/*}"
  name="${resource#*/}"

  primary_resource_json="$(jq -S --arg k "$kind" --arg n "$name" '
    [ .items[] | select(.kind == $k and .metadata.name == $n) ][0] // null
  ' "$WORKDIR/primary.json")"

  dr_resource_json="$(jq -S --arg k "$kind" --arg n "$name" '
    [ .items[] | select(.kind == $k and .metadata.name == $n) ][0] // null
  ' "$WORKDIR/dr.json")"

  safe_name="$(printf '%s__%s' "$kind" "$name" | tr -cs 'a-zA-Z0-9._-' '_')"
  resource_diff_file="$WORKDIR/diffs/${safe_name}.diff"

  if ! diff -u \
    <(printf '%s\n' "$primary_resource_json") \
    <(printf '%s\n' "$dr_resource_json") \
    >"$resource_diff_file"; then
    DIFF_COUNT=$((DIFF_COUNT + 1))
    DIFF_NAMES+=("$resource")

    {
      printf '### %s\n' "$resource"
      cat "$resource_diff_file"
      printf '\n'
    } >>"$WORKDIR/diff.txt"
  else
    rm -f "$resource_diff_file"
  fi
done

if [ "$DIFF_COUNT" -eq 0 ]; then
  echo "Clusters are identical for Deployments/ConfigMaps/Secrets"
else
  echo "Differences found in $DIFF_COUNT resource(s)"
  echo "Summary (resource names):"
  printf ' - %s\n' "${DIFF_NAMES[@]}"
  echo
  echo "Detailed diff: $WORKDIR/diff.txt"
  cat "$WORKDIR/diff.txt"
fi
