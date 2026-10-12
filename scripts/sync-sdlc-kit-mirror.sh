#!/usr/bin/env bash
# Refresh the tracked skills/sdlc-kit mirror from the local sdlc-kit clone and
# push it to origin/main. ~/.local/bin/sdlc-kit-sync (launchd, hourly) calls it
# after fast-forwarding the clone.
#
# The commit is built on a temporary index, so the working checkout (where
# skills/sdlc-kit is a symlink to the clone) is never touched.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${SDLC_KIT_SRC:-$HOME/.agents/sources/cskwork/sdlc-kit}"
MIRROR=skills/sdlc-kit
log() { echo "$(date '+%Y-%m-%dT%H:%M:%S%z') mirror $*"; }

if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
  log "SKIP sdlc-kit clone has local changes"; exit 0
fi
git -C "$REPO" fetch -q origin main
base=$(git -C "$REPO" rev-parse origin/main)
src_tree=$(git -C "$SRC" rev-parse 'HEAD^{tree}')
# The mirror is the clone's tracked files verbatim, so equal tree ids mean it is current.
[ "$(git -C "$REPO" rev-parse "$base:$MIRROR" 2>/dev/null)" != "$src_tree" ] || exit 0

version=$(git -C "$SRC" show HEAD:VERSION)
src_rev=$(git -C "$SRC" rev-parse --short HEAD)
git -C "$REPO" fetch -q "$SRC" HEAD   # copy the clone's objects into pi-setup

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export GIT_INDEX_FILE="$tmp/index"
git -C "$REPO" read-tree "$base"
git -C "$REPO" rm -rqf --cached --ignore-unmatch "$MIRROR"
git -C "$REPO" read-tree --prefix="$MIRROR/" "$src_tree"
tree=$(git -C "$REPO" write-tree)
unset GIT_INDEX_FILE

commit=$(git -C "$REPO" commit-tree "$tree" -p "$base" -m "chore(sdlc-kit): cskwork/sdlc-kit v$version 미러

원본 $src_rev 기준 추적 파일 전체를 그대로 반영했다(scripts/sync-sdlc-kit-mirror.sh 자동 실행).")
git -C "$REPO" push -q origin "$commit:refs/heads/main"
log "OK v$version ($src_rev) -> $(git -C "$REPO" rev-parse --short "$commit")"

# Move the local checkout along only when the mirror commit is all it lacks:
# on main, nothing staged, HEAD at the old tip. A mixed reset leaves files alone.
git -C "$REPO" fetch -q origin main
if [ "$(git -C "$REPO" symbolic-ref -q --short HEAD)" = main ] \
   && [ "$(git -C "$REPO" rev-parse HEAD)" = "$base" ] \
   && git -C "$REPO" diff --cached --quiet; then
  git -C "$REPO" reset -q --mixed "$commit"
else
  log "local checkout left as is (not on main at $base or has staged changes)"
fi
