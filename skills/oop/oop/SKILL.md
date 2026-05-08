---
name: oop
description: Use when the user explicitly requests extraction opportunities across every OOP pattern lens (e.g. "/oop", "find OOP refactoring opportunities", "check all extraction patterns"). The Rails Way is still the default — this skill finds where it stops being enough.
---

# OOP Extraction Sweep

Comprehensive sweep through every OOP extraction pattern in `skills/oop/`. Each pattern gets its own dedicated reviewer; this skill never restates the patterns themselves.

## Role boundaries

- **Per-pattern reviewers** — each loads exactly one `oop-*` skill and looks for code that *should* extract into that pattern. They report opportunities, not violations.
- **Orchestrator** (this skill) — dispatches all 9 reviewers in parallel against the target, aggregates suggestions.

## Reviewer dispatch

Dispatch one parallel subagent per pattern. Each subagent answers: "Is there code here that would benefit from extracting into this pattern?" See `dispatching-parallel-agents` for the dispatch primitive.

| Skill | Looks for |
|---|---|
| `oop-value-objects` | Repeated formatting/validation of domain values; `Money`, `EmailAddress`-shaped concepts inline |
| `oop-null-objects` | Defensive `&.` and `if x.present?` chains around nilable collaborators |
| `oop-concerns-and-mixins` | Behavior duplicated across 2+ models or controllers |
| `oop-presenters` | Display logic crammed into helpers or views |
| `oop-query-objects` | Complex AR queries that have outgrown scopes |
| `oop-form-objects` | Multi-model forms, virtual attributes, wizard steps |
| `oop-service-objects` | Genuinely cross-aggregate operations buried in models or controllers |
| `oop-policy-objects` | Authorization checks scattered across controllers and models |
| `oop-repository-pattern` | (Rare) Domain code coupled to a specific data source that needs swapping |

The Rails Way is still the default. Reviewers must justify *why* the pattern earns the extra layer; if a model method, scope, or concern works fine, no opportunity should be reported.

## Subagent contract

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single `oop-*` skill to load

Each subagent returns either:
- **Opportunities**: `file:line` citation, current shape, proposed pattern, one-line trade-off
- **None found**: a single line so the orchestrator can drop it from the aggregate

## Aggregation protocol

Group opportunities by file, then by pattern. For each include:
- Current code shape (one-line summary)
- Proposed pattern
- One-line trade-off (what you gain, what you lose)

Skip patterns with no opportunities — don't list "no findings" rows.

## Relationship to rails-antipatterns

`rails-antipatterns` finds smells; `oop` finds extraction opportunities. They overlap on smells like `service-object-soup` (extraction *into* this pattern is sometimes the wrong move) and `anemic-domain-model` (extraction *out of* services into models). When invoked together, run them in parallel and merge findings, deduplicating where the same code is flagged from both lenses.
