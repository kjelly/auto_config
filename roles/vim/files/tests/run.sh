#!/usr/bin/env bash
set -euo pipefail
nvim_test_dir=$(mktemp -d /tmp/nvim-regression.XXXXXX)
trap 'rm -rf "$nvim_test_dir"' EXIT
nvim_config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for nvim_test_suite in regression gamepad; do
  XDG_STATE_HOME="$nvim_test_dir/state" XDG_CACHE_HOME="$nvim_test_dir/cache" \
    nvim --headless -n -i NONE -u NONE -l "$nvim_config_dir/tests/$nvim_test_suite.lua"
done
