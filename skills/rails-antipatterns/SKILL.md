---
name: rails-antipatterns
description: Use when the user explicitly requests a sweep against every named Rails antipattern (e.g. "/rails-antipatterns", "check all antipatterns", "review for Rails smells"). Do not auto-trigger on general code review — `code-review-orchestration` handles that.
---

# Rails Antipatterns

Comprehensive catalog of named Rails antipatterns sourced from *Rails Antipatterns* (Pytel & Saleh) and the 37signals/DHH idiom. Use these as diagnostic tools when reviewing code for structural smells — each antipattern has a name, detection heuristic, and idiomatic Rails fix.

These are not abstract principles. They are concrete, named problems with concrete, named solutions. Apply them by recognizing the shape of the code, not by keyword matching.

## Antipattern Reference

| Antipattern | Reference | Detect When |
|-------------|-----------|-------------|
| Fat Model / God Object | [references/fat-model-god-object.md](references/fat-model-god-object.md) | AR model >300 lines mixing responsibilities |
| Callback Hell | [references/callback-hell.md](references/callback-hell.md) | tangled before_*/after_* side-effect chains |
| Voyeuristic Model | [references/voyeuristic-model.md](references/voyeuristic-model.md) | Law of Demeter train wrecks |
| Anemic Domain Model | [references/anemic-domain-model.md](references/anemic-domain-model.md) | behavior in services, models as attribute bags |
| Spaghetti SQL | [references/spaghetti-sql.md](references/spaghetti-sql.md) | raw queries scattered outside scopes |
| Fat Controller | [references/fat-controller.md](references/fat-controller.md) | business logic in controllers |
| Non-RESTful Actions | [references/non-restful-actions.md](references/non-restful-actions.md) | custom actions instead of new resources |
| Homemade Keys & Routes | [references/homemade-keys-and-routes.md](references/homemade-keys-and-routes.md) | hand-built URL patterns bypassing resources |
| Bloated Session | [references/bloated-session.md](references/bloated-session.md) | AR objects or state stuffed in session |
| PHP-itis Views | [references/php-itis-views.md](references/php-itis-views.md) | conditionals/loops/queries in ERB |
| N+1 in Views | [references/n-plus-one-in-views.md](references/n-plus-one-in-views.md) | per-row queries during iteration |
| God Helper Module | [references/god-helper-module.md](references/god-helper-module.md) | ApplicationHelper as dumping ground |
| Service Object Soup | [references/service-object-soup.md](references/service-object-soup.md) | *Service class proliferation |
| Premature Abstraction & DI | [references/premature-abstraction-and-di.md](references/premature-abstraction-and-di.md) | DI/interfaces purely for testability |
| Mock-Heavy Tests | [references/mock-heavy-tests.md](references/mock-heavy-tests.md) | stubbing collaborators that could be fixtures |
| Migration Smells | [references/migration-smells.md](references/migration-smells.md) | irreversible migrations, mixed schema/data |

## Sweep Mode

When invoked as a sweep, scan the changed code for each antipattern in the table above. For each detected smell, dispatch one subagent per antipattern reference that matches. Each subagent loads this skill, reads the matched reference, and reviews the code against that antipattern. Aggregate findings.

Dispatch one parallel subagent per antipattern. No file gating — smells can hide anywhere. See `dispatching-parallel-agents` for the dispatch primitive.

Each subagent receives:
- The target (diff, file paths, or working-tree scope)
- The single antipattern reference to load

Each subagent returns either:
- **Findings**: `file:line` citations with a one-line note tying the code to the smell
- **No smell detected**: a single line so the orchestrator can drop it from the aggregate

Group surviving findings by antipattern, then by file. For each finding cite `file:line` and the relevant rule from the named reference. Skip antipatterns where no reviewer flagged anything — don't list "no findings" rows.

If invoked from `code-review-orchestration` as a sub-orchestrator, return the structured findings list rather than narrative prose; the parent will integrate with its own posting protocol.

## Constraints

- Apply fixes idiomatically. The goal is vanilla Rails — Concerns, AR verbs, scopes, helpers, jobs — not new abstraction layers.
- When a smell is found, recommend the *least invasive* fix that resolves it. Don't gold-plate.
- Cite the specific antipattern name and reference file for every finding so the reader can learn the pattern.
- Do not invent new antipatterns. Only flag smells that match one of the 16 named patterns above.
- A long file or complex class is not automatically a smell — look for the named shape: mixed responsibilities, leaking queries, violating conventions, etc.
