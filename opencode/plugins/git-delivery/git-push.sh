#!/usr/bin/env bash
# Push only the current branch to its configured upstream.
set -euo pipefail

die() {
  local level='[ERROR]'
  if [[ -t 2 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
    level=$'\033[31m[ERROR]\033[0m'
  fi
  printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$*" >&2
  exit 1
}

main() {
  local action=${1:-} branch head upstream remote target
  git rev-parse --show-toplevel > /dev/null || die 'Run this in a Git working tree.'
  branch=$(git symbolic-ref --quiet HEAD) || die 'Check out a branch before pushing.'
  head=$(git rev-parse --verify --quiet "$branch") || die 'Commit changes before pushing this branch.'
  upstream=$(git for-each-ref --format='%(upstream:remotename)%09%(upstream:remoteref)' "$branch")
  IFS=$'\t' read -r remote target <<< "$upstream"
  if [[ -z $remote || $target != refs/heads/* ]]; then
    die "Branch ${branch#refs/heads/} has no configured upstream branch."
  fi

  case $action in
    preview)
      [[ $# -eq 1 ]] || die 'Unexpected arguments to preview.'
      printf '%s\n' "$branch" "$head" "$remote" "$target"
      ;;
    push)
      [[ $# -eq 5 ]] || die 'Expected push <branch-ref> <head> <remote> <target-ref>.'
      if [[ $branch != "$2" || $head != "$3" || $remote != "$4" || $target != "$5" ]]; then
        die 'The branch, tip, or upstream changed. Run /git-push again.'
      fi
      exec git -c "remote.$remote.mirror=false" push --no-follow-tags --recurse-submodules=no \
        --porcelain -- "$remote" "$branch:$target" 2>&1
      ;;
    *) die 'Expected preview or push.' ;;
  esac
}

main "$@"
