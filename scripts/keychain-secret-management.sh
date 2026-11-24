#!/usr/bin/env bash
# Create and read exact generic passwords in the default macOS Keychain.
set +x
set +a
set -euo pipefail
# Don't inherit an export attribute for any variable that may hold a secret.
unset -v secret byte hex reply escapes

usage() {
  builtin printf '%s\n' \
    'Usage: keychain-secret-management.sh --add NAME | --get NAME | --help' \
    'Use a bare NAME. Entries use service custom-secret-NAME and a fixed account.' \
    '--add prompts for a password and never replaces an entry.' \
    '--get writes the exact value without adding a newline.'
}

fail() {
  builtin printf 'ERROR: %s\n' "$1" >&2
  exit "${2:-1}"
}

restore_tty() {
  /bin/stty "$tty_mode"
}

read_secret() {
  local byte problem='' complete=no tty_mode
  secret=''
  # Noncanonical input prevents the tty from truncating long pasted tokens.
  tty_mode=$(/bin/stty -g) || fail 'Cannot read terminal settings.'
  trap restore_tty EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
  /bin/stty -echo -icanon min 1 time 0 || fail 'Cannot disable terminal echo.'
  builtin printf 'Enter password/token: ' >&2
  while IFS= builtin read -r -n 1 -d '' byte; do
    case $byte in
      $'\n'|$'\r') complete=yes; break ;;
      $'\004') break ;; # Ctrl-D in noncanonical mode
      '') problem='Password cannot contain a NUL byte.' ;;
      $'\177'|$'\b')
        if [[ -n $secret && -z $problem ]]; then
          byte=${secret: -1}
          secret=${secret%?}
          while [[ $byte == [$'\200'-$'\277'] && -n $secret ]]; do
            byte=${secret: -1}
            secret=${secret%?}
          done
        fi ;;
      *)
        [[ -z $problem ]] || continue
        if [[ $byte == [[:cntrl:]] && $byte != $'\t' ]]; then
          problem='Password contains an unsupported control character.'
        elif ((${#secret} >= $1)); then
          problem='Password is too long for the macOS security command.'
        else
          secret+=$byte
        fi ;;
    esac
  done
  builtin printf '\n' >&2
  [[ $complete == yes ]] || fail 'Password input ended before Enter.'
  [[ -z $problem ]] || fail "$problem"
  [[ -n $secret ]] || fail 'Password cannot be empty.'
  restore_tty || fail 'Cannot restore terminal settings.'
  trap - EXIT INT TERM HUP
}

add_secret() {
  local quoted prefix limit secret hex reply
  [[ -t 0 ]] || fail 'Run --add from an interactive terminal.'
  quoted=${service//\\/\\\\}
  quoted=${quoted//\"/\\\"}
  prefix="add-generic-password -a \"$account\" -s \"$quoted\" -X "
  # security -i's 4,096-byte line buffer must have room for both LF and NUL.
  limit=$(((4094 - ${#prefix}) / 2))
  ((limit > 0)) || fail 'Name is too long.'
  read_secret "$limit"
  hex=$(builtin printf '%s' "$secret" | /usr/bin/od -An -v -tx1) ||
    fail 'Cannot encode the password.'
  unset -v secret
  hex=${hex//[[:space:]]/}
  [[ -n $hex && $hex != *[![:xdigit:]]* ]] &&
    ((${#prefix} + ${#hex} <= 4094)) || fail 'Invalid password encoding or length.'

  # Require an acknowledgement and no diagnostics; the add's OSStatus alone
  # is not reliably reflected in security -i's final process exit status.
  if reply=$(
    builtin printf '%s%s\nhelp help\n' "$prefix" "$hex" | /usr/bin/security -i 2>&1 &&
      builtin printf '.'
  ) && [[ $reply == $'Usage: help [command ...]\n.' ]]; then
    builtin printf 'SUCCESS: Secret created in the default macOS Keychain.\n'
  elif [[ $'\n'$reply$'\n' == *$'\nadd-generic-password: returned -25299\n'* ]]; then
    fail 'This entry already exists in the default Keychain. Nothing was overwritten.'
  else
    fail 'Could not confirm creation in the default Keychain. Check it before retrying.'
  fi
}

default_keychain() {
  local reply status
  if reply=$(/usr/bin/security default-keychain 2>&1 && builtin printf '.'); then
    # Apple prints one unescaped path, enclosed in quotes and indented.
    local format='^    "(/[^[:cntrl:]]+)"'$'\n''\.$'
    [[ $reply =~ $format ]] || fail 'Could not identify the default Keychain path.'
    builtin printf '%s' "${BASH_REMATCH[1]}"
  else
    status=$?
    fail 'Could not read the default Keychain.' "$status"
  fi
}

get_secret() {
  local path reply status hex escapes=''
  path=$(default_keychain) || exit "$?"
  # With ONE path, security can substitute the search list when the open
  # fails. With TWO it uses an explicit array, even if no path opens.
  # Passing the same absolute path twice confines both attempts to it.
  if reply=$(
    /usr/bin/security find-generic-password -a "$account" -s "$service" -g -- \
      "$path" "$path" 2>&1 >/dev/null && builtin printf '.'
  ); then
    [[ $reply == 'password: '*$'\n.' ]] || fail 'Unexpected Keychain response.'
  else
    status=$?
    fail "No secret returned from the default Keychain (security exit $status)." "$status"
  fi
  reply=${reply#password: }
  reply=${reply%$'\n.'}
  [[ $reply != *[![:print:]]* ]] || fail 'Unexpected Keychain response.'

  # Unlike -w (untagged hex for nonprintable bytes), -g labels hex with 0x
  # and quotes plain ASCII. It may append a display copy to the hex.
  case $reply in
    '') return 0 ;;
    \"*\")
      reply=${reply:1:${#reply}-2}
      [[ $reply != *\\* ]] || fail 'Unexpected Keychain response.'
      builtin printf '%s' "$reply" ;;
    0x*)
      hex=${reply#0x}
      hex=${hex%% *}
      [[ -n $hex && $hex != *[![:xdigit:]]* ]] &&
        ((${#hex} % 2 == 0)) || fail 'Unexpected Keychain response.'
      case ${reply#"0x$hex"} in
        ' '|'  "'*'"') ;;
        *) fail 'Unexpected Keychain response.' ;;
      esac
      while [[ -n $hex ]]; do
        escapes+="\\x${hex:0:2}"
        hex=${hex:2}
      done
      builtin printf '%b' "$escapes" ;;
    *) fail 'Unexpected Keychain response.' ;;
  esac
}

main() {
  local LC_ALL=C service account=custom-secret-management
  if [[ $# == 1 && $1 == --help ]]; then
    usage
    return
  fi
  [[ $# == 2 && ( $1 == --add || $1 == --get ) ]] || { usage >&2; exit 2; }
  [[ -n $2 && $2 != custom-secret-* ]] || fail 'Provide a nonempty bare name without the custom-secret- prefix.' 2
  [[ ${2//$'\t'/} != *[[:cntrl:]]* ]] || fail 'Name contains an unsupported control character.' 2
  [[ $OSTYPE == darwin* ]] || fail 'This command requires macOS.'
  ulimit -c 0 || fail 'Cannot disable core dumps.'
  service="custom-secret-$2"
  case $1 in
    --add) add_secret ;;
    --get) get_secret ;;
  esac
}

main "$@"
