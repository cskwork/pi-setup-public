#!/usr/bin/env bash
# Prune pi session transcripts older than N days.
#
# Session JSONL files store every user prompt verbatim and nothing prunes them,
# so they accumulate indefinitely. This is a retention policy, not a cleanup:
# run it on a schedule, or by hand when the directory gets large.
#
#   ./prune-sessions.sh              # dry run, 90 days
#   ./prune-sessions.sh --apply      # delete, 90 days
#   DAYS=30 ./prune-sessions.sh --apply
#   ./prune-sessions.sh --apply --no-backup
#
# ponytail: mtime-based, no index. Sessions are flat files; a manifest would
# need maintaining and could disagree with the disk. Revisit if pi ever grows
# a session index worth respecting.
set -euo pipefail

DAYS="${DAYS:-90}"
SESSIONS="${PI_SESSIONS_DIR:-${PI_CONFIG_DIR:-$HOME/.pi}/agent/sessions}"
APPLY=0
BACKUP=1

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --no-backup) BACKUP=0 ;;
    --days=*) DAYS="${arg#--days=}" ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done

[ -d "$SESSIONS" ] || { echo "no sessions directory at $SESSIONS"; exit 0; }

mb() { xargs -0 stat -f%z 2>/dev/null | awk '{s+=$1} END{printf "%.1f", s/1048576}'; }

count=$(find "$SESSIONS" -type f -mtime +"$DAYS" | wc -l | tr -d ' ')
size=$(find "$SESSIONS" -type f -mtime +"$DAYS" -print0 | mb)
total=$(find "$SESSIONS" -type f | wc -l | tr -d ' ')

echo "sessions dir : $SESSIONS"
echo "retention    : $DAYS days"
echo "total files  : $total"
echo "to remove    : $count files (${size:-0} MB)"

if [ "$count" -eq 0 ]; then
  echo "nothing to prune ✅"
  exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  echo
  echo "oldest / newest that would be removed:"
  find "$SESSIONS" -type f -mtime +"$DAYS" -exec stat -f '  %Sm %N' -t '%Y-%m-%d' {} \; 2>/dev/null | sort | sed -n '1p;$p'
  echo
  echo "dry run — re-run with --apply to delete"
  exit 0
fi

if [ "$BACKUP" -eq 1 ]; then
  archive="$SESSIONS.prune-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  find "$SESSIONS" -type f -mtime +"$DAYS" -print0 | tar -czf "$archive" --null -T - 2>/dev/null
  echo "backup       : $archive ($(du -h "$archive" | cut -f1))"
fi

find "$SESSIONS" -type f -mtime +"$DAYS" -delete
find "$SESSIONS" -type d -empty -delete 2>/dev/null || true

echo "pruned       : $count files"
echo "remaining    : $(find "$SESSIONS" -type f | wc -l | tr -d ' ') files ($(du -sh "$SESSIONS" | cut -f1))"
