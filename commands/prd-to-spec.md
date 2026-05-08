---
description: PRD → Spec. Run the architect agent to grill the user and produce a heavy spec.md. Accepts a Linear issue ID, GitHub issue URL, file path, or raw text. Re-run on an existing slug to refine.
---

You are starting the architect (PRD → Spec) phase. Argument: `$ARGUMENTS`.

1. **Resolve the slug.**
   - If `$ARGUMENTS` is empty: read `.agency/CURRENT` to get the active slug. If no CURRENT, error and tell the user to pass a PRD source.
   - If `$ARGUMENTS` is a slug that already exists under `.agency/`: treat as a re-run on that slug.
   - Otherwise detect spec source from `$ARGUMENTS`:
     - Matches `^[A-Z]+-\d+$` or contains `linear.app` → Linear; fetch via the Linear MCP and write to a temp file.
     - Contains `github.com/.../issues/` → GitHub; fetch via the GitHub MCP (`issue_read`) or `gh issue view --json title,body`.
     - Existing path on disk → file; read directly.
     - Otherwise → raw text; write to a temp file.
   - Generate a slug: lowercase, dash-separated, prefixed with the issue ID if available (e.g. `eng-123-add-foo`).

2. **Scaffold (new slug only):**
   `bash scripts/new-feature.sh <slug> <type> <ref> <spec_file>`. This creates `.agency/<slug>/` and writes `.agency/CURRENT`.

3. **Set CURRENT:** if this was an existing slug, run `bash -c "source scripts/state.sh && state_set_current <slug>"`.

4. Record start time: `ARCH_START="$(date +%s)"`.

5. **Dispatch the architect agent** (Task tool, `subagent_type=architect`) with prompt:
   `FEATURE_SLUG=<slug>. Read .agency/<slug>/spec-source.md (and existing spec.md if any). Grill the user and produce/refine spec.md.`

6. Record usage: `bash -c "source scripts/usage.sh && usage_record '<slug>' 'architect' '' 'opus' '$ARCH_START' '.agency/<slug>/spec-source.md' '.agency/<slug>/spec.md'"`

7. After the architect returns, print `/status`-style summary.
