---
description: List all Gierd Dev Skills features with their current phase. Read-only.
---

You are listing all Gierd Dev Skills features. Do not dispatch any agents. Do not modify state.

1. Run `bash -c "source scripts/state.sh && state_list_features"` to get all slugs.
2. For each slug, read `.dev-skills/<slug>/state.json` and collect: `phase`, issue count, `tracker_sync.pr_number`.
3. Read `.dev-skills/CURRENT` if present.
4. Print a table:
   ```
   ACTIVE  SLUG                    PHASE             ISSUES  PR
   *       eng-123-add-foo         building          5       —
           eng-456-fix-bar         shipped           3       #1234
   ```
   Mark the active feature (matching CURRENT) with `*`.
