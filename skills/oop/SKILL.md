---
name: oop
description: Use when the user explicitly requests extraction opportunities across every OOP pattern lens (e.g. "/oop", "find OOP refactoring opportunities", "check all extraction patterns"). The Rails Way is still the default — this skill finds where it stops being enough.
---

# OOP Patterns for Rails

The Rails Way is still the default. Models, scopes, concerns, and helpers handle the vast majority of Rails code. These patterns are tools, not architecture — each one earns its place only when the simpler Rails idiom stops being enough. An app full of service objects, form objects, and repositories is an anemic domain model. Start with fat models, thin controllers; extract only when the pressure is clear.

## Reference Guide

| Pattern | Reference | Load When |
|---------|-----------|-----------|
| Value Objects | references/value-objects.md | `composed_of`, custom attribute types, value-with-behavior |
| Null Objects | references/null-objects.md | replacing nil checks with full-interface stand-ins |
| Concerns & Mixins | references/concerns-and-mixins.md | shared behavior across 2+ models |
| Presenters | references/presenters.md | SimpleDelegator/decorator wrappers for display logic |
| Query Objects | references/query-objects.md | complex AR queries beyond scopes |
| Form Objects | references/form-objects.md | ActiveModel::Model for multi-model/wizard forms |
| Service Objects | references/service-objects.md | last-resort POROs for cross-aggregate operations |
| Policy Objects | references/policy-objects.md | per-resource per-action authorization (Pundit-compatible) |
| Repository Pattern | references/repository-pattern.md | when swapping data sources behind models |

## Sweep Mode

When invoked as a sweep, identify which patterns are present or problematic in the code, map to the relevant reference(s) above, and dispatch one subagent per matched pattern. Each subagent loads this skill, reads the matched reference, and reviews the code against the pattern. Aggregate findings.

### Reviewer dispatch table

Dispatch one parallel subagent per pattern. Each subagent answers: "Is there code here that would benefit from extracting into this pattern?" See `dispatching-parallel-agents` for the dispatch primitive.

| Reference | Looks for |
|---|---|
| references/value-objects.md | Repeated formatting/validation of domain values; `Money`, `EmailAddress`-shaped concepts inline |
| references/null-objects.md | Defensive `&.` and `if x.present?` chains around nilable collaborators |
| references/concerns-and-mixins.md | Behavior duplicated across 2+ models or controllers |
| references/presenters.md | Display logic crammed into helpers or views |
| references/query-objects.md | Complex AR queries that have outgrown scopes |
| references/form-objects.md | Multi-model forms, virtual attributes, wizard steps |
| references/service-objects.md | Genuinely cross-aggregate operations buried in models or controllers |
| references/policy-objects.md | Authorization checks scattered across controllers and models |
| references/repository-pattern.md | (Rare) Domain code coupled to a specific data source that needs swapping |

## Subagent contract

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single reference file to load

Each subagent returns either:
- **Opportunities**: `file:line` citation, current shape, proposed pattern, one-line trade-off
- **None found**: a single line so the orchestrator can drop it from the aggregate

## Aggregation protocol

Group opportunities by file, then by pattern. For each include:
- Current code shape (one-line summary)
- Proposed pattern
- One-line trade-off (what you gain, what you lose)

Skip patterns with no opportunities — don't list "no findings" rows.

## Constraints

- **The default is still the Rails Way.** Reviewers must justify *why* the pattern earns the extra layer; if a model method, scope, or concern works fine, no opportunity should be reported.
- **Each pattern has a "Would a fat model do?" section** in its reference. Apply that test before flagging an extraction opportunity.
- **An app full of `*Service` classes** is the anemic domain model antipattern. Service objects are last resort, not default architecture.
- **Repository pattern is almost never needed.** ActiveRecord is the repository. Add a layer only when you need to swap the data source.

## Relationship to rails-antipatterns

`rails-antipatterns` finds smells; `oop` finds extraction opportunities. They overlap on smells like `service-object-soup` (extraction *into* this pattern is sometimes the wrong move) and `anemic-domain-model` (extraction *out of* services into models). When invoked together, run them in parallel and merge findings, deduplicating where the same code is flagged from both lenses.
