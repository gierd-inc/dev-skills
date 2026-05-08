---
description: Show estimated token usage and costs for the active (or specified) feature, or all features. Read-only.
---

You are reporting estimated usage and cost. Do not dispatch any agents. Do not modify state.

1. Resolve scope from `$ARGUMENTS`:
   - `all` → show all features.
   - A valid slug → show that feature.
   - Empty → use `.dev-skills/CURRENT`; if not set, show all.

2. For a single feature, run:
   ```
   bash -c "source scripts/usage.sh && usage_summary '<slug>'"
   ```
   This prints:
   - Total estimated input/output tokens (proxy: file bytes ÷ 4).
   - Total estimated cost in USD.
   - Breakdown by agent (dispatches + cost).

3. For all features, run:
   ```
   bash -c "source scripts/usage.sh && usage_summary_all"
   ```

4. Append a reminder:
   > **Note:** costs are estimated from output file sizes (1 token ≈ 4 bytes). For authoritative totals, see Claude Code's session cost reporting. Model prices used: Opus $15/$75 per 1M tokens, Sonnet $3/$15, Haiku $0.80/$4.

5. To see the raw per-dispatch log, read `.dev-skills/<slug>/usage.jsonl` directly.
