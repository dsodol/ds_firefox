#!/bin/bash
# Stage a MAR into a copy of a packaged Windows build with the build's own
# updater.exe, run under Wine, the same way Firefox stages updates in the
# background. Verifies signature, channel and version checks end to end.
#
# Usage: test-update.sh <package-dir> <mar> <expect>
#   package-dir  packaged build, e.g. obj-win64/dist/firefox
#   expect       "applied" to require success, or an updater error code
#                (e.g. 19 for a bad signature) to require that failure.
# Wine defaults to the bootstrapped one; override with $WINE.
set -euo pipefail

pkg=$(realpath "$1")
mar=$(realpath "$2")
expect="$3"
WINE="${WINE:-$HOME/.mozbuild/wine/bin/wine}"
WINESERVER="$(dirname "$WINE")/wineserver"

work=$(mktemp -d)
trap 'WINEPREFIX="$work/prefix" "$WINESERVER" -k 2>/dev/null || true; rm -rf "$work"' EXIT
install="$work/install"
updates="$work/updates/0"
mkdir -p "$updates"
cp -a "$pkg" "$install"
cp "$mar" "$updates/update.mar"
echo pending > "$updates/update.status"

winpath() { local p="${1//\//\\}"; printf 'Z:%s' "$p"; }

export WINEPREFIX="$work/prefix" WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml="
"$WINE" "$install/updater.exe" 3 "$(winpath "$updates")" "$(winpath "$install")" \
  "$(winpath "$install/updated")" first -1 || true
"$WINESERVER" -w || true

status=$(tr -d '\r' < "$updates/update.status" | head -n 1)
echo "updater status: $status"
if [ "$expect" = applied ]; then
  if [ "$status" != applied ] || [ ! -f "$install/updated/application.ini" ]; then
    echo "::error::Expected the update to stage successfully." >&2
    tail -n 40 "$updates/update.log" 2>/dev/null >&2 || true
    exit 1
  fi
  grep -E '^(Version|BuildID)=' "$install/updated/application.ini"
else
  if [ "$status" != "failed: $expect" ]; then
    echo "::error::Expected 'failed: $expect', got '$status'." >&2
    tail -n 40 "$updates/update.log" 2>/dev/null >&2 || true
    exit 1
  fi
fi
echo "OK: update test passed (expected $expect)."
