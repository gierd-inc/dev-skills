#!/usr/bin/env bash
set -euo pipefail

# Generates a slash-command wrapper in commands/ for every SKILL.md under skills/
# (excluding deprecated/). Each wrapper invokes the matching skill via the Skill
# tool, so users can call /gierd:<skill-name> from the slash-command picker.
#
# Re-run whenever skills are added, renamed, or removed. The script is idempotent:
# wrappers carry an HTML comment marker, and only files with that marker are
# touched. Hand-written commands (build.md, prd-to-spec.md, etc.) are left alone.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="$REPO/commands"
MARKER_PREFIX="<!-- auto-generated from "

mkdir -p "$COMMANDS_DIR"

# Step 1: clear out previously-generated wrappers so renames/deletes don't leave stragglers.
removed=0
while IFS= read -r -d '' cmd; do
  if head -n5 "$cmd" 2>/dev/null | grep -q "$MARKER_PREFIX"; then
    rm "$cmd"
    removed=$((removed + 1))
  fi
done < <(find "$COMMANDS_DIR" -maxdepth 1 -name '*.md' -print0)

# Step 2: walk skills/ and emit one wrapper per skill.
generated=0
skipped=0
while IFS= read -r -d '' skill_md; do
  rel_path="${skill_md#$REPO/}"

  # Extract name + description from YAML frontmatter. Handles single-line plain
  # scalars and folded (>) / literal (|) block scalars; multi-line values are
  # joined with single spaces.
  parsed="$(awk '
    BEGIN { in_fm=0; in_desc=0; name=""; desc="" }
    /^---$/ { in_fm++; if (in_fm==2) exit; next }
    in_fm==1 {
      if (/^name:/) {
        sub(/^name:[[:space:]]*/, "")
        name = $0
        in_desc = 0
        next
      }
      if (/^description:[[:space:]]*[|>]/) {
        in_desc = 1
        next
      }
      if (/^description:/) {
        sub(/^description:[[:space:]]*/, "")
        desc = $0
        in_desc = 0
        next
      }
      if (in_desc) {
        if (/^[a-zA-Z_]+:/) { in_desc = 0; next }
        line = $0
        sub(/^[[:space:]]+/, "", line)
        desc = (desc ? desc " " : "") line
      }
    }
    END { print name "\t" desc }
  ' "$skill_md")"

  name="${parsed%%$'\t'*}"
  description="${parsed#*$'\t'}"

  if [ -z "$name" ]; then
    echo "warning: $rel_path has no name; skipping" >&2
    skipped=$((skipped + 1))
    continue
  fi
  if [ -z "$description" ]; then
    description="Wrapper for the $name skill."
  fi

  output="$COMMANDS_DIR/$name.md"

  # If a hand-written command lives at this path, leave it alone.
  if [ -e "$output" ]; then
    if ! head -n5 "$output" 2>/dev/null | grep -q "$MARKER_PREFIX"; then
      echo "warning: $output is hand-written; skipping skill wrapper for $name" >&2
      skipped=$((skipped + 1))
      continue
    fi
  fi

  cat > "$output" <<EOF
---
description: $description
---

$MARKER_PREFIX$rel_path -->

Invoke the \`$name\` skill via the Skill tool, then apply it to the user's current task.
EOF

  generated=$((generated + 1))
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/deprecated/*' -not -path '*/node_modules/*' -print0)

echo "removed $removed stale wrapper(s); generated $generated; skipped $skipped"
