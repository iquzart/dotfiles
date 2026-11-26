#!/usr/bin/env bash
# Preview the Git index and commit it with the GitHub Delivery subject format.
set -euo pipefail

die() {
  local level='[ERROR]'
  if [[ -t 2 && ${TERM:-dumb} != dumb && ! ${NO_COLOR+x} ]]; then
    level=$'\033[31m[ERROR]\033[0m'
  fi
  printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$*" >&2
  exit 1
}

check_repository() {
  local state
  git rev-parse --show-toplevel > /dev/null || die 'Run this in a Git working tree.'
  branch=$(git symbolic-ref --quiet HEAD) || die 'Check out a branch before committing.'
  branch=${branch#refs/heads/}
  head=$(git rev-parse --verify --quiet HEAD || printf '%s' '-')

  for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-apply rebase-merge sequencer; do
    if [[ -e $(git rev-parse --git-path "$state") ]]; then
      die 'Finish the Git operation already in progress before using /git-commit.'
    fi
  done
}

prepare() {
  local base tree
  case ${1:-} in
    '')
      [[ $# -eq 0 ]] || die 'Use /git-commit, /git-commit --all, or /git-commit -- <paths>.'
      ;;
    --all)
      [[ $# -eq 1 ]] || die '--all cannot be combined with paths.'
      git add --all
      ;;
    --)
      shift
      [[ $# -gt 0 ]] || die 'Specify at least one path to stage.'
      git diff --cached --quiet --no-ext-diff --ignore-submodules=none ||
        die 'The index already has changes. Run /git-commit to commit those first.'
      git --literal-pathspecs add -- "$@"
      ;;
    *) die 'Use /git-commit, /git-commit --all, or /git-commit -- <paths>.' ;;
  esac

  tree=$(git write-tree)
  if [[ $head == - ]]; then
    base=$(git hash-object -t tree -w --stdin < /dev/null)
  else
    base=$(git rev-parse "$head^{tree}")
  fi
  if [[ $base == "$tree" ]]; then
    printf 'Nothing staged. Use /git-commit -- <paths> or /git-commit --all to stage and commit changes.\n'
    git status --porcelain=v1 --untracked-files=all | sed -n '1,30p;31s/.*/(more paths omitted)/p'
    return 2
  fi

  printf '%s\n' "$branch" "$head" "$tree"
  git -c core.quotePath=true diff --no-color --no-relative --no-ext-diff --no-textconv --ignore-submodules=none \
    --stat=100,65,24 --compact-summary "$base" "$tree"
  if [[ $head != - ]]; then
    printf '\nRecent subjects (style examples):\n'
    git log -3 --no-show-signature --no-notes --format='%<(90,trunc)%s' "$head"
  fi
}

format_message() {
  local subject=$1
  local ticket_pattern='^(SRE-[0-9]+)_'
  local subject_ticket_pattern='^\[SRE-[0-9]+\]'
  local opencode_marker='\[[Oo][Pp][Ee][Nn][Cc][Oo][Dd][Ee]\]'
  if [[ $subject =~ [[:cntrl:]] ]]; then
    die 'Expected a plain, single-line commit description of at most 120 characters.'
  fi
  if [[ $subject =~ $opencode_marker ]]; then
    subject=$(printf '%s\n' "$subject" | sed "s/$opencode_marker/ /g; s/  */ /g; s/^ //; s/ $//")
  fi
  if [[ ! $subject =~ [^[:space:]] || ${#subject} -gt 120 ||
    $subject == *'[AI-generated]'* || $subject == *'[agent:'* || $subject =~ $subject_ticket_pattern ]]; then
    die 'Expected a plain, single-line commit description of at most 120 characters.'
  fi
  if [[ $branch =~ $ticket_pattern ]]; then
    printf '[%s] %s [AI-generated]\n' "${BASH_REMATCH[1]}" "$subject"
  else
    printf '[AI-generated] %s\n' "$subject"
  fi
}

main() {
  local branch head action=${1:-} tree message
  [[ $# -gt 0 ]] || die 'Expected prepare, message, or commit.'
  shift
  check_repository
  case $action in
    prepare) prepare "$@" ;;
    message | commit)
      [[ $# -eq 4 ]] || die "Expected $action <branch> <head> <tree> <subject>."
      tree=$(git write-tree)
      if [[ $branch != "$1" || $head != "$2" || $tree != "$3" ]]; then
        die 'The branch, HEAD, or staged changes changed. Run /git-commit again.'
      fi
      message=$(format_message "$4")
      if [[ $action == message ]]; then
        printf '%s\n' "$message"
      else
        git commit --cleanup=verbatim -m "$message"
      fi
      ;;
    *) die 'Expected prepare, message, or commit.' ;;
  esac
}

main "$@"
