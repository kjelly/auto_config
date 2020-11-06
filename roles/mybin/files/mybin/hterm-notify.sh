#!/bin/sh
# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# Write an error message and exit.
# Usage: <message>
if [ -z $HTERM_TTY ]
then
  HTERM_TTY=$(tty)
fi
die() {
  echo "ERROR: $*"
  exit 1
}
# Send a DCS sequence through tmux.
# Usage: <sequence>
tmux_dcs() {
  printf '\033Ptmux;\033%s\033\\' "$1" > $HTERM_TTY
}
# Send a DCS sequence through screen.
# Usage: <sequence>
screen_dcs() {
  printf '\033P\033%s\033\\' "$1" > $HTERM_TTY
}
# Send an escape sequence to hterm.
# Usage: <sequence>
print_seq() {
  local seq="$1"
  case ${TERM-} in
  screen*)
    # Since tmux defaults to setting TERM=screen (ugh), we need to detect
    # it here specially.
    if [ -n "${TMUX-}" ]; then
      tmux_dcs "${seq}"
    else
      tmux_dcs "${seq}" > $HTERM_TTY
      #screen_dcs "${seq}"
    fi
    ;;
  tmux*)
    tmux_dcs "${seq}"
    ;;
  *)
    if [ -z $HTERM_TTY ]
    then
      echo "${seq}"
    else
      tmux_dcs "${seq}"
    fi

    ;;
  esac
}
# Send a notification.
# Usage: [title] [body]
notify() {
  local title="${1-}" body="${2-}"
  title="$(whoami)@$(hostname): ${title}"
  print_seq "$(printf '\033]777;notify;%s;%s\a' "${title}" "${body}")"
}
# Write tool usage and exit.
# Usage: [error message]
usage() {
  if [ $# -gt 0 ]; then
    exec 1>&2
  fi
  cat <<EOF
Usage: hterm-notify [options] <title> [body]
Send a notification to hterm.
Notes:
- The title should not have a semi-colon in it.
- Neither field should have escape sequences in them.
  Best to stick to plain text.
EOF
  if [ $# -gt 0 ]; then
    echo
    die "$@"
  else
    exit 0
  fi
}
main() {
  set -e
  while [ $# -gt 0 ]; do
    case $1 in
    -h|--help)
      usage
      ;;
    -*)
      usage "Unknown option: $1"
      ;;
    *)
      break
      ;;
    esac
  done
  if [ $# -eq 0 ]; then
    die "Missing message to send"
  fi
  if [ $# -gt 2 ]; then
    usage "Too many arguments"
  fi
  notify "$@"
}
main "$@"
