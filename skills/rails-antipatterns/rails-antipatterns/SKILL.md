---
name: rails-antipatterns
description: Use when the user explicitly requests a sweep against every named Rails antipattern (e.g. "/rails-antipatterns", "check all antipatterns", "review for Rails smells"). Do not auto-trigger on general code review — `code-review-orchestration` handles that.
---

# Rails Antipatterns Sweep

Comprehensive sweep against every named Rails antipattern in `skills/rails-antipatterns/`. Each smell gets its own dedicated reviewer; this skill never restates the smells themselves.

## Role boundaries

- **Per-antipattern reviewers** — each loads exactly one `rails-antipattern-*` skill and emits findings through that lens only. They do not cross-check other antipatterns.
- **Orchestrator** (this skill) — dispatches all 16 reviewers in parallel against the same target (a diff, a file, or the working tree), then aggregates results.

## Reviewer dispatch

Dispatch one parallel subagent per antipattern. No file gating — smells can hide anywhere. See `dispatching-parallel-agents` for the dispatch primitive.

| Skill | Smell |
|---|---|
| `rails-antipattern-fat-model-god-object` | Models past 300 lines, multiple responsibilities |
| `rails-antipattern-callback-hell` | Side-effecting callbacks chained across save lifecycle |
| `rails-antipattern-voyeuristic-model` | Law of Demeter violations, train wrecks |
| `rails-antipattern-anemic-domain-model` | Behavior in services, models reduced to attributes |
| `rails-antipattern-spaghetti-sql` | Raw SQL or `where(...)` scattered across layers |
| `rails-antipattern-fat-controller` | Business logic in controller actions |
| `rails-antipattern-non-restful-actions` | Custom controller actions instead of new resources |
| `rails-antipattern-homemade-keys-and-routes` | Hand-rolled URL schemes bypassing `resources` |
| `rails-antipattern-bloated-session` | AR objects or workflow state in `session` |
| `rails-antipattern-php-itis-views` | Logic and queries in ERB |
| `rails-antipattern-n-plus-one-in-views` | Per-row queries in collection iteration |
| `rails-antipattern-god-helper-module` | `ApplicationHelper` as dumping ground |
| `rails-antipattern-service-object-soup` | `app/services/*Service` proliferation |
| `rails-antipattern-premature-abstraction-and-di` | DI/interfaces solely for testability |
| `rails-antipattern-mock-heavy-tests` | Stubbing collaborators instead of fixtures |
| `rails-antipattern-migration-smells` | Irreversible migrations, mixed schema/data, missing FK indexes |

## Subagent contract

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single antipattern skill to load

Each subagent returns either:
- **Findings**: `file:line` citations with a one-line note tying the code to the smell
- **No smell detected**: a single line so the orchestrator can drop it from the aggregate

## Aggregation protocol

Group surviving findings by antipattern, then by file. For each finding cite `file:line` and the relevant rule from the named skill. Skip antipatterns where no reviewer flagged anything — don't list "no findings" rows.

If invoked from `code-review-orchestration` as a sub-orchestrator, return the structured findings list rather than narrative prose; the parent will integrate with its own posting protocol.
