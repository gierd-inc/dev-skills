#!/usr/bin/env bash
# new-feature.sh - scaffold per-feature artifact tree under .agency/<slug>/
# and initialize state.json.
#
# Usage:
#   new-feature.sh <slug> <spec_source_type> <spec_source_ref> <spec_content_file>
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $(basename "$0") <slug> <spec_source_type> <spec_source_ref> <spec_content_file>" >&2
  exit 2
fi

SLUG="$1"
SPEC_TYPE="$2"
SPEC_REF="$3"
SPEC_FILE="$4"
TARGET_REPO="$PWD"

if [ ! -f "$SPEC_FILE" ]; then
  echo "error: spec content file not found: $SPEC_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./state.sh
source "$SCRIPT_DIR/state.sh"

ROOT="${AGENCY_ROOT:-$PWD/.matrix}"
FEATURE_DIR="$ROOT/$SLUG"

mkdir -p \
  "$FEATURE_DIR/architect" \
  "$FEATURE_DIR/design" \
  "$FEATURE_DIR/issues" \
  "$FEATURE_DIR/team-lead" \
  "$FEATURE_DIR/engineer" \
  "$FEATURE_DIR/review" \
  "$FEATURE_DIR/validation"

cp "$SPEC_FILE" "$FEATURE_DIR/spec-source.md"

state_init "$SLUG" "$SPEC_TYPE" "$SPEC_REF" "$TARGET_REPO"
state_set_current "$SLUG"

echo "Initialized feature $SLUG at $FEATURE_DIR"
