#!/usr/bin/env bash
#===============================================================================
# Script Name : helm-values-get-images.sh
# Description : Extracts service name, image repository, and tag from Helm
#               values files and displays them in a tabular format.
# Usage       : ./helm-values-get-images.sh <values.yaml>
#===============================================================================

set -euo pipefail

VALUES_FILE="${1:-values.yaml}"

if [[ ! -f "$VALUES_FILE" ]]; then
  echo "Usage: $0 <values.yaml>"
  exit 1
fi

# Print header
printf "%-25s %-60s %-20s\n" "ServiceName" "ImageRepository" "Tag"
printf "%-25s %-60s %-20s\n" "-----------" "----------------" "---"

# Extract and format data from YAML
awk '
  /^[[:alnum:]_-]+:$/ { service=$1; sub(":", "", service) }
  /repository:/ { repo=$2 }
  /tag:/ {
    tag=$2
    gsub("\"", "", repo)
    gsub("\"", "", tag)
    if (service && repo && tag)
      printf "%-25s %-60s %-20s\n", service, repo, tag
  }
' "$VALUES_FILE"
