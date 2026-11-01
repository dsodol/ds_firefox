#!/bin/bash
# Rebase this fork onto the latest stable Firefox release.
#
# The fork's changes are everything that differs between the recorded
# upstream commit (tools/ds_firefox/upstream.env) and HEAD. When a newer
# FIREFOX_<version>_RELEASE tag exists upstream, this replaces the tree with
# that release, re-applies the fork's changes with a 3-way merge, and commits
# the result on top of HEAD.
#
# Usage: sync-upstream.sh [--check] [--tag FIREFOX_X_Y_RELEASE]
#   --check  only report whether a newer release exists; change nothing.
# Writes "changed", "tag" and "version" to $GITHUB_OUTPUT when set.
set -euo pipefail

STATE=tools/ds_firefox/upstream.env
cd "$(git rev-parse --show-toplevel)"
# shellcheck source=/dev/null
source "$STATE"

output() {
  echo "$1=$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "$1=$2" >> "$GITHUB_OUTPUT"
  fi
}

want_tag=""
check_only=false
while [ $# -gt 0 ]; do
  case "$1" in
    --check) check_only=true; shift ;;
    --tag) want_tag="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

refs=$(git ls-remote --tags "$UPSTREAM_URL" 'FIREFOX_*_RELEASE')
if [ -z "$want_tag" ]; then
  want_tag=$(printf '%s\n' "$refs" | sed -n 's#^[0-9a-f]*\trefs/tags/\(FIREFOX_[0-9_]*_RELEASE\)$#\1#p' \
    | awk -F_ '{ printf "%05d%05d%05d %s\n", $2, $3, ($4 == "RELEASE" ? 0 : $4), $0 }' \
    | sort | tail -n 1 | cut -d' ' -f2)
fi
if [ -z "$want_tag" ]; then
  echo "No upstream release tag found." >&2
  exit 1
fi

if [ "$want_tag" = "$UPSTREAM_TAG" ]; then
  echo "Already on $UPSTREAM_TAG."
  output changed false
  exit 0
fi

new_sha=$(printf '%s\n' "$refs" | awk -v t="refs/tags/$want_tag^{}" '$2 == t { print $1 }')
if [ -z "$new_sha" ]; then
  new_sha=$(printf '%s\n' "$refs" | awk -v t="refs/tags/$want_tag" '$2 == t { print $1 }')
fi
version=$(echo "$want_tag" | sed -e 's/^FIREFOX_//' -e 's/_RELEASE$//' -e 's/_/./g')
if [ -z "$new_sha" ]; then
  echo "Upstream tag $want_tag not found." >&2
  exit 1
fi
if $check_only; then
  echo "Newer upstream release: $want_tag (currently $UPSTREAM_TAG)."
  output changed true
  output tag "$want_tag"
  output version "$version"
  exit 0
fi
echo "Syncing from $UPSTREAM_TAG ($UPSTREAM_SHA) to $want_tag ($new_sha)."

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Working tree has uncommitted changes; refusing to sync." >&2
  exit 1
fi

git fetch --no-tags --depth 1 "$UPSTREAM_URL" "$UPSTREAM_SHA" "$new_sha"

patch=$(mktemp)
trap 'rm -f "$patch"' EXIT
git diff --binary --full-index "$UPSTREAM_SHA" HEAD > "$patch"
echo "Fork changes: $(git diff --stat "$UPSTREAM_SHA" HEAD | tail -n 1)"

git read-tree -u --reset "$new_sha"
if ! git apply --3way --index "$patch"; then
  echo "::error::The fork's changes do not apply cleanly to $want_tag." >&2
  echo "Conflicting files:" >&2
  git diff --name-only --diff-filter=U >&2 || true
  exit 2
fi

cat > "$STATE" <<STATE
UPSTREAM_URL=$UPSTREAM_URL
UPSTREAM_TAG=$want_tag
UPSTREAM_SHA=$new_sha
STATE
git add "$STATE"
git commit -q -m "Sync with upstream Firefox $version

Upstream tag $want_tag ($new_sha), with this fork's changes
re-applied on top."
output changed true
output tag "$want_tag"
output version "$version"
