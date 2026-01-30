#!/bin/bash

#
# Export all JFrog Xray configuration for documentation/backup.
# Outputs JSON files into ./xray-export
#

set -e

# ------------------------------
# CONFIG
# ------------------------------
XRAY_URL="${XRAY_URL:-https://your-jfrog-url/xray}"
XRAY_TOKEN="${XRAY_TOKEN:-YOUR_ACCESS_TOKEN}"

OUT_DIR="xray-export"
mkdir -p "$OUT_DIR"

HEADER="Authorization: Bearer $XRAY_TOKEN"

echo "🔍 Exporting JFrog Xray Configurations..."
echo "Output directory: $OUT_DIR"
echo "Using Xray URL: $XRAY_URL"
echo ""

# ------------------------------
# Function to GET and save files
# ------------------------------
fetch() {
  local endpoint="$1"
  local outfile="$2"

  echo "==> Fetching $endpoint ..."
  curl -s -X GET "$XRAY_URL$endpoint" -H "$HEADER" | jq . >"$OUT_DIR/$outfile"
  echo "   Saved to $OUT_DIR/$outfile"
}

# ------------------------------
# EXPORT DATA
# ------------------------------

# 1. Policies
fetch "/api/v2/policies" "policies.json"

# Fetch each policy individually
echo "==>  Fetching individual policies..."
jq -r '.[].name' "$OUT_DIR/policies.json" | while read -r policy; do
  fetch "/api/v2/policies/$policy" "policy_${policy}.json"
done

# 2. Watches
fetch "/api/v2/watches" "watches.json"

# Fetch each watch individually
echo "==>  Fetching individual watches..."
jq -r '.[].name' "$OUT_DIR/watches.json" | while read -r watch; do
  fetch "/api/v2/watches/$watch" "watch_${watch}.json"
done

# 3. Reports
fetch "/api/v1/reports" "reports.json"

echo "==>  Fetching individual reports..."
jq -r '.reports[].id // empty' "$OUT_DIR/reports.json" | while read -r id; do
  fetch "/api/v1/reports/$id" "report_${id}.json"
done

# 4. Xray General Configuration
fetch "/api/v1/configuration" "xray_configuration.json"

# 5. Indexed Repositories
fetch "/api/v1/binMgr/default/repos" "repos_indexed.json"

# 6. Build Indexing
fetch "/api/v1/binMgr/default/builds" "builds_indexed.json"

# 7. System Info
fetch "/api/v1/system/version" "system_version.json"

echo ""
echo "==> Export Complete!"
echo "Files stored in: $OUT_DIR"
