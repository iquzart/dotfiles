#!/bin/bash
#
# Grant access to Github
#
set -e

REPO="$1"       # Format: owner/repo
USERNAME="$2"   # GitHub username
PERMISSION="$3" # pull | triage | push | maintain | admin

if [[ -z "$REPO" || -z "$USERNAME" || -z "$PERMISSION" ]]; then
  echo "Usage: $0 <owner/repo> <username> <permission>"
  echo "Permissions: pull, triage, push, maintain, admin"
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "❌ GITHUB_TOKEN is not set. Export it before running this script."
  echo "Example: export GITHUB_TOKEN=ghp_xxxxxxxxxxxxx"
  exit 1
fi

valid_permissions=("pull" "triage" "push" "maintain" "admin")
if ! echo "${valid_permissions[@]}" | grep -q -w "$PERMISSION"; then
  echo "❌ Invalid permission: $PERMISSION"
  echo "Valid permissions: ${valid_permissions[*]}"
  exit 1
fi

echo "Granting '$PERMISSION' access to user '$USERNAME' on repo '$REPO'..."

api_response=$(curl -s -w "\n%{http_code}" \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/collaborators/$USERNAME" \
  -d "{\"permission\":\"$PERMISSION\"}")

status_code=$(echo "$api_response" | tail -n1)
response_body=$(echo "$api_response" | sed '$d')

if [[ "$status_code" == "201" || "$status_code" == "204" ]]; then
  echo "✅ Access granted successfully to $USERNAME on $REPO with $PERMISSION permission."
else
  echo "❌ Failed to grant access. Status code: $status_code"
  echo "Response:"

  if command -v jq &>/dev/null; then
    echo "$response_body" | jq . || echo "$response_body"
  else
    echo "$response_body"
  fi
fi
