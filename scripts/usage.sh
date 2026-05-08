#!/usr/bin/env bash
# usage.sh - per-dispatch usage logging and cost estimation for Matrix.
# Sourceable. Each dispatch appends one JSONL line to .matrix/<slug>/usage.jsonl.
# State rollup lives in state.json under .usage.{total_input_bytes, total_output_bytes, by_agent}.
#
# Estimated cost is based on output file size as a proxy for output tokens.
# Input size is estimated from the combined size of input files passed to the agent.
# These are approximations — for authoritative totals, see Claude Code's session cost.
#
# Model pricing (USD per 1M tokens, as of 2025; update as needed):
#   opus:   $15 input / $75 output
#   sonnet: $3  input / $15 output
#   haiku:  $0.80 input / $4 output
#
# Bytes-to-tokens approximation: 1 token ≈ 4 bytes (rough average for English + code).

_usage_root() {
  printf '%s' "${MATRIX_ROOT:-${ORCHESTRATION_ROOT:-$PWD/.matrix}}"
}

_usage_file() {
  local slug="$1"
  printf '%s/%s/usage.jsonl' "$(_usage_root)" "$slug"
}

_usage_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# Cost table: input and output USD per 1M tokens
_model_input_cost() {
  case "$1" in
    opus*)   printf '15.00' ;;
    sonnet*) printf '3.00'  ;;
    haiku*)  printf '0.80'  ;;
    *)       printf '3.00'  ;; # default to sonnet
  esac
}

_model_output_cost() {
  case "$1" in
    opus*)   printf '75.00' ;;
    sonnet*) printf '15.00' ;;
    haiku*)  printf '4.00'  ;;
    *)       printf '15.00' ;;
  esac
}

# usage_record <slug> <agent> <issue_id_or_empty> <model> <start_epoch_s> <input_files_csv> <output_file>
#
# input_files_csv: comma-separated list of files read as primary inputs (for byte-counting).
#   Pass "" if unknown.
# output_file: the markdown file the agent wrote. Pass "" if none.
#
# Appends one JSONL record and updates state.json rollup.
usage_record() {
  local slug="$1" agent="$2" issue="${3:-}" model="$4" start_s="$5" input_files_csv="${6:-}" output_file="${7:-}"

  local end_s
  end_s="$(date +%s)"
  local duration_s=$(( end_s - start_s ))
  local now
  now="$(_usage_now)"

  # Byte counts
  local input_bytes=0 output_bytes=0
  if [ -n "$input_files_csv" ]; then
    IFS=',' read -ra _ifiles <<< "$input_files_csv"
    for f in "${_ifiles[@]}"; do
      [ -f "$f" ] && input_bytes=$(( input_bytes + $(wc -c < "$f") )) || true
    done
  fi
  if [ -n "$output_file" ] && [ -f "$output_file" ]; then
    output_bytes="$(wc -c < "$output_file")"
  fi

  # Estimated tokens (1 token ≈ 4 bytes)
  local input_tokens=$(( input_bytes / 4 ))
  local output_tokens=$(( output_bytes / 4 ))

  # Estimated cost in USD (scale factor: tokens/1M * price)
  local input_cost output_cost
  input_cost="$(echo "scale=6; $input_tokens * $(_model_input_cost "$model") / 1000000" | bc 2>/dev/null || echo "0")"
  output_cost="$(echo "scale=6; $output_tokens * $(_model_output_cost "$model") / 1000000" | bc 2>/dev/null || echo "0")"

  local usage_file
  usage_file="$(_usage_file "$slug")"
  mkdir -p "$(dirname "$usage_file")"

  # Append JSONL
  jq -nc \
    --arg ts "$now" \
    --arg agent "$agent" \
    --arg issue "$issue" \
    --arg model "$model" \
    --argjson duration_s "$duration_s" \
    --argjson input_bytes "$input_bytes" \
    --argjson output_bytes "$output_bytes" \
    --argjson input_tokens "$input_tokens" \
    --argjson output_tokens "$output_tokens" \
    --arg input_cost "$input_cost" \
    --arg output_cost "$output_cost" \
    '{
      ts: $ts,
      agent: $agent,
      issue: $issue,
      model: $model,
      duration_s: $duration_s,
      input_bytes: $input_bytes,
      output_bytes: $output_bytes,
      input_tokens: $input_tokens,
      output_tokens: $output_tokens,
      estimated_cost_usd: (($input_cost | tonumber) + ($output_cost | tonumber))
    }' >> "$usage_file"

  # Update state.json rollup
  local state_file
  state_file="$(_usage_root)/$slug/state.json"
  if [ -f "$state_file" ]; then
    local tmp="$state_file.tmp"
    local updated_at
    updated_at="$(_usage_now)"
    jq --arg agent "$agent" \
       --argjson ib "$input_bytes" \
       --argjson ob "$output_bytes" \
       --argjson it "$input_tokens" \
       --argjson ot "$output_tokens" \
       --arg ic "$input_cost" \
       --arg oc "$output_cost" \
       --arg updated_at "$updated_at" \
      '
      .usage //= {total_input_tokens: 0, total_output_tokens: 0, total_cost_usd: 0, by_agent: {}}
      | .usage.total_input_tokens += $it
      | .usage.total_output_tokens += $ot
      | .usage.total_cost_usd += (($ic | tonumber) + ($oc | tonumber))
      | .usage.by_agent[$agent] //= {input_tokens: 0, output_tokens: 0, cost_usd: 0, dispatches: 0}
      | .usage.by_agent[$agent].input_tokens += $it
      | .usage.by_agent[$agent].output_tokens += $ot
      | .usage.by_agent[$agent].cost_usd += (($ic | tonumber) + ($oc | tonumber))
      | .usage.by_agent[$agent].dispatches += 1
      | .updated_at = $updated_at
      ' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
  fi
}

# usage_summary <slug>
# Prints a human-readable cost summary.
usage_summary() {
  local slug="$1"
  local usage_file
  usage_file="$(_usage_file "$slug")"
  if [ ! -f "$usage_file" ]; then
    echo "No usage data for $slug."
    return 0
  fi

  echo "=== Usage — $slug ==="
  jq -r '
    [., ""] | @base64
  ' "$usage_file" 2>/dev/null || true

  # Rollup from state.json
  local state_file="$(_usage_root)/$slug/state.json"
  if [ -f "$state_file" ] && jq -e '.usage' "$state_file" >/dev/null 2>&1; then
    jq -r '
      .usage as $u |
      "Total input tokens (est.):  \($u.total_input_tokens)",
      "Total output tokens (est.): \($u.total_output_tokens)",
      "Total cost (est.):          $\($u.total_cost_usd | . * 10000 | round / 10000)",
      "",
      "By agent:",
      ($u.by_agent | to_entries[] |
        "  \(.key): \(.value.dispatches) dispatch(es) — est. $\(.value.cost_usd | . * 10000 | round / 10000)")
    ' "$state_file"
  fi
}

# usage_summary_all
# Prints summary across all features.
usage_summary_all() {
  local root
  root="$(_usage_root)"
  [ -d "$root" ] || { echo "No .matrix directory found."; return 0; }

  local total_cost=0
  while IFS= read -r slug; do
    local state_file="$root/$slug/state.json"
    [ -f "$state_file" ] || continue
    if jq -e '.usage' "$state_file" >/dev/null 2>&1; then
      local cost
      cost="$(jq -r '.usage.total_cost_usd' "$state_file")"
      printf '  %-40s $%s\n' "$slug" "$(echo "scale=4; $cost" | bc 2>/dev/null || echo "$cost")"
      total_cost="$(echo "scale=4; $total_cost + $cost" | bc 2>/dev/null || echo "$total_cost")"
    fi
  done < <(find "$root" -mindepth 2 -maxdepth 2 -name state.json -printf '%h\n' | sed "s|^$root/||" | sort)

  echo "  ----------------------------------------"
  printf '  %-40s $%s\n' "TOTAL" "$total_cost"
}
