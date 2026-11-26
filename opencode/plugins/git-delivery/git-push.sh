#!/usr/bin/env bash
# Preview and push only the current branch to its configured upstream.
set -euo pipefail

die() {
  local level='[ERROR]'
  if [[ -t 2 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
    level=$'\033[31m[ERROR]\033[0m'
  fi
  printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$*" >&2
  exit 1
}

push_branch() {
  git -c "remote.$remote.mirror=false" push --no-follow-tags --recurse-submodules=no \
    --porcelain "$@" -- "$remote" "$branch:$target"
}

inspect_push() {
  local output
  if ! output=$(LC_ALL=C push_branch --dry-run --no-verify); then
    printf '%s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output"
}

outgoing_commits() {
  local plan=$1 flag ref summary destination='' base range count
  local seen=false limit=50
  while IFS=$'\t' read -r flag ref summary; do
    if [[ $flag == 'To '* ]]; then
      destination=${flag#To }
      continue
    fi
    [[ $ref == "$branch:$target" ]] || continue
    seen=true
    case $flag in
      =) continue ;;
      ' ')
        [[ $summary =~ ^([[:xdigit:]]+)\.\.[[:xdigit:]]+$ ]] ||
          die 'Could not read the upstream commit from the push preview.'
        base=$(git rev-parse --disambiguate="${BASH_REMATCH[1]}")
        [[ $base =~ ^[[:xdigit:]]+$ ]] || die 'Could not resolve the upstream commit locally.'
        range="$base..$head"
        printf '\nTo %s\n' "$destination"
        ;;
      '*')
        range=$head
        printf '\nTo %s (new upstream branch)\n' "$destination"
        ;;
      *) die 'Git reported an unexpected status for the upstream branch.' ;;
    esac

    count=$(git rev-list --count "$range" --)
    if ((count > limit)); then
      printf 'Commits: %s (showing latest %s)\n' "$count" "$limit"
    else
      printf 'Commits: %s\n' "$count"
    fi
    git --no-pager log --no-color --no-show-signature --no-notes --no-decorate \
      --max-count="$limit" --format='%h %<(120,trunc)%s' "$range" -- | sed 's/[[:blank:]]*$//'
  done <<< "$plan"
  [[ $seen == true ]] || die 'Git did not report a status for the upstream branch.'
}

main() {
  local action=${1:-} branch head upstream remote target plan fingerprint commits
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
      ;;
    push)
      [[ $# -eq 6 ]] || die 'Expected push <branch-ref> <head> <remote> <target-ref> <preview-fingerprint>.'
      if [[ $branch != "$2" || $head != "$3" || $remote != "$4" || $target != "$5" ]]; then
        die 'The branch, tip, or upstream changed. Run /git-push again.'
      fi
      ;;
    *) die 'Expected preview or push.' ;;
  esac

  plan=$(inspect_push)
  fingerprint=$(printf '%s\n' "$plan" | git hash-object --stdin)
  if [[ $action == preview ]]; then
    commits=$(outgoing_commits "$plan")
    printf '%s\n' "$branch" "$head" "$remote" "$target" "$fingerprint" "$commits"
    return
  fi

  if [[ $fingerprint != "$6" || $(git symbolic-ref -q HEAD) != "$branch" || $(git rev-parse -q --verify HEAD) != "$head" ]]; then
    die 'The local or remote branch changed after the preview. Run /git-push again.'
  fi
  LC_ALL=C push_branch
}

main "$@"
