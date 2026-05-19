---
name: consolidate-dependencies
description: Combine all open PRs labeled "dependencies" into a single consolidated PR per ecosystem (ruby, javascript, etc.). Creates a branch, merges the PRs in, pushes, opens a draft PR linking the originals, runs `bin/ci` locally, then marks ready-for-review on green or posts a review comment and starts diagnosing on red. Use when the user wants to batch Dependabot/Renovate PRs, says "consolidate dependencies", "batch dep PRs", or "combine dependency updates".
---

# Consolidate dependencies

Batch open dependency PRs (Dependabot, Renovate, etc.) into one PR per ecosystem so CI runs once and review happens once.

## When to use

- Multiple open PRs labeled `dependencies` are queued.
- User wants to drain the dependency queue without reviewing each PR individually.
- Trigger phrases: "consolidate dependencies", "batch the dep PRs", "combine dependency updates", `/consolidate-dependencies`.

## Inputs

- Default scope: all open PRs labeled `dependencies` on the current repo.
- Grouping label: any additional label on those PRs (`ruby`, `javascript`, `python`, `docker`, …). PRs that share a non-`dependencies` label go into the same consolidated PR. PRs with no extra label go into a generic group (`dependencies-misc`).
- Base branch: repo default (usually `main`). Don't merge into `main` directly — always work on a fresh branch.

## Procedure

### 1. Verify prerequisites

```bash
gh auth status
git status --short          # working tree must be clean
git fetch origin
```

If `bin/ci` is missing, stop and ask the user what the local CI command is.

### 2. List and group the PRs

```bash
gh pr list --label dependencies --state open --json number,title,headRefName,labels,url --limit 100
```

Group by the first non-`dependencies` label. Show the user the proposed groups and PR counts before proceeding. If the user hasn't said "just do it" / "AFK mode", confirm.

### 3. For each group, build a consolidated branch

Use a deterministic branch name: `deps/<group>-<YYYYMMDD>` (e.g. `deps/ruby-20260519`).

```bash
git checkout -B deps/<group>-<date> origin/<default-branch>
```

For each PR in the group:

```bash
gh pr checkout <number>           # only to populate the local ref
git checkout deps/<group>-<date>
git merge --no-ff origin/<head-ref> -m "Merge #<number>: <title>"
```

**On merge conflict** — usually a lockfile (`Gemfile.lock`, `yarn.lock`, `package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`):

- Take both upstream changes for the manifest (`Gemfile`, `package.json`).
- Regenerate the lockfile (`bundle install`, `npm install`, `yarn install`, `pnpm install`, etc.).
- `git add` the regenerated lockfile and the manifest, then `git commit` to finish the merge.

For non-lockfile conflicts, stop and surface the conflict to the user — don't guess.

### 4. Push and open the consolidated PR

```bash
git push -u origin deps/<group>-<date>
```

Create as **draft** with `gh pr create --draft`. Title format: `Bump <group> dependencies (<N> PRs)`.

Description template:

```markdown
Consolidates the following dependency PRs into a single update for review and CI:

- #<n1> — <title>
- #<n2> — <title>
- …

Closes #<n1>
Closes #<n2>
…
```

The `Closes` lines auto-close the originals when this PR merges. Keep them — they're how the queue actually drains.

### 5. Run CI locally

```bash
bin/ci
```

Stream output. Do **not** mark the PR ready until `bin/ci` exits 0.

### 6a. On green — mark ready for review

```bash
gh pr ready <new-pr-number>
```

Then request reviewers from `git blame` of the changed manifests (skip if the repo uses CODEOWNERS — that handles it).

### 6b. On red — comment, then diagnose

Post a review comment on the new PR with the failing output (trimmed to the relevant section):

```bash
gh pr comment <new-pr-number> --body "$(cat <<'EOF'
`bin/ci` failed locally on the consolidated branch.

<failing test names / first error>

Investigating before requesting review.
EOF
)"
```

Then invoke the `diagnose` skill on the failure. The most common causes are:

- **Peer-dep mismatch** between two updated packages — pin one back or bump the other.
- **Stale lockfile** after the merge — regenerate fully (`rm -f <lock> && <pkg-manager> install`).
- **Single PR is the culprit** — bisect by reverting individual merge commits until CI passes. `git revert -m 1 <merge-sha>`. Drop the offender from this batch; open a follow-up issue or leave that PR for individual handling.
- **Repo-level flake** unrelated to deps — re-run `bin/ci` once; if still red, treat as a real failure.

After fixing, push, re-run `bin/ci`, then mark ready.

## Stop conditions

- Non-lockfile merge conflict → surface to user.
- `bin/ci` red after one bisect/fix attempt → stop and report; don't keep churning.
- Any PR in the group is already closed or has a failing required check the original author hasn't resolved → skip it and note in the consolidated PR description.

## Notes

- One consolidated PR per group, not per language. `ruby` and `javascript` are separate PRs because their CI risk surface is separate.
- Always draft first. Marking ready is the signal that local CI passed — don't invert that.
- Don't squash-merge the originals into the consolidated branch; use `merge --no-ff` so each upstream PR stays attributable in history.
