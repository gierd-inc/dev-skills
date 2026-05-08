---
description: Spec → Issues. Run the designer agent on the active feature: draft a slice proposal, get user approval, then materialize one issue file per slice.
---

You are starting the design phase for the active feature.

1. Resolve the slug:
   - If `$ARGUMENTS` is non-empty, use it.
   - Else read `.agency/CURRENT`.
   - Error if neither resolves.

2. Verify `.agency/<slug>/spec.md` exists. If not, tell the user to run `/prd-to-spec` first and stop.

3. Record start time: `DESIGN_START="$(date +%s)"`.

4. Dispatch the designer agent (Task tool, `subagent_type=designer`) with prompt:
   `FEATURE_SLUG=<slug>. Read spec.md and any existing issues. Draft design/proposal.md, get user approval, then materialize issues.`

5. Record usage: `bash -c "source scripts/usage.sh && usage_record '<slug>' 'designer' '' 'sonnet' '$DESIGN_START' '.agency/<slug>/spec.md' '.agency/<slug>/design/proposal.md'"`

6. After the designer returns, print phase + issue count via a `/status`-style summary.
