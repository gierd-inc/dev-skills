---
name: rails-expert
description: Use when the user explicitly requests a comprehensive Rails review across every relevant layer (e.g. "/rails", "do a full Rails review", "check all Rails layers"). For GitHub PR reviews tied to a posted review, prefer `code-review-orchestration`.
---

# Rails Expert

Comprehensive review through every relevant Rails layer. Each layer gets its own dedicated reviewer; this skill never restates the layer rules themselves.

## Role Boundaries

- **Per-layer reviewers** — each loads exactly one reference file and emits findings only for its layer.
- **Orchestrator** (this skill) — selects layers based on changed files, dispatches reviewers in parallel, aggregates findings.

## Reviewer Dispatch

Map changed files to references; dispatch one reviewer per matched reference in parallel. See `dispatching-parallel-agents` for the dispatch primitive.

| File pattern | Reference |
|---|---|
| `app/models/**` | `references/models.md` |
| `app/controllers/**` | `references/controllers.md` |
| `app/views/**` | `references/views.md` |
| `app/helpers/**` | `references/helpers.md` |
| `config/routes.rb` | `references/routes.md` |
| `db/migrate/**` | `references/migrations.md` |
| `app/jobs/**` | `references/jobs.md` |
| `app/mailers/**` | `references/mailers.md` |
| `app/mailboxes/**` | `references/mailbox.md` |
| `app/channels/**` | `references/action-cable.md` |
| `app/javascript/**`, Turbo/Stimulus in views, `tailwind.config.*` | `references/hotwire-frontend.md` |
| `test/**` | `references/testing.md` |
| auth / CSRF / headers / session config | `references/security.md` |
| error handling, monitoring, logging | `references/error-handling.md` |
| query / perf / cache changes | `references/performance-and-caching.md` |
| Zeitwerk / `autoload_paths` | `references/autoloading.md` |
| `config/deploy.yml`, `Dockerfile`, prod env | `references/deployment.md` |
| I18n / locale changes | `references/localization.md` |
| rich text content, `has_rich_text` | `references/action-text.md` |
| file attachments, variants, direct uploads | `references/active-storage.md` |
| composite primary keys | `references/composite-keys.md` |

If no specific layer matches but the change is broadly Rails-flavored, fall back to `references/the-rails-way.md` for general convention review.

## Subagent Contract

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single reference file to load

Each subagent returns either:
- **Findings**: `file:line` citations tied to specific rules from the loaded reference
- **No issues**: a single line so the orchestrator can drop it from the aggregate

## Aggregation Protocol

Group findings by file, then by layer reviewer. Surface severity if the reviewer provides one; otherwise list as observations.

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| The Rails Way | references/the-rails-way.md | conventions, code organization, philosophy |
| Models | references/models.md | Active Record models, associations, validations, scopes, callbacks |
| Controllers | references/controllers.md | RESTful actions, strong params, before_actions, respond_to |
| Routes | references/routes.md | resourceful routes, constraints, namespacing |
| Views | references/views.md | ERB templates, forms, layout, g_* helpers |
| Helpers | references/helpers.md | view helpers, app/helpers/ |
| Hotwire Frontend | references/hotwire-frontend.md | Turbo Frames/Streams/Morph, Stimulus, Tailwind |
| Jobs | references/jobs.md | Active Job, Solid Queue, retry/discard |
| Mailers | references/mailers.md | Action Mailer, mail views, deliveries |
| Mailbox | references/mailbox.md | Action Mailbox, inbound email routing |
| Action Cable | references/action-cable.md | WebSocket channels, subscriptions, broadcasts |
| Action Text | references/action-text.md | rich content, trix editor, has_rich_text |
| Active Storage | references/active-storage.md | file attachments, variants, direct uploads |
| Active Support | references/active-support.md | helpers, concerns, time zones, core extensions |
| Migrations | references/migrations.md | schema changes, indexes, reversibility |
| Composite Keys | references/composite-keys.md | composite primary keys |
| Autoloading | references/autoloading.md | Zeitwerk, constant resolution, file naming |
| Error Handling | references/error-handling.md | validation errors, exceptions, error pages, Honeybadger |
| Security | references/security.md | has_secure_password, authorization, CSRF, headers |
| Localization | references/localization.md | I18n, locale files, pluralization |
| Performance & Caching | references/performance-and-caching.md | N+1, query optimization, fragment cache, Solid Cache |
| Testing | references/testing.md | Minitest with fixtures, model/controller/system/integration tests |
| Deployment | references/deployment.md | Kamal, Dockerfile, production env, deploy.yml |

## Sweep Mode

When invoked as a sweep across changed files, map each changed file to the relevant reference(s) above and dispatch one subagent per matched reference. Each subagent should: load this skill, read the matched reference file, and review the changed code in that file against the reference. Aggregate findings by layer.

## Relationship to code-review-orchestration

`code-review-orchestration` performs the same per-layer dispatch but ties it to a GitHub PR (risk label, line comments, posting protocol). Use this skill when:
- The user asks for a Rails review that isn't tied to a PR (working tree, branch, single file)
- You want findings as conversation output rather than a posted GitHub review

Do not load both for the same task — pick one entry point.

## Constraints

- Rails 8.1+ (Rails Edge)
- Ruby 3.4+
- Hotwire: Turbo + Stimulus (latest); prefer Turbo Morph over frame replacements
- TailwindCSS via RubyGem (v4), DaisyUI for semantic CSS classes
- Minitest with fixtures exclusively — no RSpec, no FactoryBot
- Solid Queue / Solid Cache / Solid Cable (DB-backed, no Redis required)
- Kamal 2 + Kamal Proxy + Thruster for Docker-based deploys
- Propshaft (asset pipeline)
- PostgreSQL or SQLite (project-dependent)
