---
name: rails
description: Use when the user explicitly requests a comprehensive Rails review across every relevant layer (e.g. "/rails", "do a full Rails review", "check all Rails layers"). For GitHub PR reviews tied to a posted review, prefer `code-review-orchestration`.
---

# Rails Comprehensive Review

Comprehensive review through every relevant `rails-*` layer skill in `skills/rails/`. Each layer gets its own dedicated reviewer; this skill never restates the layer rules themselves.

## Role boundaries

- **Per-layer reviewers** — each loads exactly one `rails-*` skill and emits findings only for its layer.
- **Orchestrator** (this skill) — selects layers based on changed files, dispatches reviewers in parallel, aggregates findings.

## Reviewer dispatch

Map changed files to skills; dispatch one reviewer per matched skill in parallel. See `dispatching-parallel-agents` for the dispatch primitive.

| File pattern | Reviewer skill |
|---|---|
| `app/models/**` | `rails-models` |
| `app/controllers/**` | `rails-controllers` |
| `app/views/**` | `rails-views` |
| `app/helpers/**` | `rails-helpers` |
| `config/routes.rb` | `rails-routes` |
| `db/migrate/**` | `rails-migrations` |
| `app/jobs/**` | `rails-jobs` |
| `app/mailers/**` | `rails-mailers` |
| `app/mailboxes/**` | `rails-mailbox` |
| `app/channels/**` | `rails-action-cable` |
| `app/javascript/**`, Turbo/Stimulus in views, `tailwind.config.*` | `rails-hotwire-frontend` |
| `test/**` | `rails-testing` |
| auth / CSRF / headers / session config | `rails-security` |
| error handling, monitoring, logging | `rails-error-handling` |
| query / perf / cache changes | `rails-performance-and-caching` |
| Zeitwerk / `autoload_paths` | `rails-autoloading` |
| `config/deploy.yml`, `Dockerfile`, prod env | `rails-deployment` |
| I18n / locale changes | `rails-localization` |
| rich text content, `has_rich_text` | `rails-action-text` |
| file attachments, variants, direct uploads | `rails-active-storage` |
| composite primary keys | `rails-composite-keys` |

If no specific layer matches but the change is broadly Rails-flavored, fall back to `rails-the-rails-way` for general convention review.

## Subagent contract

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single `rails-*` skill to load

Each subagent returns either:
- **Findings**: `file:line` citations tied to specific rules from the loaded skill
- **No issues**: a single line so the orchestrator can drop it from the aggregate

## Aggregation protocol

Group findings by file, then by layer reviewer. Surface severity if the reviewer provides one; otherwise list as observations.

## Relationship to code-review-orchestration

`code-review-orchestration` performs the same per-layer dispatch but ties it to a GitHub PR (risk label, line comments, posting protocol). Use this skill when:
- The user asks for a Rails review that isn't tied to a PR (working tree, branch, single file)
- You want findings as conversation output rather than a posted GitHub review

Do not load both for the same task — pick one entry point.
