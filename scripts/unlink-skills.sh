#!/usr/bin/env bash
set -euo pipefail

# Removes symlinks in ~/.claude/skills that point back into this repo's
# skills/ tree. The inverse of link-skills.sh.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.claude/skills"

if [ ! -e "$DEST" ]; then
  echo "$DEST does not exist; nothing to unlink."
  exit 0
fi

# If ~/.claude/skills is itself a symlink into this repo, refuse to act —
# matches the safety check in link-skills.sh.
if [ -L "$DEST" ]; then
  resolved="$(readlink -f "$DEST")"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      echo "error: $DEST is a symlink into this repo ($resolved)." >&2
      echo "Refusing to operate; remove or relocate the symlink manually." >&2
      exit 1
      ;;
  esac
fi

removed=0
while IFS= read -r -d '' entry; do
  target="$(readlink -f "$entry" 2>/dev/null || true)"
  case "$target" in
    "$REPO"/skills/*)
      rm "$entry"
      echo "unlinked $(basename "$entry") -> $target"
      removed=$((removed + 1))
      ;;
  esac
done < <(find "$DEST" -maxdepth 1 -mindepth 1 -type l -print0)

if [ "$removed" -eq 0 ]; then
  echo "no skill symlinks pointing into $REPO found in $DEST"
fi
