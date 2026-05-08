# Agency Skills

The Agency PRD-to-shipped workflow: PRD → Spec → Issues → Code → review → draft PR. File-based subagent contracts with resumable per-feature state under `.dev-skills/`.

These come from [agency-plugin](https://github.com/ryenski/agency-plugin) and are loaded by the orchestration commands under `commands/`.

- **[architect](./architect/SKILL.md)** — PRD-to-Spec interrogator: reads the raw PRD, grills the user, writes a heavy `spec.md`.
- **[code-review-orchestration](./code-review-orchestration/SKILL.md)** — Multi-agent code review of a Rails PR. Dispatches per-layer reviewers (each loading one `rails-*` skill), aggregates findings, applies a GitHub Risk label, posts a single review with line comments.
- **[deploy-to-dev](./deploy-to-dev/SKILL.md)** — Deploy the current feature branch to the dev environment.

## Workflow

The Agency commands (`/gierd:prd-to-spec`, `/gierd:spec-to-issues`, `/gierd:build`, `/gierd:create-pr`, `/gierd:status`, `/gierd:resume`, `/gierd:setup`, etc.) live under [`commands/`](../../commands/) at the repo root.

State lives under `.dev-skills/<feature-slug>/`. Add `.dev-skills/` to `.gitignore` for any project that uses these commands — `/gierd:setup` will offer to do that for you.
