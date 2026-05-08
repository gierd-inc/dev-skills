---
description: Print Agency status for the active (or specified) feature. Read-only; dispatches no agents.
---

You are reporting status. Do not dispatch any agents. Do not modify state.

1. Resolve the slug:
   - If `$ARGUMENTS` is a slug, use it.
   - Else read `.dev-skills/CURRENT`.
   - If neither resolves, list all features (`bash -c "source scripts/state.sh && state_list_features"`) and stop.

2. Read `.dev-skills/<slug>/state.json` and print:
   - `feature_slug`
   - `phase`
   - `rounds.{spec_revisions, design_revisions, final_validation}`
   - `worktree_path`, `branch`
   - `tracker_sync.pr_number` (if set)

3. Print issue table:
   - For each issue: `<id>  <status>  e=<rounds.engineer>  r=<rounds.review>  deps=[...]`

4. Print last 5 entries from `.dev-skills/<slug>/team-lead/log.md` if present.

5. If `.dev-skills/<slug>/state.json` contains a `.usage` key, print a one-line cost summary:
   `Est. cost: $<total_cost_usd> (<total_input_tokens> in / <total_output_tokens> out tokens) — run /cost for breakdown`

6. Suggest next command based on phase:
   - `spec` → `/spec-to-issues`
   - `designed` → `/build`
   - `building` / `validating` → `/build` (resume)
   - `ready-to-ship` → `/create-pr`
   - `escalated` → `/resume`
   - `shipped` → done

Output as concise human-readable summary.
