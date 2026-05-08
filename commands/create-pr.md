---
description: Promote the draft PR to ready-for-review, optionally sync issues to Linear/GitHub, and request reviewers from git blame.
---

You are shipping the active feature.

1. Resolve the slug:
   - If `$ARGUMENTS` is non-empty, use it.
   - Else read `.dev-skills/CURRENT`.
   - Error if neither resolves.

2. Read state:
   - `phase` must be `ready-to-ship`. If not, tell the user the build is not done and stop.
   - `tracker_sync.pr_number` must be set. If not, tell the user to re-run `/build` and stop.
   - `worktree_path` is the worktree root.

3. **Confirm with the user.** Print:
   - PR number, title, branch.
   - Issue count and acceptance summary from `spec.md`.
   - List of files touched (`git -C <worktree> diff --name-only $(git merge-base HEAD origin/main)`).
   Ask: "Mark ready for review and request reviewers? [y/N]"

4. On confirm:
   - **Push the branch** (if not already): `git -C <worktree> push -u origin HEAD`.
   - **Mark PR ready**: prefer `mcp-server-github update_pull_request` with `draft: false`. Fallback: `gh pr ready <pr_number>`.
   - **Request reviewers from blame**: collect top contributors to changed files (`git -C <worktree> blame --line-porcelain ...`), pick the top 1-2 distinct GitHub usernames, request via `update_pull_request` or `gh pr edit --add-reviewer`.
   - **Optional issue-tracker sync** (ask the user): if yes, create one Linear/GitHub issue per local issue file under `.dev-skills/<slug>/issues/`. Record the resulting IDs in `state.tracker_sync.linear_ids` / `.github_issue_numbers` keyed by local issue id.
   - Set `state_set <slug> .phase '"shipped"'`.

5. Print final status: PR URL, reviewers requested, tracker sync results.
