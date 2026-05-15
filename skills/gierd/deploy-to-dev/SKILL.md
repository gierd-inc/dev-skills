---
name: deploy-to-dev
description: Use when deploying the current feature branch to the dev environment. Triggered by "deploy to dev", "push to dev", or "merge into dev".
---

# Deploy to Dev

## When to Use

- User asks to "deploy to dev", "push to dev", or "merge into dev"
- Work on the current branch is ready for integration testing on dev

## Prerequisites

- Must be on a feature branch (not `master`, `main`, or `dev`)
- Changes should be committed and pushed to origin

## Steps

### 1. Ensure a PR exists for the current branch

```bash
gh pr list --head "$(git branch --show-current)"
```

If no PR exists, create one before proceeding. Use the `create-pull-request` skill.

### 2. Pull the latest dev branch

```bash
git fetch origin dev
git checkout dev
git pull origin dev
```

### 3. Merge the feature branch into dev

```bash
git merge <feature-branch> --no-edit
```

If there are conflicts, resolve them, then `git merge --continue`.

### 4. Push dev to origin

```bash
git push origin dev
```

CI will automatically deploy after the push.

### 5. Switch back to feature branch

```bash
git checkout <feature-branch>
```

## Full Command Sequence

Replace `BRANCH` with the actual feature branch name:

```bash
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH"           # verify PR exists
git fetch origin dev
git checkout dev
git pull origin dev
git merge "$BRANCH" --no-edit
git push origin dev
git checkout "$BRANCH"
```

## Notes

- Always verify a PR exists before merging — dev is a shared environment and PRs keep work tracked
- If the merge results in unexpected conflicts with other in-progress work on dev, communicate with the team before resolving
- CI deploys automatically after `git push origin dev` — no manual deploy step needed
