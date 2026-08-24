#!/usr/bin/env bash
# Backup pi-memory (learned preferences/lessons) to the private GitHub mirror.
# Safe: checkpoints SQLite first so the pushed copy is never a torn WAL state.
set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-$HOME/.pi/memory}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/pi-memory-backup}"

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"
[ -d .git ] || git init -q -b main
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/cskwork/pi-memory-backup.git"

# Atomic snapshot via sqlite3 .backup (falls back to file copy if sqlite3 absent)
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$MEMORY_DIR/memory.db" ]; then
  sqlite3 "$MEMORY_DIR/memory.db" ".backup '$BACKUP_DIR/memory.db'"
else
  cp -f "$MEMORY_DIR/memory.db" "$BACKUP_DIR/memory.db" 2>/dev/null || true
fi

# Include free-standing artifacts if present (ai-memory, vault wiki).
# Copied content ships as plain files — strip their .git so nothing nests.
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
