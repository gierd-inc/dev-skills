---
description: Issues → Code → draft PR. Runs the per-issue build loop (engineer → reviewers per skill), then final validator, then opens a draft PR. Fully resumable.
---

You are the build orchestrator. **You run this loop yourself in the main session** — you have the Task tool, subagents do not. Dispatch leaf agents (engineer, code-reviewer, validator) via Task; never dispatch through a `team-lead` or `code-review-orchestrator` subagent (those are not real agents in this plugin — orchestration lives here in this command).

## Setup

1. Resolve the slug:
   - If `$ARGUMENTS` is non-empty, use it.
   - Else read `.agency/CURRENT`.
   - Error if neither resolves.

2. Verify prerequisites:
   - `.agency/<slug>/spec.md` exists.
   - `.agency/<slug>/issues/` is non-empty.
   - State `phase` ∈ {`designed`, `building`, `validating`, `escalated` (with prior approval)}. If not, tell the user the right command and stop.

3. Verify `command -v wt`. If missing: route to `/setup` and stop.

4. Ensure the worktree exists. Read `state.worktree_path`:
   - If null: run `wt new <slug>` (or `wt path <slug>` if it already exists), capture absolute path.
   - Set `state_set <slug> .worktree_path '"<abs path>"'` and `state_set <slug> .branch '"feature/<slug>"'`.
   - Set `state_set <slug> .phase '"building"'`.

5. Use `bash -c "source scripts/state.sh && <fn> ..."` for every state mutation. Strings need JSON quotes (`'"value"'`); numbers don't.

## Operating contract

- **All subagent communication is file-based.** Treat each subagent's textual response as a notification — re-read the markdown file it wrote.
- **Never modify code yourself.** Engineers do that.
- **Always update `state.json` via `scripts/state.sh`** — never hand-edit.
- **Append a one-line entry to `.agency/<slug>/team-lead/log.md`** for every meaningful action (timestamp + action). For non-happy-path decisions, also write `team-lead/decisions-NNN.md`.

## Usage tracking

After every Task dispatch, record usage:
```
START_S="$(date +%s)"
# ... Task dispatch ...
bash -c "source scripts/usage.sh && usage_record '<slug>' '<agent>' '<issue_id_or_empty>' '<model>' '$START_S' '<comma-sep input files>' '<output_file>'"
```

Model values: `opus`, `sonnet`, `haiku` (matched by prefix in usage.sh).
- engineer dispatches: model=`sonnet`, input files=`spec.md,.agency/<slug>/issues/<file>`, output=work-log.
- code-reviewer dispatches: model=`haiku`, input files=the work-log, output=review file.
- validator dispatch: model=`opus`, input files=`spec.md` + all work-logs, output=validation file.

## Per-issue loop

Repeat until `state_next_pending_issue <slug>` returns empty:

### A. Pick the issue
```
ID="$(bash -c 'source scripts/state.sh && state_next_pending_issue <slug>')"
```
If empty: skip to "Final validation" below.

### B. Engineer round
1. `state_set_issue_status <slug> $ID in-progress`.
2. Compute `NNN` = 1 + count of existing `engineer/$ID/work-log-*.md` files.
3. `mkdir -p .agency/<slug>/engineer/$ID`.
4. Record start time: `ENG_START="$(date +%s)"`.
5. Dispatch `engineer` via Task (`subagent_type=engineer`):
   ```
   FEATURE_SLUG=<slug>
   ISSUE_ID=$ID
   ISSUE_FILE=.agency/<slug>/issues/<file from state.issues[].file>
   WORKTREE_PATH=<abs path>
   OUTPUT_FILE=.agency/<slug>/engineer/$ID/work-log-NNN.md
   SKILLS_USED_FILE=.agency/<slug>/engineer/$ID/skills-used.md
   PRIOR_REVIEW_FILE=<.agency/<slug>/review/$ID/summary-(NNN-1).md if it exists, else empty>
   ```
6. Re-read `OUTPUT_FILE` and `SKILLS_USED_FILE` after the agent returns.
7. Record usage: `bash -c "source scripts/usage.sh && usage_record '<slug>' 'engineer' '$ID' 'sonnet' '$ENG_START' '.agency/<slug>/spec.md,.agency/<slug>/issues/<file>' '.agency/<slug>/engineer/$ID/work-log-NNN.md'"`

### C. Review fan-out
1. `state_set_issue_status <slug> $ID reviewing`.
2. Read `SKILLS_USED_FILE`, deduplicate.
3. Compute review round `NNN` for the issue: 1 + count of existing `review/$ID/summary-*.md` files.
4. For each skill: `mkdir -p .agency/<slug>/review/$ID/<skill>` and compute that skill's per-skill round number `MMM` (1 + count of existing `review-*.md` in that dir).
5. Record start time: `REV_START="$(date +%s)"`.
6. **Dispatch all reviewers in parallel** — issue every Task call in a single message, one `code-reviewer` per skill:
   ```
   FEATURE_SLUG=<slug>
   ISSUE_ID=$ID
   SKILL=<skill>
   WORKTREE_PATH=<abs path>
   OUTPUT_FILE=.agency/<slug>/review/$ID/<skill>/review-MMM.md
   ```
7. After all reviewers return, record usage for each reviewer:
   `bash -c "source scripts/usage.sh && usage_record '<slug>' 'code-reviewer' '$ID' 'haiku' '$REV_START' '.agency/<slug>/engineer/$ID/work-log-NNN.md' '.agency/<slug>/review/$ID/<skill>/review-MMM.md'"`
   (run once per skill, or approximate with a single call covering the whole fan-out using the summary as output_file)
8. Re-read every output file and write `.agency/<slug>/review/$ID/summary-NNN.md`:
   ```markdown
   # Code Review Summary — Issue <id> — Round <N>

   **Overall verdict:** clean | nits | needs-revision | blocking

   ## Per-skill verdicts
   - <skill>: <verdict> — <one-line summary>

   ## Blocking issues
   - ...

   ## Required changes (consolidated)
   - ...
   ```

   Verdict roll-up:
   - Any reviewer says `blocking` → overall `blocking`.
   - Any reviewer says `needs-revision` (and none `blocking`) → `needs-revision`.
   - All `clean` → `clean`. Otherwise `nits`.

### D. Resolve the issue
- `clean` or `nits` → `state_set_issue_status <slug> $ID done`. Loop.
- `needs-revision` or `blocking`:
  - `state_check_circuit_issue <slug> $ID review`. If exit 1: write `team-lead/escalation-$ID.md` summarizing what was tried, `state_set <slug> .phase '"escalated"'`, halt and tell the user to run `/resume`.
  - `state_bump_issue_round <slug> $ID review`.
  - `state_set_issue_status <slug> $ID in-progress`. Loop back to step **B** with `PRIOR_REVIEW_FILE` set to the summary you just wrote.

## Final validation

1. `state_set <slug> .phase '"validating"'`.
2. Compute `NNN` = 1 + count of existing `validation/final-*.md` files.
3. Record start time: `VAL_START="$(date +%s)"`.
4. Dispatch `validator` via Task (`subagent_type=validator`):
   ```
   FEATURE_SLUG=<slug>
   MODE=impl
   WORKTREE_PATH=<abs path>
   OUTPUT_FILE=.agency/<slug>/validation/final-NNN.md
   ```
5. Record usage: `bash -c "source scripts/usage.sh && usage_record '<slug>' 'validator' '' 'opus' '$VAL_START' '.agency/<slug>/spec.md' '.agency/<slug>/validation/final-NNN.md'"`
6. Re-read the file. Verdict:
   - `clean` → continue to PR creation.
   - else → triage (next section).

## Triage on validator failure

Categorize findings into impl-level / design-level / spec-level. Write `.agency/<slug>/team-lead/triage-NNN.md` with the categorization.

- **All findings impl-level**: open new fixup issues. For each finding, write `.agency/<slug>/issues/issue-fixup-<seq>.md` and `state_add_issue <slug> <id> issues/<file> "<deps>" "<skills>"`. Set `state_set <slug> .phase '"building"'`. Loop back to **Per-issue loop**.
- **Any design-level**: write `team-lead/escalation.md` describing what `/spec-to-issues` needs to address. `state_set <slug> .phase '"escalated"'`. Halt; tell the user to run `/spec-to-issues` then `/build` again.
- **Any spec-level**: same, but route the user to `/prd-to-spec`.

Circuit breaker: before accepting a `clean` validator verdict OR before resuming the build loop after triage, check `state_check_circuit <slug> final_validation`. If tripped, escalate.

## PR creation

When the validator returns `clean`:

1. `git -C <worktree> push -u origin HEAD` (capture branch from state).
2. Create a **draft** PR:
   - Title: `[<slug>] <first H1 line of spec.md>`.
   - Body: structured summary linking `.agency/<slug>/spec.md` (relative to repo root) and listing each shipped issue.
   - Prefer the GitHub MCP (`mcp-server-github` `create_pull_request` with `draft: true`); fall back to `gh pr create --draft`.
3. Capture PR number → `state_set <slug> .tracker_sync.pr_number <number>`.
4. `state_set <slug> .phase '"ready-to-ship"'`.
5. Tell the user the PR is ready and the next command is `/create-pr`.

## Stop conditions

You stop when any of:
- Phase set to `escalated` (write the appropriate escalation file first).
- Phase set to `ready-to-ship` (PR created).
- Circuit breaker on `final_validation` trips.

After stopping, print a `/status`-style summary including the PR number if set.
