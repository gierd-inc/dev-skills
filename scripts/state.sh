#!/usr/bin/env bash
# state.sh - per-feature state.json helpers for the Agency plugin.
# Sourceable: do NOT set -e at file level. Callers control their own shell options.
#
# Phase enum:
#   spec | design-proposed | designed | building | validating |
#   ready-to-ship | shipped | escalated
#
# Issue status enum:
#   pending | in-progress | reviewing | done | blocked

_state_root() {
  printf '%s' "${DEV_SKILLS_ROOT:-$PWD/.dev-skills}"
}

_state_file() {
  local slug="$1"
  printf '%s/%s/state.json' "$(_state_root)" "$slug"
}

_state_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# state_init <slug> <spec_source_type> <spec_source_ref> <target_repo>
state_init() {
  local slug="$1" stype="$2" sref="$3" target_repo="$4"
  local dir
  dir="$(_state_root)/$slug"
  mkdir -p "$dir"
  local now
  now="$(_state_now)"
  jq -n \
    --arg slug "$slug" \
    --arg stype "$stype" \
    --arg sref "$sref" \
    --arg target_repo "$target_repo" \
    --arg now "$now" \
    '{
      feature_slug: $slug,
      spec_source: { type: $stype, ref: $sref },
      phase: "spec",
      rounds: { spec_revisions: 0, design_revisions: 0, final_validation: 0 },
      max_rounds: 3,
      worktree_path: null,
      branch: null,
      target_repo: $target_repo,
      issues: [],
      tracker_sync: { linear_ids: {}, github_issue_numbers: {}, pr_number: null },
      created_at: $now,
      updated_at: $now
    }' > "$dir/state.json"
}

# state_get <slug> <jq_path>
state_get() {
  local slug="$1" path="$2"
  jq -r "$path" "$(_state_file "$slug")"
}

# state_set <slug> <jq_path> <json_value>
# Caller is responsible for JSON-quoting strings: state_set foo .phase '"building"'
state_set() {
  local slug="$1" path="$2" value="$3"
  local file
  file="$(_state_file "$slug")"
  local now
  now="$(_state_now)"
  local tmp="$file.tmp"
  jq --argjson v "$value" --arg now "$now" \
    "$path = \$v | .updated_at = \$now" "$file" > "$tmp"
  mv "$tmp" "$file"
}

# state_bump_round <slug> <round_name>
state_bump_round() {
  local slug="$1" round="$2"
  local file
  file="$(_state_file "$slug")"
  local now
  now="$(_state_now)"
  local tmp="$file.tmp"
  jq --arg round "$round" --arg now "$now" \
    '.rounds[$round] = (.rounds[$round] + 1) | .updated_at = $now' "$file" > "$tmp"
  mv "$tmp" "$file"
}

# state_check_circuit <slug> <round_name>
# exit 0 if rounds.<round> < max_rounds, else exit 1
state_check_circuit() {
  local slug="$1" round="$2"
  jq -e --arg round "$round" '.rounds[$round] < .max_rounds' "$(_state_file "$slug")" > /dev/null
}

# ---- Issue-level helpers ----

# state_add_issue <slug> <issue_id> <issue_file> <depends_on_csv> <skills_csv>
state_add_issue() {
  local slug="$1" id="$2" issue_file="$3" deps_csv="${4:-}" skills_csv="${5:-}"
  local file
  file="$(_state_file "$slug")"
  local now
  now="$(_state_now)"
  local tmp="$file.tmp"
  local deps_json skills_json
  deps_json="$(_csv_to_json_array "$deps_csv")"
  skills_json="$(_csv_to_json_array "$skills_csv")"
  jq --arg id "$id" \
     --arg issue_file "$issue_file" \
     --argjson deps "$deps_json" \
     --argjson skills "$skills_json" \
     --arg now "$now" \
    '.issues = ((.issues // []) | map(select(.id != $id)) + [{
       id: $id,
       file: $issue_file,
       depends_on: $deps,
       skills_baseline: $skills,
       status: "pending",
       rounds: { engineer: 0, review: 0 }
     }]) | .updated_at = $now' "$file" > "$tmp"
  mv "$tmp" "$file"
}

# state_set_issue_status <slug> <issue_id> <status>
state_set_issue_status() {
  local slug="$1" id="$2" status="$3"
  local file
  file="$(_state_file "$slug")"
  local now
  now="$(_state_now)"
  local tmp="$file.tmp"
  jq --arg id "$id" --arg status "$status" --arg now "$now" \
    '.issues |= map(if .id == $id then .status = $status else . end) | .updated_at = $now' \
    "$file" > "$tmp"
  mv "$tmp" "$file"
}

# state_bump_issue_round <slug> <issue_id> <round_name>
state_bump_issue_round() {
  local slug="$1" id="$2" round="$3"
  local file
  file="$(_state_file "$slug")"
  local now
  now="$(_state_now)"
  local tmp="$file.tmp"
  jq --arg id "$id" --arg round "$round" --arg now "$now" \
    '.issues |= map(if .id == $id then .rounds[$round] = (.rounds[$round] + 1) else . end) | .updated_at = $now' \
    "$file" > "$tmp"
  mv "$tmp" "$file"
}

# state_check_circuit_issue <slug> <issue_id> <round_name>
state_check_circuit_issue() {
  local slug="$1" id="$2" round="$3"
  jq -e --arg id "$id" --arg round "$round" \
    '(.issues[] | select(.id == $id) | .rounds[$round]) < .max_rounds' \
    "$(_state_file "$slug")" > /dev/null
}

# state_next_pending_issue <slug>
# Prints id of next eligible issue (status=pending and all depends_on are done), or empty.
state_next_pending_issue() {
  local slug="$1"
  jq -r '
    . as $root
    | (.issues // []) as $issues
    | ($issues | map(select(.status == "done") | .id)) as $done_ids
    | $issues
    | map(select(.status == "pending" and ((.depends_on // []) - $done_ids | length) == 0))
    | .[0].id // ""
  ' "$(_state_file "$slug")"
}

# ---- CURRENT pointer helpers ----

# state_set_current <slug>
state_set_current() {
  local slug="$1"
  local root
  root="$(_state_root)"
  mkdir -p "$root"
  printf '%s\n' "$slug" > "$root/CURRENT"
}

# state_get_current
state_get_current() {
  local root
  root="$(_state_root)"
  local f="$root/CURRENT"
  [ -f "$f" ] || return 1
  head -n1 "$f" | tr -d '[:space:]'
}

# state_list_features
state_list_features() {
  local root
  root="$(_state_root)"
  [ -d "$root" ] || return 0
  find "$root" -mindepth 2 -maxdepth 2 -name state.json -printf '%h\n' \
    | sed "s|^$root/||" \
    | sort
}

# ---- Internal ----

_csv_to_json_array() {
  local csv="$1"
  if [ -z "$csv" ]; then
    printf '[]'
    return 0
  fi
  printf '%s' "$csv" | jq -Rc 'split(",") | map(select(length > 0) | gsub("^\\s+|\\s+$"; ""))'
}
