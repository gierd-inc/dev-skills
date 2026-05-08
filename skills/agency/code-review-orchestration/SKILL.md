---
name: code-review-orchestration
description: Use when orchestrating a multi-agent code review of a Rails PR — dispatches per-layer reviewers (each loading one rails-* skill), assesses risk, applies a GitHub Risk label, and posts a single aggregated review with line comments. Use only at the orchestrator level; do not load in per-layer reviewers.
---

# Code Review Orchestration

Process and risk assessment for the review orchestrator. Layer-specific rules live in the matching `rails-*` skills — this skill does **not** restate them.

## Role boundaries

- **Per-layer reviewers** — each loads exactly one `rails-*` skill (e.g., `rails-models`, `rails-controllers`, `rails-hotwire-frontend`) and emits findings only for its layer. They do not assess overall risk and do not post the review.
- **Orchestrator** (this skill) — selects which reviewers to dispatch based on changed files, aggregates their findings, assesses risk, applies the label, and posts one review.

## Reviewer dispatch

Map changed files to skills; dispatch one reviewer per matched skill in parallel:

| File pattern | Reviewer skill |
|---|---|
| `app/models/**` | `rails-models` |
| `app/controllers/**` | `rails-controllers` |
| `app/views/**`, `app/helpers/components/**` | `rails-views` |
| `app/helpers/**` | `rails-helpers` |
| `config/routes.rb` | `rails-routes` |
| `db/migrate/**` | `rails-migrations` |
| `app/jobs/**` | `rails-jobs` |
| `app/mailers/**` | `rails-mailers` |
| `app/mailboxes/**` | `rails-mailbox` |
| `app/channels/**` | `rails-action-cable` |
| `app/javascript/**`, `app/views/**/*.html.erb` (Turbo/Stimulus), `tailwind.config.*` | `rails-hotwire-frontend` |
| `test/**` | `rails-testing` |
| auth/CSRF/headers/session config | `rails-security` |
| error handling, monitoring, logging | `rails-error-handling` |
| query/perf/cache changes | `rails-performance-and-caching` |
| Zeitwerk/autoload_paths | `rails-autoloading` |
| `config/deploy.yml`, `Dockerfile`, prod env | `rails-deployment` |

## Risk assessment

| Level | Criteria |
|---|---|
| Low | Small, isolated changes (bug fixes, copy, minor UI) |
| Medium | Refactors, new features, contained changes touching shared code |
| High | Breaking changes — schema migrations, API changes, auth/security, multi-system impact |

**Always flag explicitly as breaking:**
- DB schema changes (migrations, column rename/drop, index changes)
- Public API endpoint changes (renamed routes, changed params/response shapes)
- Background job interface changes (renamed classes, changed argument shapes)
- Auth/permission model changes
- Removed/renamed public methods used across the codebase
- Changes to shared concerns, base classes, or core abstractions

## Cross-repo impact (Gierd)

Escalate to **High** if changes affect schema, API endpoints, job interfaces, or event payloads consumed by:
- `gierd-inc/data-science` — data pipelines
- `gierd-inc/dbt_gierd` — dbt models
- `gierd-inc/kestra-ops` — orchestration infra
- `gierd-inc/kestra-gierd` — Kestra workflows

## GitHub label workflow

Always apply exactly one Risk label: `Risk: High`, `Risk: Medium`, or `Risk: Low`. Use the GitHub MCP tool (`update_pull_request`) or `gh pr edit --add-label`. Create the label if missing.

## Posting protocol

Post **one review** containing multiple **line comments** anchored to specific lines. Each line comment is brief, focused, no emojis, and cites the relevant `rails-*` skill or rule. The review summary must lead with `Risk: Low / Medium / High`; if High, list breaking changes before the issue count. If no issues found, post only a summary review with no line comments.

## Acceptance check

Before posting, verify the changes match the linked Linear issue's intent and acceptance criteria. Flag any divergence in the summary.
