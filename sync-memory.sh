#!/usr/bin/env bash
# Backup pi-memory (MEMORY.md, daily logs, scratchpad) to the PRIVATE GitHub mirror.
# pi-memory stores plain markdown, so this is a straight copy — no SQLite checkpoint needed.
set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-$HOME/.pi/agent/memory}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/pi-memory-backup}"
REMOTE="${REMOTE:-https://github.com/cskwork/pi-memory-backup.git}"

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"
[ -d .git ] || git init -q -b main
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"

# Refuse to push to a public repo — this content is personal.
if command -v gh >/dev/null 2>&1; then
  slug=$(printf '%s' "$REMOTE" | sed -E 's#.*github\.com[:/]##; s#\.git$##')
  if [ "$(gh repo view "$slug" --json isPrivate -q .isPrivate 2>/dev/null)" = "false" ]; then
    echo "refusing to push memory to PUBLIC repo $slug" >&2
    exit 1
  fi
fi

# pi-memory markdown store (authoritative).
rm -rf "${BACKUP_DIR:?}/memory"
mkdir -p "$BACKUP_DIR/memory"
cp -R "$MEMORY_DIR/." "$BACKUP_DIR/memory/" 2>/dev/null || true

# ai-memory server data + wiki still back other agents up; ship them if present.
# Copied as plain files — strip their .git so nothing nests.
for d in "$HOME/Applications/ai-memory" "$HOME/wiki"; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  rm -rf "${BACKUP_DIR:?}/$n"
  cp -R "$d" "$BACKUP_DIR/$n"
  find "$BACKUP_DIR/$n" -name ".git" -type d -prune -exec rm -rf {} + 2>/dev/null || true
done

if [ -z "$(git status --porcelain --untracked-files=normal)" ]; then
  echo "memory already in sync ✅"
  exit 0
fi
git add -A
git commit -q -m "memory backup: $(date '+%Y-%m-%d %H:%M')"
git push -q -u origin main
echo "memory backed up ✅"
