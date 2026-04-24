#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Name:    list-acr-images.sh
# Purpose: Azure Container Registry repo and tag management
# Usage:   list-acr-images.sh <list-repos|list-tags|check-tag>
# Depends: curl, jq
# Vars:    ACR_NAME, ACR_USERNAME, ACR_PASSWORD
# =============================================================

# -------- colors --------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

DIVIDER="========================================"
SEPARATOR="----------------------------------------"

# -------- colored output helpers --------
info() { echo -e "${CYAN}$*${RESET}"; }
success() { echo -e "${GREEN}$*${RESET}"; }
warn() { echo -e "${YELLOW}$*${RESET}"; }
error() { echo -e "${RED}$*${RESET}"; }
bold() { echo -e "${BOLD}$*${RESET}"; }

usage() {
  cat <<EOF
Usage:
  $(basename "$0") list-repos              List all repositories
  $(basename "$0") list-tags               List all repositories with tags
  $(basename "$0") check-tag <image> <tag> Check if a specific tag exists for an image

Environment variables required:
  ACR_NAME      Azure Container Registry name
  ACR_USERNAME  ACR username
  ACR_PASSWORD  ACR password

Examples:
  $(basename "$0") list-repos
  $(basename "$0") list-tags
  $(basename "$0") check-tag myapp/backend latest
EOF
  exit 1
}

preflight() {
  for var in ACR_NAME ACR_USERNAME ACR_PASSWORD; do
    if [[ -z "${!var:-}" ]]; then
      error "ERROR: Environment variable '$var' is not set."
      exit 1
    fi
  done
  if ! command -v jq &>/dev/null; then
    error "ERROR: jq is not installed."
    exit 1
  fi
}

# -------- helpers --------
get_token() {
  local scope="$1"
  curl -s -u "$ACR_USERNAME:$ACR_PASSWORD" \
    "https://$LOGIN_SERVER/oauth2/token?service=$LOGIN_SERVER&scope=$scope" |
    jq -r .access_token
}

get_repos() {
  local token
  token=$(get_token "registry:catalog:*")
  curl -s -H "Authorization: Bearer $token" \
    "https://$LOGIN_SERVER/v2/_catalog" | jq -r '.repositories[]? // empty'
}

get_tags() {
  local repo="$1"
  local token
  token=$(get_token "repository:$repo:pull")
  curl -s -H "Authorization: Bearer $token" \
    "https://$LOGIN_SERVER/v2/$repo/tags/list" | jq -r '.tags[]? // empty' || true
}

print_header() {
  echo
  bold "$DIVIDER"
  bold "  ACR: $LOGIN_SERVER"
  bold "$DIVIDER"
}

# -------- commands --------
cmd_list_repos() {
  print_header
  info "  Fetching repositories..."
  bold "$DIVIDER"

  local repos
  repos=$(get_repos)

  if [[ -z "$repos" ]]; then
    warn "  (no repositories found)"
  else
    local count=0
    while IFS= read -r repo; do
      echo -e "  ${CYAN}$LOGIN_SERVER/${RESET}${GREEN}${repo}${RESET}"
      count=$((count + 1))
    done <<<"$repos"
    bold "$DIVIDER"
    success "  Total: $count repositories"
  fi
  bold "$DIVIDER"
}

cmd_list_tags() {
  print_header
  info "  Fetching repositories and tags..."

  local repos
  repos=$(get_repos)

  if [[ -z "$repos" ]]; then
    warn "  (no repositories found)"
    return
  fi

  local total_repos=0
  while IFS= read -r repo; do
    echo
    bold "$SEPARATOR"
    echo -e "  ${BOLD}Repo :${RESET} ${CYAN}$LOGIN_SERVER/${RESET}${GREEN}${repo}${RESET}"
    bold "$SEPARATOR"

    local tags
    local tag_count=0
    tags=$(get_tags "$repo")

    if [[ -z "$tags" ]]; then
      warn "  (no tags or no permission)"
    else
      while IFS= read -r tag; do
        echo -e "  ${CYAN}$LOGIN_SERVER/${repo}:${RESET}${GREEN}${tag}${RESET}"
        tag_count=$((tag_count + 1))
      done <<<"$tags"
      info "  Total: $tag_count tag(s)"
    fi

    total_repos=$((total_repos + 1))
  done <<<"$repos"

  echo
  bold "$DIVIDER"
  success "  Total repositories: $total_repos"
  success "  Completed"
  bold "$DIVIDER"
}

cmd_check_tag() {
  local image="${1:-}"
  local tag="${2:-}"

  if [[ -z "$image" || -z "$tag" ]]; then
    error "ERROR: check-tag requires <image> and <tag> arguments."
    usage
  fi

  print_header
  info "  Checking: $LOGIN_SERVER/${image}:${tag}"
  bold "$DIVIDER"

  local tags
  tags=$(get_tags "$image")

  if echo "$tags" | grep -qx "$tag"; then
    success "  ✓ Tag found:     $LOGIN_SERVER/${image}:${tag}"
  else
    error "  ✗ Tag NOT found: $LOGIN_SERVER/${image}:${tag}"
    echo
    warn "  Available tags:"
    if [[ -z "$tags" ]]; then
      warn "    (none)"
    else
      while IFS= read -r t; do
        echo -e "  ${YELLOW}  - ${t}${RESET}"
      done <<<"$tags"
    fi
  fi
  bold "$DIVIDER"
}

# -------- entrypoint --------
preflight
LOGIN_SERVER="${ACR_NAME}.azurecr.io"

case "${1:-}" in
list-repos) cmd_list_repos ;;
list-tags) cmd_list_tags ;;
check-tag) cmd_check_tag "${2:-}" "${3:-}" ;;
*) usage ;;
esac
