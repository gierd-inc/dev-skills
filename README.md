# Gierd Skills

[![skills.sh](https://skills.sh/b/gierd/dev-skills)](https://skills.sh/gierd/dev-skills)

Plugin name: `gierd`. Commands: `/gierd:build`, `/gierd:prd-to-spec`, `/gierd:status`, etc.

Agent skills for Gierd's Ruby on Rails engineering workflow — daily-driver process tools, the Agency PRD-to-shipped pipeline, and a complete set of Rails-domain skills.

> Forked from [mattpocock/skills](https://github.com/mattpocock/skills) and [ryenski/agency-plugin](https://github.com/ryenski/agency-plugin). Process skills (grill, triage, to-prd, to-issues, diagnose, tdd, improve-architecture) come from Matt Pocock's set; Rails skills and the Agency workflow come from the agency-plugin. Both are credited inline in their respective `SKILL.md` files where retained verbatim.

## What's in this repo

These skills are designed to be small, easy to adapt, and composable. They work with any model. Hack around with them. Make them your own.

The skills cover four broad areas:

1. **Process** — grill the agent into alignment, triage incoming bugs, break PRDs into issues, debug systematically.
2. **Rails domain knowledge** — one focused skill per Rails layer (models, controllers, views, jobs, mailers, migrations, security, performance, testing, Hotwire, etc.). Each is loaded on-demand based on what the agent is touching.
3. **The Agency workflow** — PRD → Spec → Issues → Code → draft PR, with file-based subagent contracts and resumable per-feature state under `.agency/`.
4. **Productivity** — `grill-me`, `caveman` mode, `write-a-skill`.

## Quickstart

1. Install the plugin:

   ```bash
   npx skills@latest add gierd/dev-skills
   ```

2. Run `/setup-gierd-skills` in your agent. It will:
   - Ask which issue tracker you use (Linear by default for Gierd repos, with GitHub / GitLab / local-markdown as alternatives)
   - Confirm the triage label vocabulary
   - Confirm whether the repo is single- or multi-context (multi-context is default for repos with `CONTEXT-MAP.md`)

## Why these skills exist

These skills exist to fix common failure modes with Claude Code, Codex, and other coding agents.

### #1 — Misalignment

The most common failure mode in software development is misalignment. The fix is a **grilling session** — getting the agent to ask you detailed questions about what you're building before it writes anything.

- [`/grill-me`](./skills/productivity/grill-me/SKILL.md) — non-code grilling
- [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) — same, but routes through `CONTEXT-MAP.md` and the per-context `CONTEXT.md` files, sharpens terminology, and updates ADRs inline

### #2 — Verbose agents drifting from the team's language

Agents are usually dropped into a project and asked to figure out the jargon as they go. The fix is a shared, written domain language — `CONTEXT.md` per bounded context, plus `docs/adr/` for decisions that span contexts. `/grill-with-docs` builds and maintains these.

### #3 — Code that doesn't work

Static feedback loops, TDD, and disciplined debugging:

- [`/tdd`](./skills/engineering/tdd/SKILL.md) — Minitest + fixtures, red-green-refactor
- [`/diagnose`](./skills/engineering/diagnose/SKILL.md) — reproduce → minimise → hypothesise → instrument → fix → regression-test

### #4 — Ball-of-mud architectures

Agents accelerate software entropy. Counter it:

- [`/to-prd`](./skills/engineering/to-prd/SKILL.md) and [`/to-issues`](./skills/engineering/to-issues/SKILL.md) keep changes scoped before code is written
- [`/zoom-out`](./skills/engineering/zoom-out/SKILL.md) forces big-picture context
- [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) hunts for deepening opportunities, informed by the bounded contexts in `CONTEXT-MAP.md` and the decisions in `docs/adr/`

## Reference

### Engineering

Skills used daily for code work.

- **[diagnose](./skills/engineering/diagnose/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions.
- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)** — Grilling session that updates `CONTEXT.md` (single- or multi-context) and ADRs inline.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)** — Find deepening opportunities, informed by `CONTEXT-MAP.md` and `docs/adr/`.
- **[setup-gierd-skills](./skills/engineering/setup-gierd-skills/SKILL.md)** — Scaffold per-repo config (issue tracker, triage labels, domain doc layout). Run once per repo.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with red-green-refactor. Minitest + Rails fixtures.
- **[to-issues](./skills/engineering/to-issues/SKILL.md)** — Break a plan, spec, or PRD into independently-grabbable issues using vertical slices.
- **[to-prd](./skills/engineering/to-prd/SKILL.md)** — Turn the current conversation into a PRD on the configured issue tracker.
- **[triage](./skills/engineering/triage/SKILL.md)** — Triage issues through a state machine of triage roles.
- **[zoom-out](./skills/engineering/zoom-out/SKILL.md)** — Higher-level context for an unfamiliar section of code.
- **[prototype](./skills/engineering/prototype/SKILL.md)** — Throwaway prototype to flush out a design.

### Rails

Domain skills loaded on-demand based on what the agent is touching. Each is a focused reference for one Rails layer or concern.

See [`skills/rails/README.md`](./skills/rails/README.md) for the full list with one-line descriptions.

### Agency workflow

PRD → Spec → Issues → Code → draft PR. Resumable per-feature state under `.agency/`.

See [`commands/`](./commands/) for the slash commands (`/gierd:prd-to-spec`, `/gierd:spec-to-issues`, `/gierd:build`, `/gierd:create-pr`, `/gierd:status`, `/gierd:resume`, etc.).

### Productivity

General workflow tools, not code-specific.

- **[caveman](./skills/productivity/caveman/SKILL.md)** — Ultra-compressed communication mode.
- **[grill-me](./skills/productivity/grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design.
- **[write-a-skill](./skills/productivity/write-a-skill/SKILL.md)** — Create new skills with proper structure and progressive disclosure.

### Misc

- **[git-guardrails-claude-code](./skills/misc/git-guardrails-claude-code/SKILL.md)** — Hooks to block dangerous git commands.

## License & attribution

This repo bundles work originally authored by Matt Pocock and Ryan Heneise. See individual `SKILL.md` files and commit history for attribution.
