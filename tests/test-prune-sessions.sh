#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

sessions="$TMP/sessions"
mkdir -p "$sessions/nested"
printf 'old session\n' > "$sessions/nested/old.jsonl"
touch -t 202001010000 "$sessions/nested/old.jsonl"

output="$TMP/output.txt"
if ! PI_SESSIONS_DIR="$sessions" DAYS=1 \
  bash "$ROOT/scripts/prune-sessions.sh" --apply >"$output" 2>&1; then
  cat "$output" >&2
  fail "prune command exited non-zero"
fi

[ -d "$sessions" ] || fail "sessions root was deleted"
[ ! -e "$sessions/nested/old.jsonl" ] || fail "old session was not deleted"
grep -q 'remaining    : 0 files' "$output" || fail "final statistics were not reported"

archive=$(find "$TMP" -maxdepth 1 -name 'sessions.prune-backup-*.tar.gz' -print -quit)
[ -n "$archive" ] || fail "backup archive was not created"
mode=$(stat -c '%a' "$archive" 2>/dev/null || stat -f '%Lp' "$archive")
[ "$mode" = "600" ] || fail "backup mode is $mode, expected 600"

echo "PASS: session pruning preserves the root and writes a private backup"
