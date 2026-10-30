#!/bin/bash
# Stand-in for the in-tree "mar" host tool, used by
# tools/update-packaging/make_full_update.sh. Creates the MAR with the Python
# "mar" package and signs it with the key in $MAR_SIGNING_KEY_FILE.
# That tool resolves "-c <file>" before applying "-C <dir>", so a relative
# output path is rewritten to be relative to the -C directory.
set -euo pipefail

: "${MAR_TOOL:?MAR_TOOL must point to the Python mar executable}"
: "${MAR_SIGNING_KEY_FILE:?MAR_SIGNING_KEY_FILE must point to a PEM private key}"

chdir=""
prev=""
for arg in "$@"; do
  if [ "$prev" = "-C" ]; then
    chdir="$arg"
  fi
  prev="$arg"
done

args=()
prev=""
for arg in "$@"; do
  if [ "$prev" = "-c" ] && [ -n "$chdir" ] && [ "${arg#/}" = "$arg" ]; then
    arg="$chdir/$arg"
  fi
  args+=("$arg")
  prev="$arg"
done

exec "$MAR_TOOL" -k "$MAR_SIGNING_KEY_FILE" "${args[@]}"
