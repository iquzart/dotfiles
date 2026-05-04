#!/usr/bin/env bash

set -euo pipefail

# Ask for CIDR mask
read -p "Enter Service CIDR netmask (e.g. 24 for /24): " MASK

# Validate input
if ! [[ "$MASK" =~ ^[0-9]+$ ]] || [ "$MASK" -lt 0 ] || [ "$MASK" -gt 32 ]; then
  echo "Invalid netmask. Please enter a value between 0 and 32."
  exit 1
fi

# Calculate total IPs
TOTAL=$((2 ** (32 - MASK)))

# Get all services (ALL namespaces)
JSON=$(kubectl get svc -A -o json)

# Total used ClusterIPs (excluding headless)
USED=$(echo "$JSON" | jq '[.items[] | select(.spec.type=="ClusterIP" and .spec.clusterIP != "None")] | length')

echo ""
echo "Namespace | Count"
echo "----------------------"

# Per-namespace counts
echo "$JSON" | jq -r '
  .items[]
  | select(.spec.type=="ClusterIP" and .spec.clusterIP != "None")
  | .metadata.namespace
' | sort | uniq -c | awk '{printf "%-20s | %s\n", $2, $1}'

echo "----------------------"
echo "Total Used | $USED"
echo "Total IPs  | $TOTAL"
echo "Remaining  | $((TOTAL - USED))"
echo "CIDR       | /$MASK"
