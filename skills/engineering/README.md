# Engineering

Skills used daily for code work.

- **[diagnose](./diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[grill-with-docs](./grill-with-docs/SKILL.md)** — Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates `CONTEXT.md` (single- or multi-context) and ADRs inline.
- **[triage](./triage/SKILL.md)** — Triage issues through a state machine of triage roles.
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)** — Find deepening opportunities in a codebase, informed by `CONTEXT-MAP.md` / `CONTEXT.md` and the decisions in `docs/adr/`.
- **[setup-gierd-skills](./setup-gierd-skills/SKILL.md)** — Scaffold per-repo config (issue tracker, triage label vocabulary, domain doc layout). Defaults to Linear + multi-context for Gierd repos.
- **[tdd](./tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Tuned for Minitest + Rails fixtures.
- **[to-issues](./to-issues/SKILL.md)** — Break any plan, spec, or PRD into independently-grabbable issues using vertical slices.
- **[to-prd](./to-prd/SKILL.md)** — Turn the current conversation context into a PRD on the configured issue tracker.
- **[zoom-out](./zoom-out/SKILL.md)** — Tell the agent to zoom out and give broader context or a higher-level perspective on an unfamiliar section of code.
- **[prototype](./prototype/SKILL.md)** — Build a throwaway prototype to flush out a design — either a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route.
- **[consolidate-dependencies](./consolidate-dependencies/SKILL.md)** — Combine open PRs labeled `dependencies` into one consolidated PR per ecosystem; create branch, merge originals, push, open draft PR linking them, run `bin/ci`, mark ready on green or diagnose on red.
