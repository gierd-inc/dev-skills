---
description: Resume the active (or specified) feature. Handles escalated state by surfacing the escalation file and asking how to proceed.
---

You are resuming an in-flight feature.

1. Resolve the slug from `$ARGUMENTS` or `.agency/CURRENT`. If neither: list features and stop.

2. Read state. If `phase == "escalated"`:
   - Read `.agency/<slug>/team-lead/escalation*.md` (most recent) and summarize for the user.
   - Read any triage file `.agency/<slug>/team-lead/triage-*.md`.
   - Ask the user how to proceed, presenting options based on findings:
     - **impl-level**: reset the relevant issue's review counter (`state_set <slug> .issues[N].rounds.review 0` via state helper), set issue status back to `in-progress`, set phase back to `building`.
     - **design-level**: tell the user to run `/spec-to-issues` to revise issues.
     - **spec-level**: tell the user to run `/prd-to-spec` to revise the spec.
     - **abort**: leave phase `escalated`.
   - For impl-level path only: after resetting state, follow `commands/build.md` directly to resume the per-issue loop. Do not try to dispatch a `team-lead` subagent — orchestration runs in this main session.

3. If `phase != "escalated"`:
   - Tell the user the feature is not escalated and route them to the appropriate command:
     - `spec` → `/prd-to-spec`
     - `designed` / `building` / `validating` → `/build`
     - `ready-to-ship` → `/create-pr`
     - `shipped` → done
