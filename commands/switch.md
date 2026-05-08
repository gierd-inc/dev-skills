---
description: Change the active Agency feature pointer (.dev-skills/CURRENT).
---

You are switching the active feature. Argument: `$ARGUMENTS` (a feature slug).

1. If `$ARGUMENTS` is empty: print the current active slug (`cat .dev-skills/CURRENT` if it exists) and the list of available slugs (via `/list`-style enumeration). Stop.

2. Validate that `.dev-skills/<slug>/state.json` exists. If not, error and list available slugs.

3. Run `bash -c "source scripts/state.sh && state_set_current <slug>"`.

4. Print confirmation and a `/status`-style summary for the new active feature.
