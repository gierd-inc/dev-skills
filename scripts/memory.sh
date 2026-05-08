#!/usr/bin/env bash
# memory.sh - append-only JSONL memory writer for agent-orchestration.
# Sourceable: do NOT set -e at file level. Callers control their own shell options.

_memory_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# memory_append <scope> <slug_or_empty> <kind> <body>
#   scope: "feature" | "project"
#   slug:  feature slug (used when scope=feature; ignored when scope=project)
#   kind:  short identifier (e.g. lesson, decision)
#   body:  free-form text
memory_append() {
  local scope="$1" slug="$2" kind="$3" body="$4"
  local root="${MATRIX_ROOT:-${ORCHESTRATION_ROOT:-$PWD/.matrix}}"
  local file
  case "$scope" in
    feature)
      file="$root/$slug/memory.jsonl"
      ;;
    project)
      file="$root/memory.jsonl"
      ;;
    *)
      echo "memory_append: invalid scope '$scope' (expected 'feature' or 'project')" >&2
      return 2
      ;;
  esac
  local dir
  dir="$(dirname "$file")"
  mkdir -p "$dir"
  local now
  now="$(_memory_now)"
  jq -nc \
    --arg ts "$now" \
    --arg kind "$kind" \
    --arg body "$body" \
    '{ts: $ts, kind: $kind, body: $body}' \
    >> "$file"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  memory_append "$@"
fi
